# API

> **Implementation status (2026-11-28): implemented.**
> - `POST /api/buy` is served by the **client server** (`client/app/routes.py`): it validates and prices the line and publishes it to Kafka (`client/producer.py`).
> - `GET /api/purchases` is served by the client server as a proxy to the **api** service's `GET /purchases` (`api/app.py`), which reads MongoDB.
>
> The contract below is what the frontend calls (`client/app/static/js/api.js`) and what the in-browser mock imitates (`mock-api.js`). Changing its shape is a breaking change that needs an entry in [DECISIONS.md](DECISIONS.md).

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

| Status | Body | When |
|---|---|---|
| 400 | `{"error": "Invalid JSON"}` / `"Invalid product"` / `"Invalid quantity"` | malformed JSON, slug not a string, quantity not an integer 1–10 |
| 404 | `{"error": "Product not found"}` | unknown slug |
| 503 | `{"error": "Purchase service unavailable"}` | Kafka did not acknowledge the message within 5 s |

The 202 means Kafka has acknowledged the message (`acks=all`). The order is stored later by the consumer, as `completed` or `failed`.

## `GET /api/purchases`

Response: **200**:

```json
{ "purchases": [ Purchase, ... ] }
```

Purchases are listed newest first, at most 100 (`PURCHASES_LIMIT`). A bare array is also accepted by the client. If the api or MongoDB is unavailable the answer is 503 with `{"error": …}`. The UI polls this endpoint every `POLL_INTERVAL_MS` (default 1500 ms) while any order is `pending`.

## `Purchase`

```jsonc
{
  "id": "9f1c2a…",                 // string (UUID4), unique
  "purchase_id": "9f1c2a…",        // same value; the Kafka key and the unique index in MongoDB
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
- **No rate limiting** on `POST /api/buy` (open question in DECISIONS.md).

## Internal endpoints (not public)

| Service | Endpoint | Purpose |
|---|---|---|
| api | `GET /purchases` | the listing behind `GET /api/purchases` |
| api | `GET /healthz` | liveness: the process is up (does not touch MongoDB) |
| api | `GET /readyz` | readiness: 503 while MongoDB does not answer |
| client | `GET /healthz` | liveness and readiness of the shop front |
