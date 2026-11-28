"""Kafka producer used by POST /api/buy.

One Producer per process (Gunicorn worker), shared by its threads. Each
request waits only for the delivery report of its own message: the old
producer.flush() waited for every in-flight message of every thread, so one
slow message delayed all concurrent requests.
"""
import json
import os
import threading
import time

from confluent_kafka import Producer
from kafka_config import kafka_config

KAFKA_SERVER = os.getenv("KAFKA_SERVER", "kafka:9092")
TOPIC = os.getenv("KAFKA_TOPIC", "purchases")

# The request gives up after this long and answers 503.
DELIVERY_TIMEOUT_SECONDS = float(os.getenv("KAFKA_DELIVERY_TIMEOUT_SECONDS", "5"))

producer = Producer({
    # Security settings (SASL/SCRAM + TLS on AKS) come from the environment.
    **kafka_config(KAFKA_SERVER),
    "acks": "all",
    # Broker de-duplicates producer retries, so a network glitch does not
    # write the same purchase twice.
    "enable.idempotence": True,
    # librdkafka stops retrying after this and reports a delivery error.
    "message.timeout.ms": int(DELIVERY_TIMEOUT_SECONDS * 1000),
    "linger.ms": 5,
})


def send_purchase(purchase, kafka_producer=None, timeout=DELIVERY_TIMEOUT_SECONDS):
    """Publish one purchase and wait for the broker to acknowledge it.

    Raises TimeoutError, RuntimeError (delivery failed) or BufferError (local
    queue full); the route turns them into 503.
    """
    kafka_producer = kafka_producer or producer
    delivered = threading.Event()
    result = {}

    def delivery_report(err, _msg):
        result["error"] = err
        delivered.set()

    kafka_producer.produce(
        topic=TOPIC,
        key=purchase["purchase_id"],
        value=json.dumps(purchase).encode("utf-8"),
        on_delivery=delivery_report,
    )

    # poll() serves delivery callbacks; any thread may run ours, so wait on
    # the event rather than on the poll that happens to fire it.
    deadline = time.monotonic() + timeout
    while not delivered.is_set():
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise TimeoutError("Kafka delivery timeout")
        kafka_producer.poll(min(0.1, remaining))

    if result["error"] is not None:
        raise RuntimeError(str(result["error"]))
    return True
