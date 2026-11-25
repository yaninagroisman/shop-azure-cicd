# Features

Statuses here mirror [ROADMAP.md](ROADMAP.md). "Verified" means it was checked on the date shown. It does not mean "the button exists".

## Working (verified)

| Feature | Where | Verified |
|---|---|---|
| Shop window: animated storefront, clickable door and sign, quips ticker, featured products | `/`, `index.html`, `magic.js` | 2026-11-25: 200, no JS errors |
| Catalogue: 13 products on 4 shelves, with search, shelf filters and sort | `/catalogue`, `catalogue.js` | Page and images 2026-11-25. Search, filter and sort were checked in an earlier session, not re-run today. |
| Product page: live preview stage, "demonstrate" button, related products | `/product/<slug>` | 2026-11-25: 200, unknown slug → 404 |
| Per-product animations (13 effects, e.g. hopping Pocket Fluffs, fizzing bees, fuses, smoke frame-swaps) | `macros.html`, `main.css`, `effects.js` | 2026-11-25 for Pocket Fluffs. Others in earlier sessions. |
| Basket: add, change quantity (1–10), remove, total in Griffins/Shards/Pips, survives reload | `basket.js`, `partials/basket.html` | 2026-11-25 `basket_test.py` |
| Checkout (mock): sending → pending → completed/failed, failed lines stay in the basket | `basket.js`, `shop.js`, `mock-api.js` | 2026-11-25 |
| The Mischief Ledger: order history with live status, reachable only from the home-page button | `/orders`, `ledger.js` | 2026-11-25 (mock) |
| Door mini-game "Mischief on the Loose": 30 s, scoring, best score, keyboard and touch | `game.js` | 2026-11-25 `gametest.py` |
| Fantasy currency (integer Pips; 1 G = 12 S = 240 P) | `money.py`, `shop.js` | 2026-11-25 (frontend only) |
| Easter eggs: typed words, secret chart, footprints, clock, sign knocks | `magic.js` | 2026-11-25 `eggs.py` (subset) |
| Mock switches `?mock=ok`, `?mock=fail`, `?mock=reset` | `mock-api.js` | earlier sessions |
| Accessibility basics: keyboard hotspots, `prefers-reduced-motion`, aria-live | across | 2026-11-25 (reduced motion, keyboard in game) |
| Security headers: CSP (no inline scripts), nosniff, Referrer-Policy | `__init__.py` | 2026-11-25 (headers present) |
| Responsive layout: no horizontal scroll at 390 px | `main.css` | 2026-11-25 |

## Partially implemented

| Feature | What exists | What is missing |
|---|---|---|
| `API_MODE=http` | Client calls `/api/buy` and `/api/purchases` and shows error states | Nothing serves these endpoints |
| Backend API | `api/database.py`, `api/Dockerfile` | `app.py`, `consumer.py` and `requirements.txt` are empty |
| Kafka | Broker in compose; topic `purchases` and group `shop-consumers` exist | Producer and consumer code |
| MongoDB | Container; `wizard_shop.purchases` with 1 test doc | Agreed schema, indexes, integration |
| Containerisation | `api/Dockerfile` | `client/Dockerfile`, Gunicorn, compose services for client, api and consumer |
| Rebranding away from third-party IP | Code and all product and storefront images | Docs and folder name; theme of the easter eggs (risk R-03) |

## Not implemented (planned)

Every Phase 2–6 item in the roadmap, in particular:

- Admin panel.
- User accounts.
- A gamification engine with achievements, rewards and secret products.
- White-label configuration and a standard currency mode.
- A labelled demo checkout and a payment interface.
- Automated tests.
- CI/CD and Azure.
