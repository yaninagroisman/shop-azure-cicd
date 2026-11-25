# Project Status

> Snapshot of [ROADMAP.md](ROADMAP.md), which wins if the two ever disagree. Update both after every task.
>
> **Last updated: 2026-11-25** (Netlify preview published)

## Current phase

**Phase 1: Core Project Completion.** Progress is **6 of 19 tasks completed (32%)**.

In mock mode the frontend is functionally complete and covered by 64 automated tests. The project is now under git. The backend (API → Kafka → consumer → MongoDB) is written by the owner as part of the course. Today the containers run, but `api/app.py` and `api/consumer.py` are empty.

## Progress by phase

Progress = completed tasks ÷ all tasks in the phase.

| Phase | Completed / total | Progress |
|---|---:|---:|
| 1. Core Project Completion | 6 / 19 | 32% |
| 2. Azure & DevOps | 0 / 17 | 0% |
| 3. Market Validation | 1 / 12 | 8% |
| 4. Commercial Product Development (including the Admin Panel, P4-01…P4-11) | 0 / 43 | 0% |
| 5. Commercial Readiness & Packaging | 1 / 24 | 4% |
| 6. Sale & Handover | 0 / 14 | 0% |
| **Overall** | **8 / 129** | **6.2%** |

## Done on 2026-11-25

- P1-03: catalogue verified by automated tests.
- P1-16: project under git.
- P1-17: unused PNGs removed from `static/`.
- P1-18: franchise references removed from the docs.
- P3-12: static preview published on Netlify (mock mode).
- P1-01: mobile fixes (no sideways panning, steam position, darkness smoke clip); P5-13: margin-note signature fixed.
- P5-14: the owner confirmed the right to sell under the training contract.
- P1-12 started: `client/tests/` exists, with 64 tests passing.

## Blockers and open decisions

- **P1-05 Order Processing** is blocked until the owner's backend (P1-02, P1-10) exists.
- **D-014** (catalog and price source for the backend) is deferred to the admin panel (P4-03).
- **D-015** (who writes the `pending` row) is the owner's call while writing the backend.
- **P1-19 atomic checkout** needs the API contract change agreed with the backend.
- **P5-13 IP:** the project folder is still named "HP Store Project". The easter eggs stay as they are (D-021).

## Recommended next tasks (in order)

1. **P1-02, P1-10, P1-09 (owner):**
   - write the API, the Kafka producer and consumer, and the MongoDB write;
   - remove the stale test document;
   - follow [API.md](API.md).
2. **P1-19:** agree the "one order with lines" contract, then implement it on both sides.
3. **P1-13, P1-14:** `client/Dockerfile` (Gunicorn), plus compose services for client, api and consumer, with health checks.
4. **P1-12:** API and consumer tests, and an integration test through Kafka.
5. **P5-13:** rename the project folder (after closing the session).

## Change log of this file

| Date | Change |
|---|---|
| 2026-11-25 | Initial audit and status baseline |
| 2026-11-25 | Owner decisions: git, tests, PNG cleanup, IP scrub of the docs, D-014 deferred, P1-19 added, P5-14 confirmed |
| 2026-11-25 | P3-12 completed: Netlify preview published |
