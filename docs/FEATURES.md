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

### Backend and infrastructure (implemented, unit-tested)

| Feature | Where | Verified |
|---|---|---|
| Real purchases: `POST /api/buy` prices the line and publishes it to Kafka | `client/app/routes.py`, `client/producer.py` | 2026-11-28: unit tests (producer, keyed by `purchase_id`, delivery errors → 503) |
| Order history from MongoDB: `GET /api/purchases` → api `GET /purchases` | `client/app/routes.py`, `api/app.py` | 2026-11-28: unit tests |
| Kafka consumer: at-least-once, idempotent insert, `failed` with reason, dead-letter topic, retries with backoff | `api/consumer.py` | 2026-11-28: 12 unit tests |
| Health endpoints and container health checks | api `/healthz` `/readyz`, client `/healthz`, consumer heartbeat | 2026-11-28: unit tests |
| Full local stack with one `docker compose up` | `compose.yaml` | written 2026-11-27; no end-to-end run recorded |
| Production containers: Gunicorn, non-root, pinned image and dependencies | `api/Dockerfile`, `client/Dockerfile` | 2026-11-28: hadolint clean |
| Kafka SASL/SCRAM + TLS from environment variables (PLAINTEXT by default) | `kafka_config.py` | 2026-11-28: 6 unit tests in each service |

### Azure and DevOps (written, not yet running)

| Feature | Where | Status |
|---|---|---|
| Remote Terraform state, pipeline identities, Azure DevOps project, budget | `terraform/bootstrap/` | applied 2026-11-27 |
| Dev environment: AKS, ACR, Key Vault, workload identities, monitoring, public IP, Argo CD | `terraform/environments/dev/` | applied once 2026-11-28 (57/58); blocked by the 4 vCPU quota |
| GitOps: cert-manager, Strimzi Kafka, Kyverno, Gateway + Let's Encrypt, MongoDB, the shop, NetworkPolicies, image verification | `gitops-shop` | static checks only |
| CI/CD: lint, tests, Trivy, push, Cosign signing, GitOps tag bump | `.azure-pipelines/ci.yml` | not yet run |

## Partially implemented

| Feature | What exists | What is missing |
|---|---|---|
| Atomic basket checkout | one order per basket line | one order with lines (P1-19, R-07) |
| Rebranding away from third-party IP | code and all product and storefront images | folder name; theme of the easter eggs (risk R-03) |
| Deployment on Azure | everything written; bootstrap applied | a cluster that fits the quota, the first CI run, end-to-end checks |

## Not implemented (planned)

Phase 4–6 items in the roadmap, in particular:

- Admin panel.
- User accounts.
- A gamification engine with achievements, rewards and secret products.
- White-label configuration and a standard currency mode.
- A labelled demo checkout and a payment interface.
- Terraform plan/apply pipelines, rate limiting, Azure Policy.
