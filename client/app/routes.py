"""Page routes. The Flask app only renders templates and serves static files.

    /                   shop window
    /catalogue          all products
    /product/<slug>     one product
    /orders             purchase history, "The Mischief Ledger" (filled in by static/js/ledger.js)
"""
from flask import Blueprint, abort, render_template

from .catalog import CATEGORIES, PRODUCTS, get_product, related_products

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


@bp.app_errorhandler(404)
def not_found(_error):
    return render_template("404.html", page="404"), 404
