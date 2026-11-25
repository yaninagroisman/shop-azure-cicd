# Commercial Readiness

> **Verdict (2026-11-25): not ready for sale.** This is a pre-commercial demo, and the backend is still missing. The checklist tasks are tracked in [ROADMAP.md](ROADMAP.md) Phase 5.

## Readiness checklist (summary)

| Area | State | Roadmap |
|---|---|---|
| Working end-to-end product | ✗ (frontend only, mock orders) | Phase 1 |
| Public demo | ✗ | P3-01 |
| Version control and clean history | ✓ local git (2026-11-25) | P1-16, P5-10 |
| Automated tests | partial (client: 64 tests) | P1-12, P5-05 |
| IP clean | partial (code, images and docs OK; folder name open; easter eggs kept (D-021)) | P5-13 |
| Right to sell (training project) | ✓ per contract (owner) | P5-14 |
| AI asset terms | generator recorded (ChatGPT), details open | P5-15 |
| Licences of fonts and libraries | partial (fonts OFL, Flask BSD-3, pymongo Apache-2.0) | P5-12, P5-16 |
| Rebrandable without code edits | ✗ (store name, texts, words hard-coded) | P4-36…P4-44 |
| Buyer documentation | started (`docs/`) | P5-17…P5-21 |

## Technical and commercial risks

| ID | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| R-01 | ~~No version control~~. **Resolved 2026-11-25**: local git repository (P1-16). A remote is still to be chosen (D-016) | — | — | Push to a private remote |
| R-02 | **Backend not written.** The core course requirement (Kafka async writes) is not met: `app.py` and `consumer.py` are empty | Certain (today) | High | The owner is writing it (D-018): P1-02, P1-09, P1-10 |
| R-03 | **Residual third-party IP.** Code and images are rebranded, but: (a) ~~docs mapping products to the franchise~~ removed 2026-11-25 (P1-18); (b) the project folder is named "HP Store Project"; (c) the catalogue concept and the easter eggs (secret map with an oath phrase, spell-like Latin words, a family clock with danger hands, twin shop owners) closely follow that franchise | High | High: a buyer's legal review could reject it | Docs scrubbed (P1-18). Rename the folder; easter eggs kept as they are by owner decision (D-021); have an IP lawyer review the theme (P5-13). Consider making a second, neutral demo theme the primary listing (P4-39) |
| R-04 | ~~Ownership of a training project~~. **Resolved 2026-11-25**: the owner confirmed that the training contract allows the sale (P5-14) | — | — | Keep a copy of the clause for buyer due diligence |
| R-05 | **Partial test coverage.** The client has 64 automated tests (2026-11-25); the backend has none yet | Certain | Medium | P1-12 |
| R-06 | **AI-generated images** (ChatGPT, OpenAI). The generator is recorded; dates and prompts are not. Some jurisdictions give weak copyright protection to AI output, which lowers its exclusive value | Medium | Medium | Asset register (P5-15, P5-16); disclose it in the listing |
| R-07 | **Non-atomic checkout.** A basket is N sequential `POST /api/buy` calls, so a failure midway leaves it partly ordered | Medium | Medium | Fix planned: P1-19 (one order with lines; contract change) |
| R-08 | **Catalog lives only in the client app** (`catalog.py`). The API cannot price orders without duplicating it | Certain | Medium | Deferred to the admin panel (D-014, P4-03) |
| R-09 | ~~Repo weight~~. **Resolved 2026-11-25**: PNG masters moved out of `static/` and out of git (P1-17) | — | — | — |
| R-10 | **Kafka cost in the cloud.** Managed Kafka can be expensive for a demo; single node, RF 1 today | Medium | Medium | Cost analysis in P2-01 (including Kafka-compatible managed options) |
| R-11 | **Schema drift.** The Mongo test document uses old field names, slug and prices | Certain | Low | Remove it; contract tests (P1-09) |
| R-12 | ~~Image pipeline not reproducible~~. **Resolved 2026-11-25**: scripts saved in `optional-concepts/tools/` with a README | — | — | — |
| R-13 | **Theme hard-coded across templates and JS** (store name, copy, secret words) | Certain | Medium for white-label | P4-36…P4-44; extract to config incrementally |
| R-14 | **Dev server in use** (`flask run`) | Certain | Low now, High if exposed | P1-13 Gunicorn |

## Market notes (to be filled in Phase 3)

- Price hypothesis: $3,000–6,000, **unconfirmed**.
- Competitors, marketplaces (SideProjectors, Flippa) and buyer list: P3-04…P3-07.
