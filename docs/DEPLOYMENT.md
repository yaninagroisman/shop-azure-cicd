# Deployment

> **Current state: local development only.** There is no reproducible full-stack deployment yet (P1-15), and nothing runs in the cloud (Phase 2).

## 1. Frontend only (works today)

```bash
cd client
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
flask --app wsgi run --debug                 # API_MODE=mock (default): orders simulated in the browser
API_MODE=http flask --app wsgi run           # calls /api/*; shows error states until the API exists
```

Open <http://127.0.0.1:5000>. The WSGI entry point is `wsgi:app`.

### Preview container used during development

The container is not part of the repo. It mounts `client/` read-only and runs the Flask dev server:

```bash
docker run -d --name mischief-preview -p 8000:8000 \
  -e API_MODE=mock -e PYTHONDONTWRITEBYTECODE=1 \
  -v "$PWD/client:/app:ro" -w /app python:3.13-slim \
  sh -c "pip install -q -r requirements.txt && flask --app wsgi run --host 0.0.0.0 --port 8000"
docker restart mischief-preview   # after editing files
```

## 2. Infrastructure containers (present, not wired)

```bash
docker compose up -d     # starts mongodb (mongo:8.0) and kafka (apache/kafka:4.1.2, KRaft single node)
```

No ports are published, so only containers on the compose network can reach them. The client, API and consumer are **not** services in `compose.yaml` yet.

## Environment variables

| Variable | Used by | Default | Meaning |
|---|---|---|---|
| `API_MODE` | client | `mock` | `mock` = in-browser fake backend, `http` = same-origin `/api/*` |
| `POLL_INTERVAL_MS` | client | `1500` | how often the UI re-reads pending orders |
| `MONGO_URI` | api | `mongodb://mongodb:27017` | MongoDB connection |

## 3. Target local deployment (P1-13 to P1-15, proposed)

The target is one `docker compose up` that starts these services:

- `client`: Gunicorn, `API_MODE=http`, proxying `/api/*`;
- `api`;
- `consumer`;
- `kafka`;
- `mongodb`.

Each service has a health check, and `depends_on: condition: service_healthy` orders the start-up. Success criterion: a purchase completes on a clean machine with the README alone.

## 4. Azure (Phase 2)

Services are not chosen yet (P2-01). This section is filled in by P2-16.
