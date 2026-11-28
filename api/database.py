import os

from pymongo import ASCENDING, DESCENDING, MongoClient

MONGO_URI = os.getenv("MONGO_URI", "mongodb://mongodb:27017")

# Fail fast instead of pymongo's 30 s default: the client gives the API 5 s,
# and Kubernetes probes need a quick answer when MongoDB is down.
TIMEOUT_MS = int(os.getenv("MONGO_TIMEOUT_MS", "3000"))

# Newest purchases returned by GET /purchases. The UI polls this endpoint, so
# it must not return the whole collection.
PURCHASES_LIMIT = int(os.getenv("PURCHASES_LIMIT", "100"))

client = MongoClient(
    MONGO_URI,
    serverSelectionTimeoutMS=TIMEOUT_MS,
    connectTimeoutMS=TIMEOUT_MS,
    socketTimeoutMS=TIMEOUT_MS + 2000,
)

db = client["wizard_shop"]

purchases = db["purchases"]


def ensure_indexes():
    """Create the indexes the application relies on. Safe to call on every start.

    The unique index on purchase_id is what makes the consumer idempotent:
    a redelivered Kafka message raises DuplicateKeyError instead of creating
    a second order. Without it, duplicates are silently inserted.
    The created_at index serves the newest-first listing.
    """
    purchases.create_index([("purchase_id", ASCENDING)], unique=True)
    purchases.create_index([("created_at", DESCENDING)])


def ping():
    """Raises a PyMongoError if MongoDB is not reachable."""
    client.admin.command("ping")


def save_purchase(purchase):
    purchases.insert_one(purchase)


def get_all_purchases(limit=PURCHASES_LIMIT):
    return list(
        purchases.find({}, {"_id": 0})
        .sort("created_at", -1)
        .limit(limit)
    )
