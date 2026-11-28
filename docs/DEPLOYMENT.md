# Deployment

> **Current state (2026-11-28):**
> - **Local:** the full stack runs with one `docker compose up`.
> - **Azure:** all Terraform, GitOps manifests and the CI pipeline are written. The bootstrap stack is applied. The dev environment was applied once and could not finish because of the 4 vCPU quota (see §2.8); it is destroyed now.

## 1. Local full stack (Docker Compose)

Requirements: Docker with Compose v2.

```bash
docker compose up -d --build
docker compose ps            # wait until every service is healthy; kafka-init exits with 0
```

Open <http://localhost:8080>. The shop runs with `API_MODE=http`: a purchase goes client → Kafka → consumer → MongoDB, and the Ledger (`/orders`) reads it back through the api.

| Service | Image | Role |
|---|---|---|
| `mongodb` | `mongo:8.0` | database `wizard_shop`, volume `mongo_data` |
| `kafka` | `apache/kafka:4.1.2` | single KRaft node, PLAINTEXT, auto topic creation off |
| `kafka-init` | `apache/kafka:4.1.2` | one-shot: creates `purchases` (3 partitions) and `purchases.dlq` |
| `api` | `shop-api:1.0` (built from `api/`) | `GET /purchases`, `/healthz`, `/readyz` |
| `consumer` | `shop-api:1.0`, `python consumer.py` | Kafka → MongoDB |
| `client` | `shop-client:1.0` (built from `client/`) | shop front, `POST /api/buy` producer, port **8080** |

Kafka and MongoDB publish no host ports.

```bash
docker compose logs -f consumer   # watch orders being stored
docker compose down               # stop (data volumes kept)
docker compose down -v            # stop and delete the data
```

### Frontend only (mock mode)

```bash
cd client
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
flask --app wsgi run --debug      # API_MODE=mock (default): orders are simulated in the browser
```

### Static preview on Netlify (mock mode)

```bash
python3 -m venv .venv && .venv/bin/pip install -r client/requirements.txt
.venv/bin/python optional-concepts/tools/netlify/freeze.py   # writes dist/ (git-ignored)
```

Drag `dist/` onto <https://app.netlify.com/drop>. The preview always runs in mock mode, and the link is public.

### Environment variables

| Variable | Used by | Default | Meaning |
|---|---|---|---|
| `API_MODE` | client | `mock` | `mock` = in-browser fake backend, `http` = real `/api/*` |
| `POLL_INTERVAL_MS` | client | `1500` | how often the UI re-reads pending orders |
| `API_URL` | client | `http://api:5000` | where `GET /api/purchases` is proxied |
| `KAFKA_SERVER` | client, consumer | `kafka:9092` | bootstrap servers |
| `KAFKA_TOPIC`, `KAFKA_DLQ_TOPIC`, `KAFKA_GROUP_ID` | client, consumer | `purchases`, `purchases.dlq`, `purchase-consumers` | |
| `KAFKA_DELIVERY_TIMEOUT_SECONDS` | client | `5` | `POST /api/buy` answers 503 after this |
| `KAFKA_SECURITY_PROTOCOL` | client, consumer | `PLAINTEXT` | `SASL_SSL` on AKS |
| `KAFKA_SASL_MECHANISM`, `KAFKA_SASL_USERNAME`, `KAFKA_SASL_PASSWORD` | client, consumer | `SCRAM-SHA-512`, —, — | required when the protocol is `SASL_*` |
| `KAFKA_SSL_CA_LOCATION` | client, consumer | — | CA file for TLS (Strimzi cluster CA on AKS) |
| `MONGO_URI` | api, consumer | `mongodb://mongodb:27017` | MongoDB connection |
| `MONGO_TIMEOUT_MS` | api, consumer | `3000` | fail fast instead of pymongo's 30 s |
| `PURCHASES_LIMIT` | api | `100` | newest purchases returned by `GET /purchases` |

## 2. Azure (dev environment)

Architecture: [ARCHITECTURE.md](ARCHITECTURE.md) §5. Decisions: [DECISIONS.md](DECISIONS.md) (AD-xx).

### 2.1 Prerequisites (once)

- Azure subscription where you are Owner; Azure DevOps organization connected to the same Entra ID tenant.
- Free Microsoft-hosted parallel job requested for the organization (<https://aka.ms/azpipelines-parallelism-request>, takes a few days).
- Tools: Terraform ≥ 1.11, Azure CLI, `jq`, `kubectl`, `kubelogin` (`az aks install-cli` installs both).
- A GitHub fork or copy of both repositories: this one and [`gitops-shop`](https://github.com/yaninagroisman/gitops-shop) (must be public, AD-28).

### 2.2 Bootstrap (once per subscription)

Creates the state storage, the pipeline identities, the Azure DevOps project with its service connections, and the budget. Full steps: [terraform/bootstrap/README.md](../terraform/bootstrap/README.md).

```bash
az login && az account set --subscription <id>
cd terraform/bootstrap
cp terraform.tfvars.example terraform.tfvars      # real values, git-ignored
terraform init && terraform plan -out=bootstrap.tfplan && terraform apply bootstrap.tfplan
terraform output -raw backend_config > backend.hcl
cp backend.tf.example backend.tf
terraform init -migrate-state -backend-config=backend.hcl
```

### 2.3 Dev environment (one apply)

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars      # your IP (/32), Entra object ID, e-mail, GitOps repo URL
cp backend.hcl.example backend.hcl                # values from the bootstrap output
terraform init -backend-config=backend.hcl
terraform plan -out=dev.tfplan
terraform apply dev.tfplan                        # ~15–25 minutes
```

Use your public **IPv4** address in `api_server_authorized_ip_ranges` (`curl -4 https://ifconfig.me`); AKS accepts IPv4 only.

The apply creates the infrastructure, installs Argo CD and applies the root Application. Argo CD then installs everything from `gitops-shop` (cert-manager, Strimzi, Kyverno, Gateway, Kafka, MongoDB, the shop) in a few minutes. Until CI has pushed the first signed images (§2.5), the client, api and consumer pods cannot start: this is expected.

### 2.4 Azure DevOps pipeline (once, manual)

These steps cannot be done by Terraform; they are also listed in the header of `.azure-pipelines/ci.yml`.

1. **GitHub App:** Azure DevOps → Pipelines → New pipeline → GitHub → install *Azure Pipelines* on this repository only → *Existing Azure Pipelines YAML file* → `/.azure-pipelines/ci.yml`.
2. **Deploy key for `gitops-shop`:**
   ```bash
   ssh-keygen -t ed25519 -N "" -C shop-ci -f gitops-shop-deploy-key
   ```
   - GitHub `gitops-shop` → Settings → Deploy keys → add the `.pub` with **Allow write access**.
   - Azure DevOps → Pipelines → Library → Secure files → upload `gitops-shop-deploy-key` (private part) and allow the pipeline to use it.
   - Pipeline variable `gitopsDeployKeyPublic` = contents of the `.pub`.
   - Delete both local files.

### 2.5 First release

Merge to `main` (or re-run the pipeline on `main`). The pipeline:

1. **Validate:** Gitleaks, ruff, hadolint, pytest for api and client (browser tests included).
2. **Build:** `docker build`, Trivy (fails on fixable CRITICAL/HIGH), push to ACR, Cosign signature with the Key Vault key.
3. **Deploy:** sets the new tag (first 12 characters of the commit SHA) in `gitops-shop/shop/kustomization.yaml` and pushes.

Argo CD picks up the commit; Kyverno admits only images signed with the project key.

### 2.6 Access and checks

```bash
cd terraform/environments/dev
$(terraform output -raw kubeconfig_command)        # Entra ID credentials for kubectl
terraform output -raw argocd_ui_command            # prints the admin password, then port-forwards https://localhost:8080
terraform output gateway_fqdn                       # https://<fqdn>/ is the shop
kubectl get applications -n argocd                  # every Application Synced / Healthy
kubectl get pods -A
```

Checks to run after the first full deployment (not yet done):

- every Argo CD Application is `Synced` and `Healthy`;
- the Gateway Service got the Terraform public IP; the Let's Encrypt certificate `shop-tls` is `Ready`;
- a purchase on `https://<fqdn>/` reaches `completed` in the Ledger;
- an unsigned image in `shop` is denied by Kyverno;
- KEDA scales the consumer when lag grows;
- the pod labels assumed by the NetworkPolicies match (Strimzi broker role, Gateway pod, KEDA operator).

### 2.7 Destroy

```bash
cd terraform/environments/dev
terraform destroy                                    # removes the whole environment (AD-31)
```

Never destroy `bootstrap/` during the project: it holds the state (`prevent_destroy` and a delete lock refuse anyway).

### 2.8 Known blocker: 4 vCPU quota

On the Free Trial subscription (4 vCPU per region) the dev cluster has 3.8 allocatable vCPU, and the AKS add-ons plus the stack request about 5.9 vCPU. The first apply therefore stopped at the root Application (its Run Command pod was `Unschedulable`). Options: reduce the add-ons to fit 4 vCPU, or move to Pay-As-You-Go with an 8 vCPU quota. Details: [DECISIONS.md](DECISIONS.md), "Capacity finding".

### 2.9 Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `kubectl` times out | your public IP changed | update `api_server_authorized_ip_ranges`, apply again |
| root Application step fails with `reason: Unschedulable …` | no free CPU on the nodes | see §2.8 |
| root Application step fails right after the first apply | role assignment not yet propagated, or the Argo CD extension still starting | the script retries 8 times; otherwise run `terraform apply` again |
| `ImagePullBackOff` / Kyverno denies a shop pod | no signed image yet | run the CI pipeline on `main` |
| CI push step stops with a message about the resource group | dev is not applied | apply dev first |

### 2.10 Cost (rough, while dev is running)

| Item | Approximate cost |
|---|---|
| 2 × D2ads_v5 nodes | ~$0.20/hour |
| Standard load balancer + public IPs | a few cents per hour |
| Managed disks (Kafka, MongoDB) | cents per day |
| Log Analytics (capped 0.25 GB/day) | ≤ ~$0.70/day; the first 5 GB/month are free |
| Managed Prometheus, ACR Basic, Key Vault | a few dollars per month |

AKS Free tier has no control-plane charge. The budget in bootstrap e-mails at 25/50/80 % of $100 and at 100 % forecast. Destroy dev between work sessions.
