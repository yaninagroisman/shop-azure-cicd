# Testing

## Current state (2026-11-28)

| Suite | Tests | Result |
|---|---:|---|
| `api/tests/` | 36 | all pass (0.2 s) |
| `client/tests/` | 75 | 63 pass; the 12 Playwright browser tests are skipped when Chromium is not installed (they run in CI) |

```bash
# API and consumer
cd api
pip install -r requirements-dev.txt
pytest

# Shop front and producer
cd client
pip install -r requirements-dev.txt
playwright install chromium             # once, for the browser tests
pytest                                  # everything
pytest -m "not browser"                 # fast tests only
```

If Playwright or Chromium is missing, the browser tests are **skipped**, not failed: check the summary line.

The unit tests need neither Kafka nor MongoDB: Kafka producers and consumers and the MongoDB collection are replaced by fakes.

## What the tests cover

### `api/tests/`

| File | Covers |
|---|---|
| `test_app.py` | `GET /purchases` returns the list; MongoDB down → 503 JSON; `/healthz` does not touch MongoDB; `/readyz` up and down; the listing limit |
| `test_consumer.py` | parsing valid and poison messages; valid order stored as `completed`; business-rule violation stored as `failed` with a reason; duplicate delivery treated as done; poison message and MongoDB-rejected document go to the DLQ and are not saved; MongoDB down and DLQ delivery error/timeout are transient (retried); exponential capped backoff; heartbeat file |
| `test_kafka_config.py` | PLAINTEXT default; SASL/SCRAM + TLS settings from env; missing username or password and unknown protocol are rejected |

### `client/tests/`

| File | Covers |
|---|---|
| `test_money.py` | coinage ratios, `split_pips` ↔ `to_pips` round trip |
| `test_catalog.py` | 13 unique slugs, complete fields, integer prices, valid categories, every 1600 px and 640 px image exists, related products |
| `test_pages.py` | every page (all 13 product pages) returns 200; unknown product 404; security headers; no inline `<script>`; `API_MODE` reaches the page; versioned static URLs |
| `test_producer.py` | the message is keyed by `purchase_id`; delivery error and missing delivery report raise; `/healthz` |
| `test_kafka_config.py` | same cases as in `api/` (the module is duplicated in both images) |
| `test_browser.py` | headless Chromium against a live server in mock mode: no JS errors or broken images on 5 pages under the strict CSP; no horizontal scroll at 390 px; basket → checkout → delivered → Ledger; the door game; catalogue search, filter and sort |

The interaction tests open their page with `bypass_csp=True`, because Playwright's `wait_for_function` evaluates strings and the shop's CSP forbids that. The error checks use pages with the normal CSP.

## Static checks

| Check | Command | Runs in CI |
|---|---|---|
| Python lint | `ruff check .` (version pinned in `ruff.toml`) | yes |
| Dockerfile lint | `hadolint api/Dockerfile client/Dockerfile` | yes |
| Secret scan | `gitleaks` over the change (full history scanned 2026-11-28: 0 findings) | yes |
| Image vulnerabilities | Trivy, fails on fixable CRITICAL/HIGH | yes |
| Terraform | `terraform fmt -check`, `terraform validate` in both stacks | not yet (no Terraform pipeline) |
| GitOps manifests | `kustomize build`, kubeconform (Kubernetes 1.33 + CRD schemas of Strimzi, Kyverno, cert-manager, Gateway API, CSI, KEDA, Cilium), `helm lint apps/` | not yet (run by hand on 2026-11-28) |

## CI

`.azure-pipelines/ci.yml` runs on every pull request and on `main`: Gitleaks, ruff, hadolint, pytest for api and client (Chromium installed, so the browser tests run), then image builds and Trivy. A failing test fails the pipeline. The pipeline has not yet run in Azure DevOps (it needs the one-time setup in [DEPLOYMENT.md](DEPLOYMENT.md) §2.4).

## Not yet tested

| Layer | How | Status |
|---|---|---|
| End-to-end in compose: purchase → Kafka → consumer → Ledger | `docker compose up`, then a purchase in the browser | the stack was built to do this; no run is recorded in the repository |
| End-to-end on AKS | the checks in [DEPLOYMENT.md](DEPLOYMENT.md) §2.6 | blocked by the 4 vCPU quota |
| Browser tests in `http` mode against the real API | Playwright + compose | not written |
| Integration test through a real Kafka broker | testcontainers or compose in CI | not written |
