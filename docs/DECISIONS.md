# Decision Log (ADR-lite)

Each decision has an ID, a date, a status, the context, the decision and its consequences.

**Statuses:**

- **Accepted**: in force.
- **Proposed**: awaiting the owner.
- **Superseded**: replaced by a later decision.

D-001 to D-013 were made during the frontend work before 2026-11-25. They are recorded retroactively from `REPORT.md` and the code.

## Accepted

| ID | Date | Decision | Context and consequences |
|---|---|---|---|
| D-001 | ≤2026-11-25 | **Stack: Flask + Jinja2 + plain CSS + vanilla JS, no frontend framework, no build step** | Course requirement plus simplicity for a buyer. Dependencies: Flask only. |
| D-002 | ≤2026-11-25 | **One backend seam: `window.ShopAPI`** (`api.js`) with `buy()` and `getAllBoughtItems()` | The UI never calls `fetch` directly, so swapping the mock for the real API needs no UI changes. |
| D-003 | ≤2026-11-25 | **In-browser mock (`mock-api.js`) selected by the `API_MODE` env var** | The frontend can be developed and demoed with no backend. Remove the mock when the API exists. |
| D-004 | ≤2026-11-25 | **Same-origin `/api/*`, no hard-coded hosts** | Keeps CSP `connect-src 'self'` and avoids CORS. The API must be proxied under the client's origin. |
| D-005 | ≤2026-11-25 | **Async order model: `pending` → `completed`/`failed`, with the UI polling** | Matches the Kafka write flow. `POLL_INTERVAL_MS` is configurable. |
| D-006 | ≤2026-11-25 | **Money as integer Pips (1 Griffin = 12 Shards = 240 Pips)** | Exact arithmetic. The server computes prices; the browser never sends them. |
| D-007 | ≤2026-11-25 | **Strict CSP, no inline scripts, self-hosted fonts** | Security baseline. Inline `style` attributes are still allowed. |
| D-008 | ≤2026-11-25 | **Content-hashed static URLs (`asset()`) with 1-year caching** | Fast repeat visits. A replaced file gets a new URL automatically. |
| D-009 | 2026-11-25 | **Original brand "Marvellous Mischief Co." with no third-party franchise names or elements** | Needed for commercial use. All names, products, currency, secret words and routes are original. Residual risk: R-03. |
| D-010 | 2026-11-25 | **Product images are cut-outs on 1600×1600 transparent canvases, base at 88%, with 640 px copies**; multi-state products use extra frames or layers | Consistent staging on the darkened display niche. CSS animations rely on these positions. |
| D-011 | 2026-11-25 | **Basket stored in `localStorage`; checkout calls `buy()` once per line, in sequence** | No API contract change. Trade-off: non-atomic (R-07); fix planned as P1-19 (D-020). |
| D-012 | 2026-11-25 | **The Ledger (`/orders`) is reachable only from the home-page button**, not from the menu or toasts | Owner's product decision. |
| D-013 | 2026-11-25 | **`ROADMAP.md` is the single source of truth for tasks; documentation updated after every task** | Rules recorded in `CLAUDE.md`. |
| D-017 | 2026-11-25 | **Dev-only test dependencies: pytest and Playwright** (`client/requirements-dev.txt`) | The site itself still needs only Flask. Browser tests use Playwright's bundled Chromium. |
| D-018 | 2026-11-25 | **The owner writes the backend (API, Kafka producer and consumer, MongoDB access)** as part of the course | Roadmap tasks P1-02, P1-05, P1-09 and P1-10 are owner-implemented. The contract in API.md stays the interface between the two halves. |
| D-019 | 2026-11-25 | **Git from now on; PNG masters stay outside git** (`optional-concepts/source-png/`, git-ignored) | Keeps the repository light (WebP only, 11 MB). The masters must still be handed over to a buyer (P6-10). |
| D-020 | 2026-11-25 | **Fix the non-atomic checkout (R-07)**: one order with lines per basket | Planned as P1-19. Changes the API contract, so it is agreed with the backend first. |
| D-021 | 2026-11-25 | **Keep the easter eggs as they are** (secret chart and its phrase, Latin secret words, family clock) | Owner's decision. They use only original names and texts. The residual similarity in mechanics stays part of risk R-03, for the lawyer's review before listing (P5-13). |

## Deferred

| ID | Question | Decision |
|---|---|---|
| D-014 | Where do the catalog and prices live for the backend? | **Deferred to the admin panel (P4-03).** Options for that point: a shared data file read by client and API, or a MongoDB `products` collection managed from the admin panel. |

## Proposed (need the owner's decision)

| ID | Question | Options | Recommendation |
|---|---|---|---|
| D-015 | Who writes the `pending` row? (The owner decides while writing the backend.) | (a) the API inserts `pending` and then produces; the consumer updates. (b) The API only produces; the consumer inserts. | **(b)** keeps writes purely asynchronous, as the course requires, with no dual-write. The UI already tracks the id returned by the 202. |
| D-016 | Remote git hosting | GitHub private / Azure Repos | Decide with P2-04 (Azure DevOps Pipelines can use either). |
