# Database (MongoDB)

## Observed state (2026-11-25)

| Item | Value |
|---|---|
| Server | `mongo:8.0` container from `compose.yaml`, volume `mongo_data`, **no port published**, **no authentication** |
| Connection | `MONGO_URI` env var, default `mongodb://mongodb:27017` (`api/database.py`) |
| Database | `wizard_shop` |
| Collection | `purchases`: 1 document (a manual test) |
| Indexes | not checked; none are created by the code |
| Code | `api/database.py`: `save_purchase(p)` → `insert_one`; `get_all_purchases()` → `find({}, {"_id": 0})` with no sort |

The test document **does not match the API contract**:

```jsonc
{ "purchase_id": "test-001",      // contract: "id"
  "product_slug": "<pre-rebrand slug>",   // no longer exists in the catalog
  "product_name": "<pre-rebrand name>",
  "quantity": 2, "unit_price": 493, "total_price": 986,   // old coinage (1 = 493), contract: Pips
  "status": "completed",
  "created_at": ISODate(...) }    // no failure_reason, no updated_at
```

Delete it, or migrate it, before integration testing (P1-09).

## Target schema (proposed)

The collection is `purchases`, and each document mirrors the API `Purchase` ([API.md](API.md)):

| Field | Type | Notes |
|---|---|---|
| `_id` | ObjectId | internal, never returned |
| `id` | string | **unique index**; it is also the idempotency key for the consumer |
| `product_slug` | string | |
| `product_name` | string | stored as it was at purchase time |
| `quantity` | int | 1–10 |
| `unit_price`, `total_price` | int | Pips |
| `status` | string | `pending` \| `completed` \| `failed` |
| `failure_reason` | string \| null | |
| `created_at`, `updated_at` | date | serialised as ISO 8601 by the API |

Indexes:

- `{ id: 1 }`, unique.
- `{ created_at: -1 }`, for the Ledger's newest-first listing.

Later (Phase 4):

- `user_id` on purchases.
- Collections `products`, `categories`, `users`, `game_events`, `achievements`, `settings`.

These depend on D-014 (where the catalog lives).

## Rename to consider

`wizard_shop` is harmless, but a neutral name (`shop`) would suit the white-label goal. It should come from config (`MONGO_DB`).
