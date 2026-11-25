import pytest

from app.catalog import PRODUCTS

PAGES = ["/", "/catalogue", "/orders"] + [f"/product/{p['slug']}" for p in PRODUCTS]


@pytest.mark.parametrize("url", PAGES)
def test_page_renders(client, url):
    res = client.get(url)
    assert res.status_code == 200
    assert b"Marvellous Mischief" in res.data


def test_unknown_product_is_404(client):
    res = client.get("/product/no-such-thing")
    assert res.status_code == 404


def test_security_headers(client):
    h = client.get("/").headers
    csp = h["Content-Security-Policy"]
    assert "script-src 'self'" in csp and "frame-ancestors 'none'" in csp
    assert h["X-Content-Type-Options"] == "nosniff"
    assert h["Referrer-Policy"] == "same-origin"


def test_no_inline_scripts(client):
    """CSP forbids inline scripts, so every <script> must have a src."""
    import re
    for url in ("/", "/catalogue", "/orders", "/product/pocket-fluffs"):
        html = client.get(url).get_data(as_text=True)
        for tag in re.findall(r"<script\b[^>]*>", html):
            assert "src=" in tag, f"inline script on {url}: {tag}"


def test_api_mode_reaches_the_page(app, client):
    assert 'data-api-mode="mock"' in client.get("/").get_data(as_text=True)
    app.config["API_MODE"] = "http"
    try:
        assert 'data-api-mode="http"' in client.get("/").get_data(as_text=True)
    finally:
        app.config["API_MODE"] = "mock"


def test_static_assets_are_versioned(client):
    html = client.get("/").get_data(as_text=True)
    assert "/static/css/main.css?v=" in html
