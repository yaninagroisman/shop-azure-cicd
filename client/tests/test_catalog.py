import os

import pytest

from app.catalog import CATEGORIES, PRODUCTS, get_product, related_products

STATIC = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "app", "static", "img", "products")
REQUIRED = ("slug", "name", "category", "tagline", "description", "price", "effect", "demo", "accent")


def images_for(p):
    names = [p["slug"]]
    if p["effect"] == "puffs":
        names += [p["slug"] + s for s in ("--box", "--violet", "--pink")]
    if p["effect"] == "ears":
        names.append(p["slug"] + "--extended")
    if p["effect"] == "snackbox":
        names.append(p["slug"] + "--open")
    return names


def test_slugs_are_unique():
    slugs = [p["slug"] for p in PRODUCTS]
    assert len(slugs) == len(set(slugs)) == 13


@pytest.mark.parametrize("product", PRODUCTS, ids=lambda p: p["slug"])
def test_product_is_complete(product):
    for field in REQUIRED:
        assert product.get(field), f"{product['slug']} has no {field}"
    assert isinstance(product["price"], int) and product["price"] > 0
    assert product["category"] in {c["slug"] for c in CATEGORIES}
    assert get_product(product["slug"]) is product


@pytest.mark.parametrize("product", PRODUCTS, ids=lambda p: p["slug"])
def test_product_images_exist(product):
    for name in images_for(product):
        for folder in ("", "640"):
            path = os.path.join(STATIC, folder, name + ".webp")
            assert os.path.isfile(path), path


def test_every_category_has_products():
    used = {p["category"] for p in PRODUCTS}
    assert used == {c["slug"] for c in CATEGORIES}


def test_related_products_exclude_itself():
    for p in PRODUCTS:
        rel = related_products(p)
        assert len(rel) == 3 and p not in rel
