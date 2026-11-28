"""Unit tests for the consumer's message handling (no Kafka or MongoDB needed)."""
import json

import consumer
import pytest
from pymongo.errors import DuplicateKeyError, ServerSelectionTimeoutError, WriteError


class FakeMessage:
    def __init__(self, value, key=b"k", topic="purchases", partition=1, offset=42):
        self._value, self._key = value, key
        self._topic, self._partition, self._offset = topic, partition, offset

    def value(self):
        return self._value

    def key(self):
        return self._key

    def topic(self):
        return self._topic

    def partition(self):
        return self._partition

    def offset(self):
        return self._offset


class FakeProducer:
    def __init__(self, error=None, deliver=True):
        self.sent, self._pending = [], []
        self._error, self._deliver = error, deliver

    def produce(self, topic, key, value, headers, callback):
        self.sent.append({"topic": topic, "key": key, "value": value, "headers": headers})
        self._pending.append(callback)

    def flush(self, _timeout):
        if self._deliver:
            for callback in self._pending:
                callback(self._error, None)
        self._pending.clear()


def purchase_bytes(**overrides):
    purchase = {"purchase_id": "p-1", "product_slug": "pocket-fluffs", "quantity": 2,
                "unit_price": 300, "total_price": 600, "status": "pending", "failure_reason": None}
    purchase.update(overrides)
    return json.dumps(purchase).encode()


class Recorder:
    def __init__(self, error=None):
        self.saved, self._error = [], error

    def __call__(self, purchase):
        if self._error:
            raise self._error
        self.saved.append(purchase)


# parse_purchase

def test_parse_valid():
    assert consumer.parse_purchase(purchase_bytes())["purchase_id"] == "p-1"


@pytest.mark.parametrize("raw", [
    None,
    b"not json",
    b"\xff\xfe",
    b"[1, 2]",
    b'{"product_slug": "x"}',
    b'{"purchase_id": 123}',
    b'{"purchase_id": ""}',
])
def test_parse_rejects_poison(raw):
    with pytest.raises(consumer.InvalidMessage):
        consumer.parse_purchase(raw)


# process

def test_valid_message_is_saved_as_completed():
    save, dlq = Recorder(), FakeProducer()
    consumer.process(FakeMessage(purchase_bytes()), dlq, save=save)
    assert len(save.saved) == 1
    assert save.saved[0]["status"] == "completed"
    assert save.saved[0]["failure_reason"] is None
    assert save.saved[0]["updated_at"]
    assert dlq.sent == []


@pytest.mark.parametrize("overrides, reason", [
    ({"quantity": 0}, "Quantity"),
    ({"quantity": 11, "total_price": 3300}, "Quantity"),
    ({"quantity": True}, "Quantity"),
    ({"product_slug": ""}, "Unknown product"),
    ({"unit_price": -1, "total_price": -2}, "Invalid price"),
    ({"total_price": 1}, "Total price"),
])
def test_business_rule_violation_is_saved_as_failed(overrides, reason):
    save, dlq = Recorder(), FakeProducer()
    consumer.process(FakeMessage(purchase_bytes(**overrides)), dlq, save=save)
    assert save.saved[0]["status"] == "failed"
    assert reason in save.saved[0]["failure_reason"]
    assert dlq.sent == []


def test_duplicate_is_treated_as_done():
    save, dlq = Recorder(DuplicateKeyError("dup")), FakeProducer()
    consumer.process(FakeMessage(purchase_bytes()), dlq, save=save)  # no exception
    assert dlq.sent == []


def test_poison_message_goes_to_dlq_and_is_not_saved():
    save, dlq = Recorder(), FakeProducer()
    message = FakeMessage(b"{broken", partition=2, offset=7)
    consumer.process(message, dlq, save=save)
    assert save.saved == []
    assert len(dlq.sent) == 1
    sent = dlq.sent[0]
    assert sent["topic"] == consumer.DLQ_TOPIC
    assert sent["value"] == b"{broken"
    assert sent["headers"]["dlq.source.partition"] == "2"
    assert sent["headers"]["dlq.source.offset"] == "7"
    assert "JSON" in sent["headers"]["dlq.reason"]


def test_document_rejected_by_mongodb_goes_to_dlq():
    save, dlq = Recorder(WriteError("bad field name", code=52)), FakeProducer()
    consumer.process(FakeMessage(purchase_bytes()), dlq, save=save)
    assert len(dlq.sent) == 1
    assert "rejected by MongoDB" in dlq.sent[0]["headers"]["dlq.reason"]


def test_mongodb_down_is_transient():
    save, dlq = Recorder(ServerSelectionTimeoutError("down")), FakeProducer()
    with pytest.raises(consumer.TRANSIENT_ERRORS):
        consumer.process(FakeMessage(purchase_bytes()), dlq, save=save)
    assert dlq.sent == []


def test_dlq_delivery_error_is_transient():
    dlq = FakeProducer(error="broker down")
    with pytest.raises(consumer.TRANSIENT_ERRORS):
        consumer.process(FakeMessage(b"{broken"), dlq, save=Recorder())


def test_dlq_delivery_timeout_is_transient():
    dlq = FakeProducer(deliver=False)
    with pytest.raises(consumer.TRANSIENT_ERRORS):
        consumer.process(FakeMessage(b"{broken"), dlq, save=Recorder())


def test_backoff_is_exponential_and_capped():
    assert [consumer.backoff_seconds(n) for n in (1, 2, 3, 4)] == [1, 2, 4, 8]
    assert consumer.backoff_seconds(50) == consumer.MAX_BACKOFF_SECONDS


def test_heartbeat_writes_file(tmp_path, monkeypatch):
    target = tmp_path / "hb"
    monkeypatch.setattr(consumer, "HEARTBEAT_FILE", str(target))
    monkeypatch.setattr(consumer, "_last_heartbeat", 0.0)
    consumer.heartbeat()
    assert target.read_text().isdigit()
