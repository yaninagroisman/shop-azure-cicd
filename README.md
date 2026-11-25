# Marvellous Mischief Co. 🎆

The shop-front of a magical joke shop. It's the visual frontend for an educational DevOps project (Kafka + MongoDB).

**Status (2026-11-25):** the frontend is complete in mock mode; the backend (`api/`, Kafka, MongoDB) is not implemented yet. See [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md).

The client is a minimal Flask app that renders Jinja2 templates and serves static files. The CSS and vanilla JavaScript do the rest. Purchases are **simulated in the browser** by a separate mock, so you can replace it with your own backend later.

## Documentation

| File | What it is |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | Permanent working rules (documentation updates, constraints) |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Master roadmap: the single source of truth for tasks |
| [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md) | Current phase, progress, next tasks |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Current vs target architecture, read and write flows, Kafka |
| [`docs/API.md`](docs/API.md) · [`docs/DATABASE.md`](docs/DATABASE.md) | API contract and MongoDB schema |
| [`docs/FEATURES.md`](docs/FEATURES.md) | What works, what is partial, what is planned |
| [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md) | Tokens, components, imagery rules |
| [`docs/SECURITY.md`](docs/SECURITY.md) · [`docs/TESTING.md`](docs/TESTING.md) · [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) | Security, tests, how to run |
| [`docs/COMMERCIAL_READINESS.md`](docs/COMMERCIAL_READINESS.md) | Readiness checklist and risk register |
| [`docs/DECISIONS.md`](docs/DECISIONS.md) · [`docs/HANDOVER.md`](docs/HANDOVER.md) · [`docs/PRODUCT_VISION.md`](docs/PRODUCT_VISION.md) | Decisions, handover, vision |
| [`CHANGELOG.md`](CHANGELOG.md) | Changes |
| [`REPORT.md`](REPORT.md) | Detailed work log (Russian) |

## Run it

```bash
cd client
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
flask --app wsgi run --debug
```

Open <http://127.0.0.1:5000>. The WSGI entry point for a production server is `wsgi:app`.

## Tests

```bash
cd client
pip install -r requirements-dev.txt && playwright install chromium
pytest            # 64 tests; `pytest -m "not browser"` for the fast ones
```

See [`docs/TESTING.md`](docs/TESTING.md).

## Pages

| Page | URL |
|---|---|
| Shop window: animated storefront | `/` |
| Catalogue: search, shelf filters, sorting | `/catalogue` |
| Product page with live preview and a "demonstrate" button | `/product/<slug>` |
| **The Mischief Ledger**: the enchanted ledger of purchases | `/orders` |

## Project layout

```
client/
  wsgi.py                 app = create_app()
  requirements.txt        Flask (pinned)
  requirements-dev.txt    pytest, Playwright (tests only)
  tests/                  automated tests
  app/
    __init__.py           app factory, template helpers, security headers
    config.py             API_MODE, POLL_INTERVAL_MS (from environment variables)
    routes.py             page routes only
    catalog.py            mock product data: 13 products, texts, prices, effects
    money.py              Griffins / Shards / Pips (1 Griffin = 12 Shards = 240 Pips)
    templates/            pages and partials (macros.html builds each product's photo stage)
    static/css/main.css   the whole visual design
    static/js/
      boot.js             page-entrance transition (runs first)
      magic.js            sparks, fireworks, toasts, transitions, footprints, secrets
      mock-api.js         ← the pretend backend (delete when the real one exists)
      api.js              ← ShopAPI: the ONE place that talks to a backend
      shop.js             money formatting, order tracking, pending/completed/failed UI
      basket.js           the basket drawer and checkout (one ShopAPI.buy per line)
      effects.js          Pocket Fluffs, Instant Midnight, demo buttons
      catalogue.js        search / filter / sort
      ledger.js           The Mischief Ledger (/orders)
      game.js             the door mini-game on the home page ("Mischief on the Loose")
    static/fonts/         self-hosted Fraunces, IM Fell English, Caveat (OFL)
    static/img/           photographs: scenes/, products/, textures/, sprites/ (see ASSETS.md)
```

## Purchases: mock now, your backend later

All purchase calls go through `window.ShopAPI` in `static/js/api.js`:

```js
ShopAPI.buy(product, quantity)   // -> Promise<Purchase>, status "pending"
ShopAPI.getAllBoughtItems()      // -> Promise<Purchase[]>, newest first
```

```jsonc
// Purchase
{
  "id": "…", "product_slug": "pocket-fluffs", "product_name": "Pocket Fluffs",
  "quantity": 2, "unit_price": 300, "total_price": 600,    // in Pips
  "status": "pending" | "completed" | "failed",
  "failure_reason": null,                                   // text when failed
  "created_at": "2026-11-25T10:00:00Z", "updated_at": "…"
}
```

`pending` means the order was **accepted** but not yet **processed**. The UI keeps re-reading `getAllBoughtItems()` every `POLL_INTERVAL_MS` until each order is `completed` (fireworks) or `failed` (error with the reason). That matches an asynchronous Kafka flow.

Switch modes with the `API_MODE` environment variable (no code changes):

| `API_MODE` | What happens |
|---|---|
| `mock` (default) | `mock-api.js` simulates orders in `localStorage`: accepted in about 0.5 s, processed after 3–7 s, about 10% fail |
| `http` | The browser calls **same-origin** endpoints that your backend (or a reverse proxy in front of it) provides: |

```
POST /api/buy         {"product_slug": "pocket-fluffs", "quantity": 2}
                      → 202  {"purchase": Purchase}   (or a bare Purchase)
GET  /api/purchases   → 200  {"purchases": [Purchase, …]}   (or a bare array)
```

Example: `API_MODE=http flask --app wsgi run`. In `http` mode the browser shows the error states until `/api/...` exists. No hostnames are hard-coded anywhere.

Mock demo switches (add to any URL): `?mock=fail` (every new order fails), `?mock=ok` (none fail), `?mock=reset` (clear the history).

## Things to discover 🤫

- Move your mouse near a **Pocket Fluff**. Click it.
- Hover over the **Long-Reach Listeners** and the **Truant's Tuckbox** (or tap the Tuckbox on the home page); on product pages press the demo button.
- Push the shop door in the storefront photo: the stock escapes, and you have 30 seconds to catch it (mini-game, `static/js/game.js`). Typing `reserare` just unlocks the door.
- Throw a pinch of **Instant Midnight Powder**.
- Type `lucerna` (then `umbra`). Type `reserare` on the home page, or `advenio` anywhere.
- Type *nothing up my sleeve* to unfold the Prowler's Chart (and *all clear* to fold it), or find the footprints in the footer.
- Knock on the swinging shop sign three times.
- Watch the family clock while an order is in flight.
- Mysterious footprints wander across the page now and then.
- With *prefers-reduced-motion* enabled, all of the movement switches off.

*© Marvellous Mischief Co. All mischief is fictional and all Griffins are imaginary.*

> **Images:** all product photos and the storefront were replaced with versions branded "Marvellous Mischief Co." (checked visually on 2026-11-25). `ASSETS.md` §1–9 is the original brief and still uses the old names; only §0 is current.
