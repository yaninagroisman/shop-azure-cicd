# Handover

This file has two parts:

- **A:** continuing development, for a new developer or a new AI session.
- **B:** the final transfer to a buyer (Phase 6).

## A. Continuing development

1. Read [ROADMAP.md](ROADMAP.md) and [PROJECT_STATUS.md](PROJECT_STATUS.md).
2. Run the frontend as described in [DEPLOYMENT.md](DEPLOYMENT.md) §1. Infrastructure: `docker compose up -d`.
3. Pick the next task from PROJECT_STATUS → *Recommended next tasks*. Check its dependencies and acceptance criteria in ROADMAP.
4. When the task is done, update the docs.

Where things are:

| Need | Look at |
|---|---|
| How the system fits together | [ARCHITECTURE.md](ARCHITECTURE.md) |
| API contract | [API.md](API.md) |
| Visual rules | [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) |
| Detailed history of the frontend work (Russian) | [REPORT.md](../REPORT.md) |
| Why something is the way it is | [DECISIONS.md](DECISIONS.md) |

## B. Buyer handover checklist (Phase 6, all open)

- [ ] Repository transferred (P6-08), with history scrubbed of third-party IP and secrets (P5-10, P5-11).
- [ ] Buyer documentation pack delivered (P6-09): README, docs/, Installation, Rebranding and Deployment guides, Known Limitations.
- [ ] Source assets delivered (P6-10): original images, the asset register with licences and AI-generator terms.
- [ ] Infrastructure transferred or destroyed (P6-11).
- [ ] All credentials rotated (P6-12).
- [ ] Owner's personal access removed and verified (P6-13).
- [ ] Rights schedule signed (P6-06).
- [ ] Buyer sign-off (P6-14).

**Do not hand over** `REPORT.md` as it is: it may name the franchise the theme was derived from (risk R-03).
