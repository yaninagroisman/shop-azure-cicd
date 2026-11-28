"""Unit tests for the API endpoints (MongoDB is replaced by monkeypatching)."""
import app as api
import database
import pytest
from pymongo.errors import ServerSelectionTimeoutError


@pytest.fixture()
def client():
    api.app.config.update(TESTING=True)
    return api.app.test_client()


def down(*_args, **_kwargs):
    raise ServerSelectionTimeoutError("mongodb down")


def test_purchases_returns_list(client, monkeypatch):
    monkeypatch.setattr(database, "get_all_purchases", lambda: [{"purchase_id": "p-1"}])
    response = client.get("/purchases")
    assert response.status_code == 200
    assert response.get_json() == {"purchases": [{"purchase_id": "p-1"}]}


def test_purchases_mongodb_down_is_503_json(client, monkeypatch):
    monkeypatch.setattr(database, "get_all_purchases", down)
    response = client.get("/purchases")
    assert response.status_code == 503
    assert "error" in response.get_json()


def test_healthz_does_not_touch_mongodb(client, monkeypatch):
    monkeypatch.setattr(database, "ping", down)
    assert client.get("/healthz").status_code == 200


def test_readyz_ok(client, monkeypatch):
    monkeypatch.setattr(database, "ping", lambda: None)
    assert client.get("/readyz").status_code == 200


def test_readyz_mongodb_down(client, monkeypatch):
    monkeypatch.setattr(database, "ping", down)
    assert client.get("/readyz").status_code == 503


def test_listing_is_limited():
    calls = {}

    class FakeCursor:
        def sort(self, *args):
            calls["sort"] = args
            return self

        def limit(self, n):
            calls["limit"] = n
            return self

        def __iter__(self):
            return iter([])

    original = database.purchases
    try:
        database.purchases = type("C", (), {"find": lambda self, *a: FakeCursor()})()
        database.get_all_purchases()
    finally:
        database.purchases = original
    assert calls["sort"] == ("created_at", -1)
    assert calls["limit"] == database.PURCHASES_LIMIT
