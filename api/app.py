from flask import Flask, jsonify
from pymongo.errors import PyMongoError

import database

app = Flask(__name__)


@app.route("/purchases", methods=["GET"])
def get_purchases():
    try:
        return jsonify({"purchases": database.get_all_purchases()})
    except PyMongoError:
        app.logger.exception("Reading purchases failed")
        return jsonify({"error": "Database unavailable"}), 503


@app.get("/healthz")
def healthz():
    """Liveness: the process is up. Deliberately no MongoDB check, so a database
    outage does not make Kubernetes restart every API pod."""
    return jsonify({"status": "ok"})


@app.get("/readyz")
def readyz():
    """Readiness: only send traffic to this pod while MongoDB answers."""
    try:
        database.ping()
    except PyMongoError:
        return jsonify({"status": "unavailable", "mongodb": "down"}), 503
    return jsonify({"status": "ok", "mongodb": "up"})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
