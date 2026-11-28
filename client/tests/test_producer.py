"""Unit tests for the Kafka producer helper and the /healthz probe (no broker needed)."""
import json

import producer
import pytest


class FakeProducer:
    """Delivers (or fails, or never answers) on the first poll()."""

    def __init__(self, error=None, deliver=True):
        self.sent, self.polls = [], 0
        self._error, self._deliver, self._callback = error, deliver, None

    def produce(self, topic, key, value, on_delivery):
        self.sent.append({"topic": topic, "key": key, "value": value})
        self._callback = on_delivery

    def poll(self, _timeout):
        self.polls += 1
        if self._deliver and self._callback:
            self._callback(self._error, None)
            self._callback = None


PURCHASE = {"purchase_id": "p-1", "product_slug": "pocket-fluffs", "quantity": 1}


def test_delivered_message_is_keyed_by_purchase_id():
    fake = FakeProducer()
    assert producer.send_purchase(PURCHASE, kafka_producer=fake) is True
    assert fake.sent[0]["topic"] == producer.TOPIC
    assert fake.sent[0]["key"] == "p-1"
    assert json.loads(fake.sent[0]["value"]) == PURCHASE


def test_delivery_error_raises_runtime_error():
    with pytest.raises(RuntimeError):
        producer.send_purchase(PURCHASE, kafka_producer=FakeProducer(error="broker down"))


def test_no_delivery_report_times_out():
    with pytest.raises(TimeoutError):
        producer.send_purchase(PURCHASE, kafka_producer=FakeProducer(deliver=False), timeout=0.3)


def test_healthz(client):
    response = client.get("/healthz")
    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}
