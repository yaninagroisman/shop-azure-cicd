# Database (MongoDB)

## Current schema (implemented)

| Item | Value |
|---|---|
| Server | local: `mongo:8.0` container from `compose.yaml` (volume `mongo_data`, no port published, no authentication). AKS: `mongo:8.0` StatefulSet, replica set `rs0` with one member, authentication on (see below) |
| Connection | `MONGO_URI` env var, default `mongodb://mongodb:27017` (`api/database.py`) |
| Database | `wizard_shop` |
| Collection | `purchases` |
| Writer | the Kafka consumer (`api/consumer.py`): one `insert_one` per order |
| Reader | the api (`GET /purchases`): `find({}, {"_id": 0})`, newest first, limit 100 |

Each document mirrors the API `Purchase` ([API.md](API.md)):

| Field | Type | Notes |
|---|---|---|
| `_id` | ObjectId | internal, never returned |
| `id`, `purchase_id` | string (UUID4) | the same value; `purchase_id` has a **unique index** and is the idempotency key |
| `product_slug` | string | |
| `product_name` | string | as it was at purchase time |
| `quantity` | int | 1–10 |
| `unit_price`, `total_price` | int | Pips (1 Griffin = 12 Shards = 240 Pips) |
| `status` | string | `completed` or `failed` (`pending` exists only in the browser, D-015) |
| `failure_reason` | string or null | set when `failed` |
| `created_at`, `updated_at` | string | ISO 8601 UTC, set by the client server when the order is placed |

Indexes (created by `ensure_indexes()` when the consumer starts):

- `{ purchase_id: 1 }`, unique: a redelivered Kafka message raises `DuplicateKeyError` and is treated as already stored.
- `{ created_at: -1 }`: the Ledger's newest-first listing.

The compose project is named `shop`, so its volume is `shop_mongo_data`. The old pre-rebrand test document lived in a volume of the previous project name and is not used any more.

## On AKS (written, not yet deployed)

`gitops-shop/platform/mongodb/`:

- StatefulSet `mongodb` in namespace `shop`, `mongo:8.0`, non-root (UID 999), 1 member of replica set `rs0`, keyfile on the data volume, WiredTiger cache 0.25 GB.
- Passwords from Key Vault through the CSI driver (files under `/mnt/secrets`); the root password is used only by the init scripts.
- An init script creates the application user `shop-app` with `readWrite` on `wizard_shop`; a PostSync Job runs `rs.initiate()`.
- api and consumer connect with `mongodb://shop-app:$(MONGO_PASSWORD)@mongodb-0.mongodb.shop.svc.cluster.local:27017/wizard_shop?replicaSet=rs0&authSource=wizard_shop`.
- No backup (AD-25): the data lives only as long as the environment.

## Later (Phase 4)

- `user_id` on purchases.
- Collections `products`, `categories`, `users`, `game_events`, `achievements`, `settings` (depend on D-014, where the catalog lives).
- A neutral database name (`shop`) from config (`MONGO_DB`) would suit the white-label goal.
