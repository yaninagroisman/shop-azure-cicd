"""Marvellous Mischief Co.: a minimal Flask app that renders the shop front."""
import hashlib
import os

from flask import Flask, url_for

from .catalog import CATEGORIES, category_name
from .config import Config

QUIPS = [
    "Why walk when you can be carried out on a stretcher? Truant's Tuckboxes, aisle two.",
    "Exam season discount: 0%. Exam season excuses: unlimited.",
    "Our Bottled Bogs are now 30% more boggy.",
    "Rufus & Reynard accept no responsibility, liability or angry letters.",
    "Pocket Fluffs: now in Violet. Do not tell the Council.",
    "Ask about our Council-approved* products. (*Not approved.)",
    "Shoplifters will be turned into canaries. We have the creams to prove it.",
    "Come for a Diversion Cracker. Stay because you cannot find the exit.",
]


def create_app() -> Flask:
    app = Flask(__name__)
    app.config.from_object(Config)

    from .routes import bp
    app.register_blueprint(bp)

    _register_template_helpers(app)
    _register_security_headers(app)
    return app


def _register_template_helpers(app: Flask) -> None:
    hashes: dict = {}

    def asset(filename: str) -> str:
        """URL of a static file with a content hash, so browsers can cache it forever."""
        if filename not in hashes:
            path = os.path.join(app.static_folder, filename)
            with open(path, "rb") as fh:
                hashes[filename] = hashlib.md5(fh.read()).hexdigest()[:10]
        return url_for("static", filename=filename, v=hashes[filename])

    app.jinja_env.globals.update(
        asset=asset,
        categories=CATEGORIES,
        category_name=category_name,
        quips=QUIPS,
    )


def _register_security_headers(app: Flask) -> None:
    @app.after_request
    def add_headers(response):
        # Everything (scripts, fonts, images, API calls) comes from our own origin.
        response.headers.setdefault(
            "Content-Security-Policy",
            "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; "
            "script-src 'self'; connect-src 'self'; font-src 'self'; frame-ancestors 'none'; "
            "base-uri 'self'; form-action 'self'",
        )
        response.headers.setdefault("X-Content-Type-Options", "nosniff")
        response.headers.setdefault("Referrer-Policy", "same-origin")
        return response
