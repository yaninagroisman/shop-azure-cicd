# API

> **Implementation status (2026-11-25): NOT IMPLEMENTED.** `api/app.py` is empty. Both endpoints return 404 when the client runs with `API_MODE=http`.
>
> The contract below is **authoritative**. It is what the frontend already calls (`client/app/static/js/api.js`) and what the in-browser mock imitates (`mock-api.js`). Changing its shape is a breaking change that needs an entry in [DECISIONS.md](DECISIONS.md).

## Conventions

- Same origin as the pages: the browser calls relative `/api/...` URLs. No CORS is needed.
- JSON in, JSON out. Errors are `{"error": "<human-readable text>"}` with a non-2xx status. The UI shows `error` directly to the shopper.
- Money is **integer Pips**: 1 Griffin = 12 Shards = 240 Pips (`client/app/money.py`).
- Timestamps are ISO 8601 in UTC.

## `POST /api/buy`

Places one order line.

Request:

```json
{ "product_slug": "pocket-fluffs", "quantity": 2 }
```

| Field | Rule |
|---|---|
| `product_slug` | must be one of the catalog slugs (13 today, see `catalog.py`) |
| `quantity` | integer, 1–10 (the basket's `MAX_QTY`) |

The server must compute `unit_price` and `total_price` from its own catalog. It must never trust prices from the browser, and the browser does not send any.

Response: **202 Accepted**:

```json
{ "purchase": { "id": "…", "status": "pending", "...": "see Purchase" } }
```

A bare `Purchase` object is also accepted by the client.

Errors:

| Status | When |
|---|---|
| 400 | unknown slug, bad quantity, malformed JSON |
| 503 | Kafka unavailable |

## `GET /api/purchases`

Response: **200**:

```json
{ "purchases": [ Purchase, ... ] }
```

Purchases are listed newest first. A bare array is also accepted by the client. The UI polls this endpoint every `POLL_INTERVAL_MS` (default 1500 ms) while any order is `pending`.

## `Purchase`

```jsonc
{
  "id": "9f1c2a…",                 // string, unique
  "product_slug": "pocket-fluffs",
  "product_name": "Pocket Fluffs",
  "quantity": 2,
  "unit_price": 300,               // Pips
  "total_price": 600,              // Pips
  "status": "pending",             // "pending" | "completed" | "failed"
  "failure_reason": null,          // string when failed, else null
  "created_at": "2026-11-25T10:00:00Z",
  "updated_at": "2026-11-25T10:00:04Z"
}
```

## Known gaps

- **No authentication.** Every visitor sees every purchase, which is acceptable only for the demo (see P4-15).
- **One order per basket line.** A basket of 3 lines makes 3 requests in sequence. If one fails midway, the order is only partly placed (risk R-07; fix planned as P1-19).
- **No health endpoint.** `GET /api/health` is proposed for P1-13 and P1-14.
