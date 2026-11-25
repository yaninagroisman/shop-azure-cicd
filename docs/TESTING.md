# Testing

## Current state

**Client test suite: `client/tests/`, 64 tests, all passing on 2026-11-25 (21.7 s).** Backend tests do not exist yet; the owner is writing the backend (P1-12 stays `IN_PROGRESS`).

```bash
cd client
pip install -r requirements-dev.txt     # pytest, Playwright (dev only)
playwright install chromium             # once
pytest                                  # everything
pytest -m "not browser"                 # fast tests only, no browser needed
```

If Playwright or Chromium is missing, the browser tests are **skipped**. They do not fail, so check the summary line.

| File | Covers |
|---|---|
| `test_money.py` | coinage ratios, `split_pips` ↔ `to_pips` round trip |
| `test_catalog.py` | 13 unique slugs, complete fields, integer prices, valid categories, every 1600 px and 640 px image (including the `--box/--violet/--pink`, `--extended` and `--open` frames) exists, related products |
| `test_pages.py` | every page (including all 13 product pages) returns 200 with the brand; unknown product returns 404; security headers; no inline `<script>`; `API_MODE` reaches the page; versioned static URLs |
| `test_browser.py` | headless Chromium against a live server in mock mode: no JS errors and no broken images on 5 pages (under the strict CSP); no horizontal scroll at 390 px on 4 pages; basket add → quantity → remove → checkout → delivered → Ledger entry; door game opens, an item is caught, the game closes and the door shuts; catalogue search, empty state, reset, shelf filter and price sort |

The interaction tests open their page with `bypass_csp=True`, because Playwright's `wait_for_function` evaluates strings and the shop's CSP forbids that. The error checks use pages with the normal CSP.

The older ad-hoc check scripts are kept in `optional-concepts/tools/checks/` for reference.

## Manual checks run on 2026-11-25 (initial audit, before the suite existed)

The checks ran against the preview container (`API_MODE=mock`, port 8000) unless noted.

| Check | Result |
|---|---|
| HTTP status: `/`, `/catalogue`, `/orders`, `/product/pocket-fluffs`, `/product/bumble-fizzies` | 200 |
| Unknown product `/product/nope` | 404 |
| `/api/purchases` | 404, because no backend exists |
| Security headers present (CSP, nosniff, Referrer-Policy) | ✓ |
| `eggs.py`: broken images, mobile menu, mobile horizontal overflow (4 pages), Tuckbox tap, reduced motion, JS errors | 0 broken images, menu opens, no overflow, reduced motion OK, **0 JS errors** |
| `basket_test.py`: add 3 lines → total 9 G 5 S 6 P → remove 1 → checkout → accepted → delivered → 2 Ledger entries | ✓, 0 JS errors |
| `gametest.py`: desktop and mobile rounds, scoring, result, best score, close and restore | ✓, 0 JS errors on both |
| `navcheck.py`: page transitions and back navigation | ✓, 0 errors |
| `API_MODE=http` (temporary container on port 8001) | Page renders with `data-api-mode="http"`; `POST /api/buy` → 404 |
| Kafka: `kafka-topics --list` | `purchases` exists; consumer groups: `shop-consumers` and one console consumer |
| MongoDB: `wizard_shop.purchases` | 1 test document (schema mismatch, see DATABASE.md) |

Not run today:

- every product's demo button;
- the full easter-egg set.

Catalogue search, filter and sort are now covered by the suite. The other two passed in earlier sessions, as recorded in `REPORT.md` §0.8 and §9.

## Still to add (P1-12)

| Layer | Tool | Covers |
|---|---|---|
| API unit | pytest | validation, server-side pricing, error JSON |
| Consumer | pytest with a fake Kafka message | idempotent upsert, failed path |
| Integration | `docker compose` + pytest | `POST` → Kafka → consumer → `GET` shows `completed` |
| Browser, http mode | Playwright | the same purchase flow against the real API |

Every test must run with one command and in CI (P2-06).
