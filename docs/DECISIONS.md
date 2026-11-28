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
| D-013 | 2026-11-25 | **`ROADMAP.md` is the single source of truth for tasks; documentation updated after every task** | Docs are updated together with each task. |
| D-017 | 2026-11-25 | **Dev-only test dependencies: pytest and Playwright** (`client/requirements-dev.txt`) | The site itself still needs only Flask. Browser tests use Playwright's bundled Chromium. |
| D-018 | 2026-11-25 | **The owner writes the backend (API, Kafka producer and consumer, MongoDB access)** as part of the course | Roadmap tasks P1-02, P1-05, P1-09 and P1-10 are owner-implemented. The contract in API.md stays the interface between the two halves. |
| D-019 | 2026-11-25 | **Git from now on; PNG masters stay outside git** (`optional-concepts/source-png/`, git-ignored) | Keeps the repository light (WebP only, 11 MB). The masters must still be handed over to a buyer (P6-10). |
| D-020 | 2026-11-25 | **Fix the non-atomic checkout (R-07)**: one order with lines per basket | Planned as P1-19. Changes the API contract, so it is agreed with the backend first. |
| D-015 | 2026-11-27 | **The consumer writes the order; the producer only publishes** (option b) | `POST /api/buy` (client server) prices the line, publishes it to Kafka and answers 202 with a `pending` purchase. The consumer inserts the document as `completed` or `failed`. No dual write; `GET /api/purchases` may miss an order for a moment, and the UI copes because it tracks the id from the 202. |
| D-016 | 2026-11-26 | **GitHub, public repositories** (see AD-28) | Application repository plus a separate GitOps repository (AD-40). Azure Pipelines reads GitHub through the Azure Pipelines GitHub App. |
| D-021 | 2026-11-25 | **Keep the easter eggs as they are** (secret chart and its phrase, Latin secret words, family clock) | Owner's decision. They use only original names and texts. The residual similarity in mechanics stays part of risk R-03, for the lawyer's review before listing (P5-13). |

## Deferred

| ID | Question | Decision |
|---|---|---|
| D-014 | Where do the catalog and prices live for the backend? | **Deferred to the admin panel (P4-03).** Options for that point: a shared data file read by client and API, or a MongoDB `products` collection managed from the admin panel. |

## Azure and DevOps decisions (AD-xx)

Made by the owner, acting as cloud architect, in the design sessions of 2026-11-26 to 2026-11-28. Missing numbers were withdrawn or merged during those sessions. "dev only" means: only a development environment is built; a production-like environment exists on paper (see [ARCHITECTURE.md](ARCHITECTURE.md) §6).

### Subscription, region, layout

| ID | Decision | Reason and consequences |
|---|---|---|
| AD-01 | **Region Sweden Central** | Quota and SKUs available on the subscription; all resources in one region. |
| AD-02 | **Azure Free Trial, dev environment only** | $200 credit for 30 days, 4 vCPU per region, no quota increase. The spending limit is the cost guard. See the capacity finding below. |
| AD-04 | **Naming: CAF pattern, prefix `shop`, random suffix** | `rg-shop-dev-swc`, `acrshopdevswc<suffix>`. The suffix lets an environment be destroyed and re-created at once (soft-deleted names do not collide). |
| AD-31 | **One root stack `terraform/environments/dev`: one apply creates everything, one destroy removes everything** | Nothing survives a destroy: no data, no shared layer. Simple to reason about and cheap (nothing runs between work sessions). |
| AD-33 | **Separate one-time `terraform/bootstrap` stack for remote state** | The state storage must exist before, and survive, the main stack. |
| AD-31a | **Bootstrap also holds the pipeline identities and the Azure DevOps project** (service connections, environments, approvals) | No pipeline can change its own permissions or approvals. |
| AD-34 | **Resource providers registered explicitly in bootstrap** | No surprise registration during the first apply. |
| AD-35 | **Budget $100/month with e-mail alerts at 25/50/80 % actual and 100 % forecast** | In bootstrap, so it exists even when dev is destroyed. |

### Kubernetes platform

| ID | Decision | Reason and consequences |
|---|---|---|
| AD-05/06 | **AKS Free tier, one node pool, 2 × Standard_D2ads_v5, ephemeral OS disk, Azure Linux 3, Kubernetes 1.36, automatic upgrades off** | Fits the 4 vCPU quota (but see the capacity finding). Immutable infrastructure: upgrade = destroy + apply, because the quota leaves no room for a surge node. |
| AD-08 | **Azure CNI Overlay + Cilium (no ACNS); KEDA add-on, consumer 1 → 3 replicas** | Cilium enforces NetworkPolicies; KEDA scales the consumer on Kafka lag. |
| AD-09 | **Public API server + Entra ID + Azure RBAC, local accounts off, API server IP allow-list** | A private cluster needs a jumpbox or VPN that the quota cannot hold. |
| AD-10 | **Outbound through the Standard Load Balancer** | No NAT gateway cost. |
| AD-11 | **AKS App Routing Gateway API (Istio-based)** | Managed Gateway API implementation; standard `Gateway`/`HTTPRoute` resources. |
| AD-12 | **No custom domain: Azure DNS label (`*.cloudapp.azure.com`) + cert-manager + Let's Encrypt HTTP-01** | Free HTTPS without buying a domain. |
| AD-18 | **Pod Security Admission `restricted` + Kyverno** instead of the Azure Policy add-on | Lighter, and policies live in Git. |
| AD-32 | **Argo CD installed by Terraform as the AKS cluster extension `Microsoft.ArgoCD`** (preview, non-HA) | The Terraform Helm provider was rejected: the API server allow-list blocks Microsoft-hosted agents. |
| AD-37 | **Gateway public IP created by Terraform in the main resource group** (Standard, static, DNS label); the AKS control-plane identity gets Network Contributor on that IP only | The address and DNS name are known before the cluster exists and survive Gateway re-creation within one environment. |
| AD-38 | **Argo CD UI only through `kubectl port-forward`** | Not exposed to the Internet. |
| AD-39 | **Root app-of-apps Application applied by Terraform through AKS Run Command** (`az aks command invoke`); `run_command_enabled = true` | Keeps the single apply. Run Command reaches the cluster through ARM and therefore bypasses the IP allow-list; it still needs Entra ID and Kubernetes RBAC. Accepted risk. |

### Data and messaging

| ID | Decision | Reason and consequences |
|---|---|---|
| AD-21 | **Kafka on AKS through the Strimzi operator** (Kafka 4.3.2, KRaft) | Managed alternatives (Event Hubs Kafka endpoint, Confluent Cloud) cost more or behave differently. Local compose stays on 4.1.2. |
| AD-42 | **One Kafka node (broker + controller), replication factor 1, ~10 GiB volume** | Quota. Production design (3 nodes, RF 3, `min.insync.replicas` 2) only on paper. |
| AD-22 | **MongoDB as a plain StatefulSet, `mongo:8.0`, replica set `rs0` with one member** | Cosmos DB for MongoDB is not the same engine and costs more. A replica set is needed for transactions and change streams later. |
| AD-23 | **Kafka SASL/SCRAM-SHA-512 + TLS + ACLs from the first deploy** | Required an application change, approved by the owner: optional `KAFKA_SECURITY_PROTOCOL`, `KAFKA_SASL_*`, `KAFKA_SSL_CA_LOCATION` variables (default PLAINTEXT, so compose is unchanged). |
| AD-25 | **No MongoDB backup** | Dev data is disposable (AD-31). |
| AD-36 | **Secrets: Kafka users and passwords generated by Strimzi inside the cluster; MongoDB passwords generated by Terraform as ephemeral values and written to Key Vault write-only (never in state), read by pods through the Key Vault CSI driver + workload identity** | No secret in Git, pipeline YAML, images or Terraform state. |
| AD-46 | **api and consumer get the MongoDB password through CSI secret sync → Kubernetes Secret → env `MONGO_PASSWORD`; `MONGO_URI` composed with `$(MONGO_PASSWORD)`** | No application change. |

### Security and supply chain

| ID | Decision | Reason and consequences |
|---|---|---|
| AD-15 | **ACR Basic**, no admin user, RBAC pull/push | Cheapest tier; network rules and retention are Premium-only (accepted). |
| AD-16 | **Images signed with Cosign using a key in Key Vault; Kyverno verifies signatures** | The private key never leaves Key Vault. No Rekor transparency log (the key is private to the project). |
| AD-43 | **NetworkPolicy default-deny (ingress and egress) in `shop` and `kafka` + explicit allow list** | Gateway → client, client → api, clients → Kafka, api/consumer → MongoDB, DNS, Entra ID / Key Vault for the CSI driver. |
| AD-44 | **Kyverno image verification in Enforce mode from the first deploy, only for images from our ACR**; tags are mutated to digests | An unsigned image of ours never runs. |

### Observability

| ID | Decision | Reason and consequences |
|---|---|---|
| AD-26 | **Hybrid: Managed Prometheus + Container Insights (namespaces `shop` and `kafka` only) + Prometheus alert rules + e-mail action group; free Grafana dashboards in the portal** | Log Analytics retention 30 days, daily cap 0.25 GB. |

### Delivery

| ID | Decision | Reason and consequences |
|---|---|---|
| AD-28 | **GitHub, public repositories** | Public so Argo CD needs no repository credentials. |
| AD-29 | **Microsoft-hosted agents** | No agent VM to run or pay for. |
| AD-30 | **Azure Pipelines for CI, Argo CD for CD (GitOps)** | The pipeline never talks to the cluster. |
| AD-40 | **Separate GitOps repository** ([gitops-shop](https://github.com/yaninagroisman/gitops-shop)) | Application and configuration change at different speeds; CI commits image tags there. |
| AD-41 | **GitOps layout: third-party components as upstream Helm charts in Argo CD Applications; our manifests as plain YAML + Kustomize** | `apps/` (app of apps), `platform/{gateway,kafka,mongodb,policies}`, `shop/`. |
| AD-45 | **GitOps bridge: Terraform passes per-environment, non-secret values (ACR, Key Vault, tenant, workload identity client IDs, Cosign public key, Gateway FQDN and annotations) through the root Application's `helm.valuesObject`** | Nothing environment-specific is committed; re-creating the environment needs no Git change. |
| AD-47 | **GitHub ↔ Azure DevOps through the Azure Pipelines GitHub App** | Installed by hand once; no personal access tokens. |
| AD-48 | **CI writes to the GitOps repository with an SSH deploy key** (write access to that repository only), stored as an Azure DevOps Secure File | Smallest possible permission. |
| AD-49 | **Direct push to `gitops-shop` main; image tag = first 12 characters of the git SHA** | Fully automatic CD for dev. Pull-request promotion between environments only on paper. |
| AD-50 | **CI checks: Gitleaks, ruff, hadolint, pytest, Trivy (fails on fixable CRITICAL/HIGH)**; no SBOM or attestations | Pinned tool versions (`ruff.toml` pins ruff 0.17.6). |
| AD-51 | **The CI identity gets Reader on `rg-shop-dev-swc`** | It discovers the ACR and Key Vault names, which change with every re-creation. Reader was added to the bootstrap ABAC allow-list. |

### Capacity finding (2026-11-28, open)

The first `terraform apply` of dev created 57 of 58 resources. The root Application failed because no pod could be scheduled: the AKS add-ons alone reserve almost all of the 3.8 allocatable vCPU of 2 × D2ads_v5.

| Consumer | CPU requests |
|---|---|
| AKS system pods (CNI, CSI, CoreDNS, metrics-server, Workload Identity webhook, …) | ~1330m |
| Monitoring agents (Container Insights + Managed Prometheus) | ~1006m |
| Argo CD extension | ~620m |
| KEDA add-on | ~420m |
| istiod (App Routing Gateway API, 2 replicas minimum) | 1000m |
| Our stack (Kafka, MongoDB, apps, cert-manager, Strimzi, Kyverno) | ~740–1300m |
| **Needed / allocatable** | **~5900m / 3800m** |

Options under consideration (decision pending):

1. **Fit into 4 vCPU:** drop or reduce monitoring (AD-26), replace the Istio-based Gateway with a light Gateway API controller such as Envoy Gateway (AD-11), self-managed KEDA with one replica, fewer Kyverno controllers, Image Cleaner off. Estimated total 2.7–3.4 vCPU.
2. **Upgrade to Pay-As-You-Go** and request an 8 vCPU quota (2 × D4ads_v5). The architecture stays as it is. The owner declined this for now.

Two clusters in two regions were considered and rejected: the add-on overhead is per cluster, and the first cluster alone needs ~4.4 vCPU.

**Lesson:** size a small AKS cluster by the CPU requests of the managed add-ons first, not only by the workloads.

## Open questions

| ID | Question | Status |
|---|---|---|
| — | Rate limiting at the Gateway | Not decided; nothing is implemented. |
| — | Azure Policy for ARM resources (allowed locations, SKUs, tags) | Not decided; nothing is implemented. |
| — | Terraform plan/apply pipelines | Service connections `sc-azure-tf-plan` / `sc-azure-tf-apply` and environment `dev` exist; the pipeline YAML is not written. Terraform is applied locally today. |
