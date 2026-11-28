"""Page routes. The Flask app only renders templates and serves static files.

    /                   shop window
    /catalogue          all products
    /product/<slug>     one product
    /orders             purchase history, "The Mischief Ledger" (filled in by static/js/ledger.js)
"""
import os
from datetime import UTC, datetime
from uuid import uuid4

import requests
from confluent_kafka import KafkaException
from flask import Blueprint, abort, jsonify, render_template, request
from producer import send_purchase

from .catalog import CATEGORIES, PRODUCTS, get_product, related_products

API_URL = os.getenv("API_URL", "http://api:5000")
bp = Blueprint("shop", __name__)


@bp.get("/")
def home():
    featured = [get_product(s) for s in ("pocket-fluffs", "skyroarer-rockets", "long-reach-listeners", "songbird-creams")]
    return render_template("index.html", featured=featured, snackbox=get_product("truants-tuckbox"),
                           products=PRODUCTS, page="home")  # products: the stock that escapes in the door game


@bp.get("/catalogue")
def catalogue():
    return render_template("catalogue.html", products=PRODUCTS, categories=CATEGORIES, page="catalogue")


@bp.get("/product/<slug>")
def product(slug):
    item = get_product(slug)
    if item is None:
        abort(404)
    return render_template("product.html", product=item, related=related_products(item), page="catalogue")


@bp.get("/orders")
def orders():
    return render_template("orders.html", page="ledger")


@bp.get("/healthz")
def healthz():
    """Liveness and readiness probe. Deliberately no Kafka or API check: the
    pages render without them, and /api/* already answers 503 on its own."""
    return jsonify({"status": "ok"})


@bp.app_errorhandler(404)
def not_found(_error):
    return render_template("404.html", page="404"), 404

@bp.post("/api/buy")
def buy():

    data = request.get_json(silent=True)

    if not isinstance(data, dict):
        return jsonify({"error": "Invalid JSON"}), 400

    slug = data.get("product_slug")
    quantity = data.get("quantity")

    if not isinstance(slug, str):
        return jsonify({"error": "Invalid product"}), 400

    item = get_product(slug)

    if item is None:
        return jsonify({"error": "Product not found"}), 404

    if type(quantity) is not int or not 1 <= quantity <= 10:
        return jsonify({"error": "Invalid quantity"}), 400
    purchase_id = str(uuid4())
    now = datetime.now(UTC).isoformat()

    purchase = {
        "id": purchase_id,
        "purchase_id": purchase_id,
        "product_slug": slug,
        "product_name": item["name"],
        "quantity": quantity,
        "unit_price": item["price"],
        "total_price": item["price"] * quantity,
        "status": "pending",
        "failure_reason": None,
        "created_at": now,
        "updated_at": now
    }
    try:
        send_purchase(purchase)

    except (KafkaException, TimeoutError, RuntimeError, BufferError):
        return jsonify({"error": "Purchase service unavailable"}), 503

    return jsonify({"purchase": purchase}), 202

@bp.get("/api/purchases")
def get_purchases():
    try:
        response = requests.get(
            f"{API_URL}/purchases",
            timeout=5
        )

        response.raise_for_status()

        return jsonify(response.json()), 200

    except requests.RequestException:
        return jsonify({
            "error": "Purchase history unavailable"
        }), 503