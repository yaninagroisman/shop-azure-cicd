# Master Roadmap: Marvellous Mischief Co.

> **Single source of truth for every project task.** There are no other roadmaps. `PROJECT_STATUS.md` summarises this file and must never contradict it.
>
> Last full audit: **2026-11-25**. Last update: 2026-11-25 (owner decisions on the audit). Statuses follow the rules in [§ Rules](#rules).

## Contents

- [Rules](#rules)
- [Progress summary](#progress-summary)
- [Phase 1: Core Project Completion](#phase-1--core-project-completion)
- [Phase 2: Azure & DevOps](#phase-2--azure--devops)
- [Phase 3: Market Validation](#phase-3--market-validation)
- [Phase 4: Commercial Product Development](#phase-4--commercial-product-development)
- [Phase 5: Commercial Readiness & Packaging](#phase-5--commercial-readiness--packaging)
- [Phase 6: Sale & Handover](#phase-6--sale--handover)
- [Proposed tasks (awaiting owner approval)](#proposed-tasks-awaiting-owner-approval)

---

## Rules

**Statuses:** `NOT_STARTED`, `IN_PROGRESS`, `BLOCKED`, `IN_REVIEW`, `COMPLETED`, `DEFERRED`.

- A task is marked `COMPLETED` only when it is implemented **and** its acceptance criteria were checked. The check goes in the *Evidence* column, with a date.
- `IN_REVIEW` means the work exists, but the acceptance criteria have not all been checked yet, or the owner still has to accept the result.
- If a check is impossible, say why in *Evidence* and keep the task below `COMPLETED`.
- **Phase progress = COMPLETED tasks ÷ all tasks in the phase.** It is not an estimate. `DEFERRED` tasks are still counted.
- **Priorities:**
  - **P0**: blocks the phase.
  - **P1**: required for the phase.
  - **P2**: valuable, but the phase can close without it.
- Task IDs never change and are never reused.
- *Updated* is the date the row last changed.

## Progress summary

| Phase | Tasks | Completed | In progress / review | Blocked | Progress |
|---|---:|---:|---:|---:|---:|
| 1. Core Project Completion | 19 | 6 | 10 | 1 | **32%** |
| 2. Azure & DevOps | 17 | 0 | 0 | 0 | **0%** |
| 3. Market Validation | 12 | 1 | 0 | 0 | **8%** |
| 4. Commercial Product Development | 43 | 0 | 0 | 0 | **0%** |
| 5. Commercial Readiness & Packaging | 24 | 1 | 4 | 0 | **4%** |
| 6. Sale & Handover | 14 | 0 | 0 | 0 | **0%** |
| **Total** | **129** | **8** | **14** | **1** | **6.2%** |

**Current phase: Phase 1.** Phase 2 starts when every P0/P1 task of Phase 1 is `COMPLETED`.

---

## Phase 1 — Core Project Completion

**Ownership:** the owner writes the backend (P1-02, P1-05, P1-09, P1-10 and the backend side of P1-11 to P1-14 and P1-19) as part of the course.

Goal: the existing shop works end to end on a developer machine. That means the browser, client server, Backend API, Kafka, the consumer and MongoDB all run with one `docker compose up`, and automated tests prove it.

| ID | Task | Pri | Depends on | Status | Acceptance criteria | Evidence | Updated |
|---|---|---|---|---|---|---|---|
| P1-01 | Complete the current Frontend | P0 | P1-02 (for http mode) | IN_PROGRESS | All pages work in `API_MODE=mock` **and** `API_MODE=http` against the real API. No JS errors. Mobile and desktop layouts work. Reduced motion is respected. No unused files in `static/`. | 2026-11-25: `client/tests` all pass (64 tests: pages, catalog, money, browser smoke incl. JS errors, broken images, mobile overflow, basket, game, catalogue). Unused PNGs removed from `static/` (P1-17). Remaining: http mode against the owner's backend. 2026-11-25: mobile fixes: page can no longer be panned sideways (`html { overflow-x: clip }`), workshop steam and lamp glow follow the 4:3 crop on phones, Instant Midnight smoke kept inside the arched stage in Safari (own compositing layer; Chromium verified, WebKit could not be run here). | 2026-11-25 |
| P1-02 | Complete the current Backend | P0 | — | IN_PROGRESS | `api/app.py` serves `POST /api/buy` and `GET /api/purchases` per [API.md](API.md). `api/consumer.py` consumes the purchase topic and writes to MongoDB. `api/requirements.txt` pins every dependency. **Owner implements this as part of the course.** | 2026-11-25: `api/app.py`, `api/consumer.py` and `api/requirements.txt` are **empty** (0 bytes). Only `api/database.py` (2 functions, pymongo) and `api/Dockerfile` exist. | 2026-11-25 |
| P1-03 | Verify the Product Catalog | P1 | — | COMPLETED | 13 products render with correct names, prices, images and categories. Search, filters and sort work. (Where the backend gets the catalog is deferred to P4-03; see D-014.) | 2026-11-25: `test_catalog.py` (unique slugs, complete fields, integer prices, valid categories, all 1600 px and 640 px images exist) and `test_browser.py::test_catalogue_search_filter_and_sort` (13 visible, search "bog" → 1, empty state and reset, shelf filter, price sort) pass. | 2026-11-25 |
| P1-04 | Verify the Shopping Cart | P1 | — | COMPLETED | You can add items from cards and product pages, change quantity (1–10) and remove lines. The total is shown in Griffins/Shards/Pips. Checkout empties the basket, and the orders appear in the Ledger. The basket survives a reload. | 2026-11-25, `basket_test.py` (mock mode): 3 lines added, total "9 Griffins 5 Shards 6 Pips", 1 removed, checkout → "Order accepted!" → "Mischief delivered!", 2 Ledger entries, 0 JS errors. | 2026-11-25 |
| P1-05 | Verify Order Processing | P0 | P1-02, P1-10 | BLOCKED | An order goes `pending` → `completed`/`failed` through API → Kafka → consumer → MongoDB. A failure carries a `failure_reason`. | Blocked: no producer, consumer or API code yet (owner is writing it). The mock path works (see P1-04). | 2026-11-25 |
| P1-06 | Verify Order History | P1 | P1-02 | IN_PROGRESS | The Ledger (`/orders`) lists purchases from `GET /api/purchases`, newest first, and live-updates pending orders. | 2026-11-25: works in mock mode (basket_test: 2 entries). http mode not possible yet (endpoint returns 404). | 2026-11-25 |
| P1-07 | Complete the first mini-game | P1 | — | COMPLETED | The door opens the game. A 30-second round runs, scoring by item type. Best score is saved. Works with mouse, touch and keyboard. Closing it restores the page. | 2026-11-25, `gametest.py`: desktop and mobile 0 errors. Items of 9 types caught, score 16, result card, best score saved, dialog closes and the door shuts. | 2026-11-25 |
| P1-08 | Verify the Fantasy Currency System | P1 | P1-02 | IN_PROGRESS | Prices are stored as integer Pips everywhere (1 Griffin = 12 Shards = 240 Pips). Frontend, API and DB agree. | Frontend: `money.py` and the JS formatter are correct (basket total verified 2026-11-25). **Mismatch found:** the test document in MongoDB uses the pre-rebrand coinage (`unit_price: 493`) and a pre-rebrand slug. | 2026-11-25 |
| P1-09 | Verify the MongoDB integration | P0 | P1-02 | IN_PROGRESS | The consumer persists purchases in the agreed schema ([DATABASE.md](DATABASE.md)). The API reads them back. Indexes exist. | 2026-11-25: container `mongo:8.0` runs. DB `wizard_shop`, collection `purchases`, 1 manual test doc with a schema that differs from the contract (`purchase_id` instead of `id`, no `failure_reason`/`updated_at`). `api/database.py` has insert and find-all. | 2026-11-25 |
| P1-10 | Verify the Kafka integration | P0 | P1-02 | IN_PROGRESS | The API produces one message per order. The consumer group processes it at least once without duplicates in the DB (idempotent write). | 2026-11-25: broker `apache/kafka:4.1.2` (KRaft) runs. Topic `purchases` (3 partitions, RF 1) and consumer group `shop-consumers` exist. They were created by code that is no longer in the repo. No producer or consumer code is present. | 2026-11-25 |
| P1-11 | Error handling | P1 | P1-02 | IN_PROGRESS | The API returns JSON errors (`{"error": …}`) with correct status codes. The consumer marks orders `failed` with a reason. The UI shows every error state. | Frontend side done: `api.js` maps HTTP and network errors to messages, and http mode with no backend shows the error state (2026-11-25). Backend side missing. | 2026-11-25 |
| P1-12 | Automated testing | P0 | P1-02 (backend part) | IN_PROGRESS | The repository holds a test suite runnable with one command: client tests, API unit tests, a consumer test, and a browser smoke test of the purchase flow. | 2026-11-25: `client/tests/` added, run with `cd client && pytest` (deps in `client/requirements-dev.txt`: pytest, Playwright). 64 passed in 21.7 s. Missing: API and consumer tests (owner's backend) and an integration test through Kafka. | 2026-11-25 |
| P1-13 | Dockerfiles | P1 | P1-02 | IN_PROGRESS | `api/Dockerfile` and `client/Dockerfile` build. Production server (Gunicorn), non-root user, health check. | `api/Dockerfile` exists (python:3.12-slim, `python app.py`), but `app.py` is empty. No `client/Dockerfile`. The preview runs as an ad-hoc `docker run` with `flask run` (dev server). | 2026-11-25 |
| P1-14 | Docker Compose | P1 | P1-13 | IN_PROGRESS | `compose.yaml` starts client, api, consumer, kafka and mongodb with health-checked ordering and volumes. | `compose.yaml` has `mongodb` and `kafka` only. No client, api or consumer services. | 2026-11-25 |
| P1-15 | Reproducible local deployment | P0 | P1-12, P1-14 | NOT_STARTED | On a clean machine, following README only: `docker compose up`, then a purchase completes. Documented in [DEPLOYMENT.md](DEPLOYMENT.md). | — | 2026-11-25 |
| P1-16 | Put the project under git | P0 | — | COMPLETED | Local git repository with a `.gitignore` that excludes secrets, caches and the PNG masters; initial commit contains the whole project and no secrets. | 2026-11-25: `git init`, initial commit on `main`. Remote hosting not chosen yet (D-016). | 2026-11-25 |
| P1-17 | Remove unused source PNGs from `static/` | P1 | — | COMPLETED | No file in `client/app/static/img` is unreferenced. Masters kept outside git. | 2026-11-25: 16 PNGs (≈80 MB) moved to `optional-concepts/source-png/` (git-ignored). `static/img` is now 11 MB. Nothing referenced `.png`; all 64 tests pass. | 2026-11-25 |
| P1-18 | Scrub third-party franchise references from the docs | P0 | — | COMPLETED | No franchise names in README, REPORT, docs or code. | 2026-11-25: REPORT.md rewritten with current names (§0.12 mapping tables removed); preview container renamed `mischief-preview`; early concept image renamed. Term grep across the repo is clean. | 2026-11-25 |
| P1-19 | Atomic basket checkout (risk R-07) | P1 | P1-02 | NOT_STARTED | A basket is sent as **one** order with lines; it succeeds or fails as a whole. API contract updated in API.md and implemented on both sides (owner: backend, client: `basket.js`). Tests cover partial-failure cases. | Owner approved the fix 2026-11-25. Needs the contract change agreed with the backend first. | 2026-11-25 |

## Phase 2 — Azure & DevOps

The specific Azure services will be chosen in P2-01 after analysing requirements, cost and constraints. Nothing is decided yet.

| ID | Task | Pri | Depends on | Status | Acceptance criteria | Evidence | Updated |
|---|---|---|---|---|---|---|---|
| P2-01 | Azure Infrastructure Design | P0 | Phase 1 | NOT_STARTED | Service choice with a cost estimate and an ADR in DECISIONS.md. Covers hosting Kafka (managed vs self-hosted) and MongoDB (managed vs self-hosted). | — | 2026-11-25 |
| P2-02 | Terraform configuration | P0 | P2-01 | NOT_STARTED | `terraform plan`/`apply` creates all resources. No hard-coded secrets. | — | 2026-11-25 |
| P2-03 | Terraform State Management | P0 | P2-02 | NOT_STARTED | Remote state backend with locking, documented. | — | 2026-11-25 |
| P2-04 | Azure DevOps Pipelines | P0 | P1-12 | NOT_STARTED | A pipeline runs on every push to main and on pull requests. | — | 2026-11-25 |
| P2-05 | Automated Build | P1 | P2-04 | NOT_STARTED | Images built and tagged with the commit SHA. | — | 2026-11-25 |
| P2-06 | Automated Testing in CI | P1 | P2-04, P1-12 | NOT_STARTED | A failing test fails the pipeline. | — | 2026-11-25 |
| P2-07 | Container Registry | P1 | P2-02 | NOT_STARTED | The pipeline pushes images. Retention policy set. | — | 2026-11-25 |
| P2-08 | Automated Deployment | P1 | P2-05, P2-07 | NOT_STARTED | Merging to main deploys. Rollback documented. | — | 2026-11-25 |
| P2-09 | Secrets Management | P0 | P2-02 | NOT_STARTED | All credentials are in a secret store. None in the repo, the pipeline YAML or images. | — | 2026-11-25 |
| P2-10 | Networking | P1 | P2-01 | NOT_STARTED | Only the client/proxy is public. Kafka and MongoDB are private. | — | 2026-11-25 |
| P2-11 | Domain configuration | P2 | P2-08 | NOT_STARTED | Custom domain resolves to the demo. | — | 2026-11-25 |
| P2-12 | HTTPS | P0 | P2-11 | NOT_STARTED | Valid TLS certificate, HTTP→HTTPS redirect, HSTS. | — | 2026-11-25 |
| P2-13 | Logging and Monitoring | P1 | P2-08 | NOT_STARTED | Central logs for all services, an uptime alert and a consumer-lag metric. | — | 2026-11-25 |
| P2-14 | Cloud Cost Management | P1 | P2-01 | NOT_STARTED | Budget and alert configured. Monthly cost documented. | — | 2026-11-25 |
| P2-15 | Infrastructure Architecture Diagram | P2 | P2-01 | NOT_STARTED | Mermaid diagram in ARCHITECTURE.md matches the deployed resources. | — | 2026-11-25 |
| P2-16 | Deployment Documentation | P1 | P2-08 | NOT_STARTED | DEPLOYMENT.md lets a newcomer deploy without help. | — | 2026-11-25 |
| P2-17 | Infrastructure recreation from scratch | P0 | P2-02…P2-16 | NOT_STARTED | Destroy and re-create the environment from the repo, with timing recorded. | — | 2026-11-25 |

## Phase 3 — Market Validation

This phase starts once a public Azure demo works. It does not wait for the commercial features. The price hypothesis is **$3,000–6,000** and is **unconfirmed**.

| ID | Task | Pri | Depends on | Status | Acceptance criteria | Evidence | Updated |
|---|---|---|---|---|---|---|---|
| P3-01 | Prepare the public demo | P0 | P2-08, P2-12 | NOT_STARTED | Public URL. Demo checkout clearly labelled. | — | 2026-11-25 |
| P3-12 | Quick static preview on Netlify (mock mode) | P2 | — | COMPLETED | `dist/` builds from the app without touching `client/`; all pages, basket, Ledger and game work when served like Netlify; the owner publishes it. | 2026-11-25: `optional-concepts/tools/netlify/freeze.py` builds 17 pages and 86 files (11 MB). Served locally with Netlify-style pretty URLs and `_headers`: 5 pages 200 with CSP, unknown URL 404, 0 broken images, 0 JS errors, basket checkout → "Mischief delivered!", Ledger 1 entry, card links and door game work. Published by the owner on Netlify Drop on 2026-11-25. | 2026-11-25 |
| P3-02 | Screenshots | P1 | P3-01 | NOT_STARTED | Desktop and mobile set, free of old trademarks. | — | 2026-11-25 |
| P3-03 | Short presentation video | P1 | P3-01 | NOT_STARTED | 60–90 s video of the store, the game and the purchase flow. | — | 2026-11-25 |
| P3-04 | Research competing products | P1 | — | NOT_STARTED | Comparison table with at least 5 products in [COMMERCIAL_READINESS.md](COMMERCIAL_READINESS.md). | — | 2026-11-25 |
| P3-05 | Research SideProjectors | P1 | — | NOT_STARTED | Comparable listings, prices and fees noted. | — | 2026-11-25 |
| P3-06 | Research Flippa | P1 | — | NOT_STARTED | Comparable listings, prices and fees noted. | — | 2026-11-25 |
| P3-07 | Identify potential buyers | P1 | P3-04 | NOT_STARTED | Buyer segments with at least 10 named example targets. | — | 2026-11-25 |
| P3-08 | Test interest in a Gamified E-commerce Platform | P1 | P3-01 | NOT_STARTED | Defined outreach and a recorded response rate. | — | 2026-11-25 |
| P3-09 | Collect feedback | P1 | P3-08 | NOT_STARTED | Feedback log with at least 5 entries. | — | 2026-11-25 |
| P3-10 | Check willingness to pay | P0 | P3-08 | NOT_STARTED | Price signals recorded against the hypothesis. | — | 2026-11-25 |
| P3-11 | Adjust commercial priorities | P0 | P3-09, P3-10 | NOT_STARTED | Owner-approved re-prioritisation of Phase 4, recorded in DECISIONS.md. | — | 2026-11-25 |

## Phase 4 — Commercial Product Development

Constraints:

- Game mechanics must be independent of the store's theme.
- Universality must not destroy the existing visual concept.
- Real payments are out of scope for v1, and demo payments must be labelled.

The scope may change after P3-11.

### Admin Panel

The admin panel also settles D-014 (where the catalog and prices live) in P4-03.

| ID | Task | Pri | Depends on | Status | Acceptance criteria | Evidence | Updated |
|---|---|---|---|---|---|---|---|
| P4-01 | Admin Authentication | P0 | Phase 1 | NOT_STARTED | Secure login, hashed passwords, session expiry, rate limiting. | — | 2026-11-25 |
| P4-02 | Role-Based Access Control | P1 | P4-01 | NOT_STARTED | Roles enforced server-side on every admin endpoint. | — | 2026-11-25 |
| P4-03 | Product Management | P0 | P4-01, D-014 | NOT_STARTED | CRUD for products, reflected in the store without a redeploy. Includes the decision on where the catalog and prices live (D-014), which the backend then uses for pricing. | — | 2026-11-25 |
| P4-04 | Category Management | P1 | P4-03 | NOT_STARTED | CRUD for categories (shelves). | — | 2026-11-25 |
| P4-05 | Image Management | P1 | P4-03 | NOT_STARTED | Upload, validation and resized copies. | — | 2026-11-25 |
| P4-06 | Pricing Management | P1 | P4-03 | NOT_STARTED | Prices edited in the active currency mode and stored as integer minor units. | — | 2026-11-25 |
| P4-07 | Inventory Management | P2 | P4-03 | NOT_STARTED | Stock levels, with orders rejected when stock runs out. | — | 2026-11-25 |
| P4-08 | Order Management | P1 | P1-05 | NOT_STARTED | List, filter and change order status. | — | 2026-11-25 |
| P4-09 | Store Settings | P1 | P4-01 | NOT_STARTED | Name, contact and texts editable. | — | 2026-11-25 |
| P4-10 | Game Settings | P2 | P4-19 | NOT_STARTED | Enable or disable games and tune their parameters. | — | 2026-11-25 |
| P4-11 | Reward Settings | P2 | P4-23 | NOT_STARTED | Configure rewards and unlock conditions. | — | 2026-11-25 |

### User Management

| ID | Task | Pri | Depends on | Status | Acceptance criteria | Evidence | Updated |
|---|---|---|---|---|---|---|---|
| P4-12 | User Registration | P1 | Phase 1 | NOT_STARTED | Email and password with validation. | — | 2026-11-25 |
| P4-13 | User Authentication | P1 | P4-12 | NOT_STARTED | Login, logout, password reset and secure cookies. | — | 2026-11-25 |
| P4-14 | User Profile | P2 | P4-13 | NOT_STARTED | View and edit profile. | — | 2026-11-25 |
| P4-15 | Personal Order History | P1 | P4-13, P1-06 | NOT_STARTED | The Ledger shows only the signed-in user's orders. | — | 2026-11-25 |
| P4-16 | Game Progress | P2 | P4-13, P4-19 | NOT_STARTED | Stored server-side per user. | — | 2026-11-25 |
| P4-17 | Achievements | P2 | P4-22 | NOT_STARTED | Visible in the profile. | — | 2026-11-25 |
| P4-18 | Unlocked Products | P2 | P4-25 | NOT_STARTED | Unlocked secret products persist per user. | — | 2026-11-25 |

### Gamification Engine

| ID | Task | Pri | Depends on | Status | Acceptance criteria | Evidence | Updated |
|---|---|---|---|---|---|---|---|
| P4-19 | Universal mini-game architecture | P0 | P1-07 | NOT_STARTED | Games are plug-ins behind one interface (start, score, finish events). Today's door game is ported to it. | — | 2026-11-25 |
| P4-20 | Ability to add new games | P1 | P4-19 | NOT_STARTED | A new game is added without touching engine code. Documented. | — | 2026-11-25 |
| P4-21 | Hidden game elements | P2 | P4-19 | NOT_STARTED | Configurable hidden triggers (the existing easter eggs become data). | — | 2026-11-25 |
| P4-22 | Progress tracking | P1 | P4-19 | NOT_STARTED | Game events recorded per user or session. | — | 2026-11-25 |
| P4-23 | Achievement system | P1 | P4-22 | NOT_STARTED | Rules evaluated server-side. | — | 2026-11-25 |
| P4-24 | Reward system | P1 | P4-23 | NOT_STARTED | Rewards (discounts, items) granted server-side. | — | 2026-11-25 |
| P4-25 | Unlock Conditions | P1 | P4-23 | NOT_STARTED | Declarative conditions evaluated server-side. | — | 2026-11-25 |
| P4-26 | Secret Products | P2 | P4-25, P4-03 | NOT_STARTED | Hidden until unlocked. Not leaked in HTML or the API. | — | 2026-11-25 |
| P4-27 | Secret Collections | P2 | P4-26 | NOT_STARTED | Groups of secret products. | — | 2026-11-25 |
| P4-28 | Game events integrated with the Backend | P0 | P4-22, P1-02 | NOT_STARTED | Events go through the API (and Kafka if justified in an ADR). | — | 2026-11-25 |
| P4-29 | Anti-tampering for game achievements | P0 | P4-28 | NOT_STARTED | Scores and rewards cannot be granted by editing `localStorage` or replaying requests. Plausibility checks run server-side. | — | 2026-11-25 |
| P4-30 | 3–5 quality mini-games for v1 | P1 | P4-20 | NOT_STARTED | 3–5 games, each tested on mobile, keyboard and reduced motion. 1 exists today (P1-07). | — | 2026-11-25 |

### White-Label Configuration

| ID | Task | Pri | Depends on | Status | Acceptance criteria | Evidence | Updated |
|---|---|---|---|---|---|---|---|
| P4-31 | Configurable Store Name | P0 | — | NOT_STARTED | Set in config, no code edits. Today it is hard-coded in templates. | — | 2026-11-25 |
| P4-32 | Configurable Logo | P1 | P4-31 | NOT_STARTED | Logo replaceable by a file and config. | — | 2026-11-25 |
| P4-33 | Color Themes | P1 | — | NOT_STARTED | Theme = one token file overriding the `:root` tokens in `main.css`. | — | 2026-11-25 |
| P4-34 | Configurable Branding | P1 | P4-31…P4-33 | NOT_STARTED | Brand texts, quips and easter-egg words come from config. | — | 2026-11-25 |
| P4-35 | Custom Product Catalog | P0 | P4-03 | NOT_STARTED | The catalog is loaded from the DB or a data file, not `catalog.py`. | — | 2026-11-25 |
| P4-36 | Fantasy Currency Mode | P1 | P1-08 | NOT_STARTED | The current 3-tier coinage is a configurable mode (names, ratios, coin images). | — | 2026-11-25 |
| P4-37 | Standard Currency Mode | P1 | P4-36 | NOT_STARTED | ISO currency with locale formatting. | — | 2026-11-25 |
| P4-38 | Configurable Content | P2 | P4-34 | NOT_STARTED | Page copy editable without code. | — | 2026-11-25 |
| P4-39 | Business logic independent of the theme | P0 | P4-35 | NOT_STARTED | Orders, pricing and games contain no theme strings. Product effects are mapped by config. | — | 2026-11-25 |

### Checkout

| ID | Task | Pri | Depends on | Status | Acceptance criteria | Evidence | Updated |
|---|---|---|---|---|---|---|---|
| P4-40 | Demonstration Checkout | P0 | P1-05 | NOT_STARTED | Checkout is clearly labelled "demo, no payment taken". One order per basket (see risk R-07). | — | 2026-11-25 |
| P4-41 | Order Confirmation | P1 | P4-40 | NOT_STARTED | Confirmation screen with the order id. | — | 2026-11-25 |
| P4-42 | Payment Provider Interface | P1 | P4-40 | NOT_STARTED | Abstract interface plus a demo implementation. No real provider. | — | 2026-11-25 |
| P4-43 | Documentation for future payment integration | P1 | P4-42 | NOT_STARTED | Integration guide for a buyer. | — | 2026-11-25 |

## Phase 5 — Commercial Readiness & Packaging

| ID | Task | Pri | Depends on | Status | Acceptance criteria | Evidence | Updated |
|---|---|---|---|---|---|---|---|
| P5-01 | Final Architecture Review | P0 | Phase 4 | NOT_STARTED | Review recorded. Findings resolved or listed as known limitations. | — | 2026-11-25 |
| P5-02 | Code Quality Review | P1 | Phase 4 | NOT_STARTED | Linters clean. Dead code removed. | — | 2026-11-25 |
| P5-03 | Security Audit | P0 | Phase 4 | NOT_STARTED | OWASP Top-10 checklist done. Findings fixed. | — | 2026-11-25 |
| P5-04 | Dependency Audit | P0 | — | NOT_STARTED | `pip-audit` (or equivalent) clean. Versions pinned. | — | 2026-11-25 |
| P5-05 | Automated Tests | P0 | P1-12 | NOT_STARTED | Suite green in CI, with critical paths covered. | — | 2026-11-25 |
| P5-06 | UI/UX Review | P1 | — | NOT_STARTED | Review notes resolved. | — | 2026-11-25 |
| P5-07 | Responsive Design Review | P1 | — | NOT_STARTED | 360, 390, 768, 1024, 1440 and 1920 px checked. | Partial history: 390 and 1440 px checked repeatedly in 2026-11. | 2026-11-25 |
| P5-08 | Performance Testing | P1 | P2-08 | NOT_STARTED | Lighthouse ≥ 90 performance on the demo. API load test documented. | — | 2026-11-25 |
| P5-09 | Accessibility Review | P1 | — | NOT_STARTED | WCAG 2.2 AA checklist passed. | Partial: keyboard access to door, sign and game items, `prefers-reduced-motion`, aria-live in game and basket. No formal audit. | 2026-11-25 |
| P5-10 | Clean Repository | P0 | P1-16, P1-17 | IN_PROGRESS | No unused assets or temp files. Clean history. | 2026-11-25: git started with a clean first commit; PNG masters and caches ignored. Re-check before sale. | 2026-11-25 |
| P5-11 | Secret Scanning | P0 | P1-16 | NOT_STARTED | A scanner (for example gitleaks) runs over the full history with 0 findings. | 2026-11-25: informal grep only (no passwords, tokens or keys). This is not a scan. | 2026-11-25 |
| P5-12 | Software License Review | P0 | — | NOT_STARTED | A licence chosen for the sale. All third-party licences listed. | Known so far: Flask (BSD-3), pymongo (Apache-2.0), fonts (SIL OFL, licence file included). | 2026-11-25 |
| P5-13 | Intellectual Property Review | P0 | P1-18 | IN_PROGRESS | No third-party trademarks or recognisable IP in code, assets, docs, names or history. | 2026-11-25: code and docs scrubbed (P1-18); all product images and the storefront show the new brand. **Open:** project folder name; easter eggs kept as they are by owner decision (D-021); final review by a lawyer before listing. 2026-11-25: hero margin note re-signed "— R." (was "— F.", not a shop character). Open: the gift tag in `workshop-night.webp` reads "WWW". | 2026-11-25 |
| P5-14 | Right to sell a project created during training | P0 | — | COMPLETED | Confirmation that the owner may sell it. | 2026-11-25: owner confirmed that the training contract allows commercial sale. Keep a copy of the relevant clause for buyer due diligence (P5-17). | 2026-11-25 |
| P5-15 | Terms of use for AI-generated assets | P0 | — | IN_PROGRESS | Generator and terms recorded per asset. Commercial transfer allowed. | 2026-11-25: generator recorded: **ChatGPT (OpenAI image generation)**, by the owner, for all photographic images. Open: record generation dates and prompts, check the account's terms at generation time, note the limited copyright of AI output in the listing. | 2026-11-25 |
| P5-16 | Rights to images, fonts and third-party libraries | P0 | P5-12, P5-15 | IN_PROGRESS | Asset register with source and licence for every file. | 2026-11-25: licences recorded (images: ChatGPT/owner; SVGs: original; fonts: SIL OFL; Flask BSD-3, pymongo Apache-2.0, pytest MIT, Playwright Apache-2.0). Open: dependencies of the owner's backend. | 2026-11-25 |
| P5-17 | Buyer Documentation | P0 | — | NOT_STARTED | Buyer pack index complete. | — | 2026-11-25 |
| P5-18 | Installation Guide | P0 | P1-15 | NOT_STARTED | A newcomer installs from the guide alone. | — | 2026-11-25 |
| P5-19 | Rebranding Guide | P0 | P4-31…P4-39 | NOT_STARTED | Rebrand the demo to a second theme using only the guide. | — | 2026-11-25 |
| P5-20 | Deployment Guide | P0 | P2-16 | NOT_STARTED | Buyer deploys to their own Azure subscription. | — | 2026-11-25 |
| P5-21 | Known Limitations | P1 | — | NOT_STARTED | List shipped to the buyer. | — | 2026-11-25 |
| P5-22 | Final Demo Website | P0 | P3-01 | NOT_STARTED | Final version deployed. | — | 2026-11-25 |
| P5-23 | Promotional Video | P1 | P5-22 | NOT_STARTED | 2–3 min video. | — | 2026-11-25 |
| P5-24 | Product Listing | P0 | P5-22 | NOT_STARTED | Listing text, screenshots, price. | — | 2026-11-25 |

## Phase 6 — Sale & Handover

The goal is a full sale of the agreed assets to one buyer, with no mandatory subscription or long-term support.

| ID | Task | Pri | Depends on | Status | Acceptance criteria | Evidence | Updated |
|---|---|---|---|---|---|---|---|
| P6-01 | Choose the marketplace | P0 | P3-05, P3-06 | NOT_STARTED | Decision recorded in DECISIONS.md. | — | 2026-11-25 |
| P6-02 | Set the starting price | P0 | P3-10 | NOT_STARTED | Price justified by Phase 3 data. | — | 2026-11-25 |
| P6-03 | Publish the listing | P0 | P5-24, P6-01 | NOT_STARTED | Listing live. | — | 2026-11-25 |
| P6-04 | Demos for potential buyers | P1 | P6-03 | NOT_STARTED | Demo script, with demos logged. | — | 2026-11-25 |
| P6-05 | Agree deal terms | P0 | P6-04 | NOT_STARTED | Signed terms. | — | 2026-11-25 |
| P6-06 | Agree the transferred rights | P0 | P5-14, P5-16 | NOT_STARTED | Rights schedule attached to the agreement. | — | 2026-11-25 |
| P6-07 | Secure payment mechanism | P0 | P6-05 | NOT_STARTED | Escrow or equivalent. | — | 2026-11-25 |
| P6-08 | Source Code Transfer | P0 | P6-07 | NOT_STARTED | Repository transferred and buyer confirms. | — | 2026-11-25 |
| P6-09 | Documentation Transfer | P0 | P6-07 | NOT_STARTED | Buyer pack delivered. | — | 2026-11-25 |
| P6-10 | Asset Transfer | P0 | P6-07 | NOT_STARTED | All source assets (including originals) delivered. | — | 2026-11-25 |
| P6-11 | Infrastructure Handover | P1 | P6-07 | NOT_STARTED | Azure resources transferred or destroyed, per agreement. | — | 2026-11-25 |
| P6-12 | Credential Rotation | P0 | P6-11 | NOT_STARTED | All secrets rotated after transfer. | — | 2026-11-25 |
| P6-13 | Removal of Personal Access | P0 | P6-12 | NOT_STARTED | Owner access removed everywhere, verified. | — | 2026-11-25 |
| P6-14 | Final Handover Checklist | P0 | P6-08…P6-13 | NOT_STARTED | [HANDOVER.md](HANDOVER.md) checklist signed off by the buyer. | — | 2026-11-25 |

---

## Proposed tasks

None open. The audit proposals of 2026-11-25 were decided by the owner on the same day:

| Old ID | Decision |
|---|---|
| PX-01 git | Approved → P1-16 (done) |
| PX-02 unused PNGs | Approved → P1-17 (done) |
| PX-03 stale docs | Approved → done together with P1-18 |
| PX-04 catalog source (D-014) | Deferred to the admin panel → P4-03 |
| PX-05 atomic checkout | Approved → P1-19 |
| PX-06 tests in the repo | Approved → part of P1-12 (client suite done) |
