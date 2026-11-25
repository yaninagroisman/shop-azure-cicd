"""Freeze the shop into plain static files for a quick Netlify preview.

Read-only for the project: it imports the Flask app, renders every page through
the test client and writes the result to <project root>/dist/ (git-ignored).
Nothing in client/ is changed.

    python optional-concepts/tools/netlify/freeze.py

Then drag the dist/ folder onto https://app.netlify.com/drop

The preview always runs in mock mode: orders live in each visitor's browser.
"""
import os
import shutil
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
CLIENT = os.path.join(ROOT, "client")
DIST = os.path.join(ROOT, "dist")

os.environ["API_MODE"] = "mock"          # no backend on a static host
sys.dont_write_bytecode = True            # leave no __pycache__ in client/
sys.path.insert(0, CLIENT)

from app import create_app                # noqa: E402
from app.catalog import PRODUCTS          # noqa: E402

# URL -> file. Netlify serves /catalogue from catalogue.html ("pretty URLs", on by default)
# and uses 404.html for every unknown address.
PAGES = {"/": "index.html", "/catalogue": "catalogue.html", "/orders": "orders.html"}
PAGES.update({f"/product/{p['slug']}": f"product/{p['slug']}.html" for p in PRODUCTS})
SECURITY_HEADERS = ("Content-Security-Policy", "X-Content-Type-Options", "Referrer-Policy")


def main():
    app = create_app()
    client = app.test_client()

    if os.path.isdir(DIST):
        shutil.rmtree(DIST)
    shutil.copytree(app.static_folder, os.path.join(DIST, "static"))

    for url, name in PAGES.items():
        res = client.get(url)
        if res.status_code != 200:
            sys.exit(f"{url} returned {res.status_code}")
        write(name, res.data)

    res = client.get("/this-page-does-not-exist")
    write("404.html", res.data)

    # The same security headers Flask sends, for every file Netlify serves.
    headers = client.get("/").headers
    lines = ["/*"] + [f"  {h}: {headers[h]}" for h in SECURITY_HEADERS if h in headers]
    write("_headers", ("\n".join(lines) + "\n").encode())

    count = sum(len(files) for _, _, files in os.walk(DIST))
    print(f"dist/ ready: {len(PAGES) + 1} pages, {count} files -> drag it onto https://app.netlify.com/drop")


def write(name, data):
    path = os.path.join(DIST, name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as fh:
        fh.write(data)


if __name__ == "__main__":
    main()
