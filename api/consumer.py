"""Kafka consumer: reads purchases from Kafka and stores them in MongoDB.

Delivery is at-least-once: the offset is committed only after the message has
been handled. Handling a message means one of:

* the purchase was saved as "completed", or as "failed" with a
  failure_reason when it breaks a business rule (or it already existed: the
  unique index on purchase_id turns a redelivery into DuplicateKeyError);
* the message can never be stored (invalid JSON, no purchase_id, or a
  document MongoDB rejects), so it was copied to the dead-letter topic
  (a "poison" message must not block its partition forever).

Transient failures (MongoDB or Kafka unavailable) are retried with
exponential backoff. The consumer seeks back to the failed message instead of
committing it, and keeps polling, so it stays in the consumer group.
"""
import json
import logging
import os
import signal
import time
from datetime import datetime, timezone

from bson.errors import InvalidDocument
from confluent_kafka import Consumer, KafkaException, Producer, TopicPartition
from pymongo.errors import ConnectionFailure, DuplicateKeyError, PyMongoError, WriteError

from database import ensure_indexes, save_purchase

KAFKA_SERVER = os.getenv("KAFKA_SERVER", "kafka:9092")
TOPIC = os.getenv("KAFKA_TOPIC", "purchases")
DLQ_TOPIC = os.getenv("KAFKA_DLQ_TOPIC", "purchases.dlq")
GROUP_ID = os.getenv("KAFKA_GROUP_ID", "purchase-consumers")

# Liveness signal: touched while the main loop runs. The container probe
# fails when the file is older than a minute (the loop is stuck).
HEARTBEAT_FILE = os.getenv("HEARTBEAT_FILE", "/tmp/consumer-heartbeat")
HEARTBEAT_EVERY_SECONDS = 5

MAX_QUANTITY = 10

# Keep the longest wait well below max.poll.interval.ms (300 s by default).
MAX_BACKOFF_SECONDS = 30

# Errors after which the same message is retried later.
TRANSIENT_ERRORS = (PyMongoError, KafkaException, BufferError, RuntimeError, TimeoutError)

log = logging.getLogger("consumer")


class InvalidMessage(ValueError):
    """The message can never be processed, however often it is retried."""


def parse_purchase(raw):
    if raw is None:
        raise InvalidMessage("empty message value")
    try:
        purchase = json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise InvalidMessage(f"value is not valid UTF-8 JSON: {exc}") from exc
    if not isinstance(purchase, dict):
        raise InvalidMessage("value is not a JSON object")
    purchase_id = purchase.get("purchase_id")
    if not isinstance(purchase_id, str) or not purchase_id:
        raise InvalidMessage("purchase_id is missing or not a string")
    return purchase


def validation_error(purchase):
    """Return why the purchase must be rejected, or None if it is valid.

    These are business rules, not parsing errors: the order is stored with
    status "failed" so the customer sees the reason in the Ledger.
    """
    slug = purchase.get("product_slug")
    quantity = purchase.get("quantity")
    unit_price = purchase.get("unit_price")
    total_price = purchase.get("total_price")
    if not isinstance(slug, str) or not slug:
        return "Unknown product"
    if type(quantity) is not int or not 1 <= quantity <= MAX_QUANTITY:
        return f"Quantity must be between 1 and {MAX_QUANTITY}"
    if type(unit_price) is not int or unit_price < 0:
        return "Invalid price"
    if total_price != unit_price * quantity:
        return "Total price does not match quantity and unit price"
    return None


def send_to_dlq(producer, message, reason):
    """Copy the original message to the dead-letter topic. Raises on failure."""
    delivery = []
    producer.produce(
        topic=DLQ_TOPIC,
        key=message.key(),
        value=message.value(),
        headers={
            "dlq.reason": reason,
            "dlq.source.topic": message.topic(),
            "dlq.source.partition": str(message.partition()),
            "dlq.source.offset": str(message.offset()),
        },
        callback=lambda err, _msg: delivery.append(err),
    )
    producer.flush(10)
    if not delivery:
        raise TimeoutError("DLQ delivery timeout")
    if delivery[0] is not None:
        raise RuntimeError(f"DLQ delivery failed: {delivery[0]}")


def process(message, dlq_producer, save=save_purchase):
    """Handle one message. Raises one of TRANSIENT_ERRORS if it must be retried."""
    try:
        purchase = parse_purchase(message.value())
    except InvalidMessage as exc:
        send_to_dlq(dlq_producer, message, str(exc))
        log.warning(
            "Sent to %s: %s (partition %s, offset %s)",
            DLQ_TOPIC, exc, message.partition(), message.offset(),
        )
        return

    reason = validation_error(purchase)
    purchase["status"] = "failed" if reason else "completed"
    purchase["failure_reason"] = reason
    purchase["updated_at"] = datetime.now(timezone.utc).isoformat()

    try:
        save(purchase)
        log.info("Purchase %s: %s%s", purchase["status"], purchase["purchase_id"],
                 f" ({reason})" if reason else "")
    except DuplicateKeyError:
        log.info("Purchase already exists: %s", purchase["purchase_id"])
    except (WriteError, InvalidDocument, OverflowError) as exc:
        # MongoDB rejects this document permanently (e.g. a "$" field name or
        # an integer that does not fit BSON): retrying would loop forever.
        send_to_dlq(dlq_producer, message, f"rejected by MongoDB: {exc}")
        log.warning("Sent to %s: rejected by MongoDB: %s", DLQ_TOPIC, exc)


def backoff_seconds(attempt):
    return min(MAX_BACKOFF_SECONDS, 2 ** (attempt - 1))


_last_heartbeat = 0.0


def heartbeat():
    global _last_heartbeat
    now = time.monotonic()
    if now - _last_heartbeat < HEARTBEAT_EVERY_SECONDS:
        return
    try:
        with open(HEARTBEAT_FILE, "w") as fh:
            fh.write(str(int(time.time())))
        _last_heartbeat = now
    except OSError as exc:
        log.warning("Cannot write heartbeat file %s: %s", HEARTBEAT_FILE, exc)


def run():
    running = True

    def stop(signum, _frame):
        nonlocal running
        log.info("Received %s, finishing the current message and stopping", signal.Signals(signum).name)
        running = False

    # Kubernetes and Docker stop containers with SIGTERM, not SIGINT.
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)

    def sleep(seconds):
        deadline = time.monotonic() + seconds
        while running and time.monotonic() < deadline:
            heartbeat()
            time.sleep(0.2)

    attempt = 0
    while running:
        try:
            ensure_indexes()
            break
        except ConnectionFailure as exc:
            attempt += 1
            log.warning("MongoDB not reachable (%s), retrying in %ss", exc, backoff_seconds(attempt))
            sleep(backoff_seconds(attempt))
    if not running:
        return

    consumer = Consumer({
        "bootstrap.servers": KAFKA_SERVER,
        "group.id": GROUP_ID,
        "auto.offset.reset": "earliest",
        "enable.auto.commit": False,
    })
    dlq_producer = Producer({
        "bootstrap.servers": KAFKA_SERVER,
        "acks": "all",
        "enable.idempotence": True,
    })
    consumer.subscribe([TOPIC])
    log.info("Consuming %s as group %s", TOPIC, GROUP_ID)

    failures = 0
    try:
        while running:
            heartbeat()
            message = consumer.poll(1.0)
            if message is None:
                continue
            if message.error():
                if message.error().fatal():
                    raise KafkaException(message.error())
                log.warning("Kafka error: %s", message.error())
                continue

            try:
                process(message, dlq_producer)
            except TRANSIENT_ERRORS as exc:
                failures += 1
                delay = backoff_seconds(failures)
                log.warning(
                    "Transient error on partition %s offset %s (attempt %s): %s; retrying in %ss",
                    message.partition(), message.offset(), failures, exc, delay,
                )
                # Rewind this partition so the same message is delivered again.
                consumer.seek(TopicPartition(message.topic(), message.partition(), message.offset()))
                sleep(delay)
                continue

            failures = 0
            try:
                consumer.commit(message=message, asynchronous=False)
            except KafkaException as exc:
                # E.g. a rebalance: the message is redelivered and the
                # unique index makes the second write a no-op.
                log.warning("Commit failed, message may be redelivered: %s", exc)
    finally:
        log.info("Closing consumer")
        consumer.close()
        dlq_producer.flush(10)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")
    run()
