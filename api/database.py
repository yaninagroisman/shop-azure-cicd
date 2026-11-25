import os
from pymongo import MongoClient

MONGO_URI = os.getenv("MONGO_URI", "mongodb://mongodb:27017")

client = MongoClient(MONGO_URI)

db = client["wizard_shop"]

purchases = db["purchases"]


def save_purchase(purchase):
    purchases.insert_one(purchase)


def get_all_purchases():
    return list(purchases.find({}, {"_id": 0}))