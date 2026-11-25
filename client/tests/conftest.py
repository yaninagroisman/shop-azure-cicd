"""Shared fixtures: the Flask app, its test client and, for browser tests, a live server."""
import os
import sys
import threading

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))  # client/ on the path

from app import create_app  # noqa: E402


@pytest.fixture(scope="session")
def app():
    app = create_app()
    app.config.update(TESTING=True)
    return app


@pytest.fixture()
def client(app):
    return app.test_client()


@pytest.fixture(scope="session")
def live_server(app):
    """Serve the app on a free local port in a background thread (mock API mode)."""
    from werkzeug.serving import make_server

    server = make_server("127.0.0.1", 0, app, threaded=True)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    yield f"http://127.0.0.1:{server.server_port}"
    server.shutdown()


@pytest.fixture(scope="session")
def browser():
    sync_api = pytest.importorskip("playwright.sync_api", reason="playwright is not installed")
    with sync_api.sync_playwright() as p:
        try:
            b = p.chromium.launch()
        except Exception as exc:  # browser binary missing
            pytest.skip(f"Chromium is not available: run `playwright install chromium` ({exc})")
        yield b
        b.close()


@pytest.fixture()
def make_page(browser, live_server):
    """Open a fresh desktop page that records JavaScript errors in page.js_errors.

    bypass_csp=True is only for tests that need Playwright's wait_for_function (it evaluates
    strings, which the shop's strict CSP forbids). Error checks use the strict default."""
    contexts = []

    def _make(bypass_csp=False):
        context = browser.new_context(viewport={"width": 1440, "height": 900}, bypass_csp=bypass_csp)
        contexts.append(context)
        pg = context.new_page()
        pg.js_errors = []
        pg.on("pageerror", lambda e: pg.js_errors.append(str(e)))
        pg.on("console", lambda m: m.type == "error" and pg.js_errors.append(m.text))
        pg.base = live_server
        return pg

    yield _make
    for c in contexts:
        c.close()
