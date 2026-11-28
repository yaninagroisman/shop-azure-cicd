# Project Status

> Snapshot of [ROADMAP.md](ROADMAP.md), which wins if the two ever disagree. Update both after every task.
>
> **Last updated: 2026-11-28** (Azure and DevOps written; first dev apply blocked by the vCPU quota)

## Current phases

**Phases 1 and 2 run in parallel** (the owner started Phase 2 early, on 2026-11-26).

- **Phase 1, Core Project Completion:** the code is complete: shop front, Kafka producer, consumer, API, MongoDB, Dockerfiles and compose. 111 automated tests. The remaining work is an end-to-end run and owner acceptance.
- **Phase 2, Azure & DevOps:** everything is written: Terraform (bootstrap + dev), the GitOps repository and the CI pipeline. Bootstrap is applied. The dev cluster does not fit the 4 vCPU Free Trial quota, so the environment could not finish its first deployment.

## Progress by phase

Progress = completed tasks ÷ all tasks in the phase. Tasks that are written but not yet checked count as `IN_REVIEW`, not as completed.

| Phase | Completed / total | In progress or review | Progress |
|---|---:|---:|---:|
| 1. Core Project Completion | 6 / 19 | 12 | 32% |
| 2. Azure & DevOps | 2 / 17 | 13 (+1 blocked) | 12% |
| 3. Market Validation | 1 / 12 | 0 | 8% |
| 4. Commercial Product Development | 0 / 43 | 0 | 0% |
| 5. Commercial Readiness & Packaging | 2 / 24 | 4 | 8% |
| 6. Sale & Handover | 0 / 14 | 0 | 0% |
| **Overall** | **11 / 129** | **29** | **8.5%** |

## Done on 2026-11-26 … 2026-11-28

- **Backend (P1-02, P1-05, P1-09, P1-10, P1-11):**
  - `POST /api/buy` publishes to Kafka (idempotent producer);
  - at-least-once consumer with idempotent insert, `failed` with reason, dead-letter topic and retries;
  - api `GET /purchases` plus health endpoints;
  - Kafka SASL/SCRAM + TLS settings from the environment.
- **Containers and compose (P1-13, P1-14):** Gunicorn, non-root, pinned images and dependencies; the full stack with health-checked start order.
- **Tests (P1-12):** api 36, client 75; ruff pinned and clean; hadolint clean.
- **Azure design (P2-01):** 51 architecture decisions (AD-xx) approved by the owner.
- **Terraform (P2-02, P2-03, P2-14):**
  - `bootstrap/` applied: state, pipeline identities, Azure DevOps project, budget;
  - `environments/dev/` written and applied once (57/58 resources).
- **GitOps repository `gitops-shop`:** Argo CD app of apps, cert-manager, Strimzi Kafka, Kyverno, Gateway + Let's Encrypt, MongoDB, the shop, NetworkPolicies, image signature verification.
- **CI (P2-04 … P2-08):** `.azure-pipelines/ci.yml`: Gitleaks, ruff, hadolint, pytest, Trivy, push to ACR, Cosign signing, GitOps tag bump.
- **Secret scan (P5-11):** Gitleaks over the full history, 0 findings.
- **Documentation:** ARCHITECTURE, DECISIONS, DEPLOYMENT, SECURITY, TESTING, API, DATABASE and FEATURES updated for the backend and Azure.

## Blockers and open decisions

- **Cluster sizing (blocks P2-02, P2-17 and every Azure check):**
  - 2 × D2ads_v5 gives 3.8 allocatable vCPU; the AKS add-ons plus the stack request ~5.9.
  - Options: fit into 4 vCPU (lighter Gateway, less monitoring, self-managed KEDA), or Pay-As-You-Go with an 8 vCPU quota.
  - Details: [DECISIONS.md](DECISIONS.md), "Capacity finding".
- **Open questions:** rate limiting, Azure Policy, Terraform plan/apply pipelines.
- **D-014** (catalog source for the backend) is deferred to the admin panel (P4-03).
- **P1-19** atomic checkout needs an API contract change.

## Recommended next tasks (in order)

1. **Decide the cluster sizing** (P2-01), adjust Terraform and `gitops-shop`, then apply dev again (P2-02).
2. **One-time Azure DevOps setup** (GitHub App, deploy key) and the first CI run on `main` (P2-04 … P2-08).
3. **Check the deployment** with the list in [DEPLOYMENT.md](DEPLOYMENT.md) §2.6; record the evidence in ROADMAP.
4. **Run the local stack end to end** (`docker compose up`, one purchase) to close P1-05 … P1-15.
5. Terraform plan/apply pipelines; HSTS; a consumer-lag alert.

## Change log of this file

| Date | Change |
|---|---|
| 2026-11-25 | Initial audit and status baseline |
| 2026-11-25 | Owner decisions: git, tests, PNG cleanup, IP scrub of the docs, D-014 deferred, P1-19 added, P5-14 confirmed |
| 2026-11-25 | P3-12 completed: Netlify preview published |
| 2026-11-28 | Backend, containers, compose, tests; Azure design, Terraform, GitOps and CI written; first dev apply blocked by the vCPU quota |
