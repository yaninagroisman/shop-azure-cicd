# CLAUDE.md: permanent instructions for this project

Marvellous Mischief Co. is an immersive and gamified e-commerce platform. The project started as a training Full-Stack and DevOps project and is intended for an exclusive source-code sale. See `docs/PRODUCT_VISION.md`.

## Communication

- The owner writes in Russian. Reply in Russian.
- Technical documentation is written in **English**. `REPORT.md` is the Russian work log and stays in Russian.
- Ask questions as plain chat text, not as dialog widgets.

## Before starting any task

1. Read `docs/PROJECT_STATUS.md` (short) to identify the current phase.
2. In `docs/ROADMAP.md`, read **only** the task's row and the rows of its dependencies (for example `grep -n "P1-19" docs/ROADMAP.md`). Do not read the whole roadmap unless the task is about the roadmap itself.
3. Check the task's dependencies.
4. Clarify its acceptance criteria. If the task is not in ROADMAP, propose adding it there with an ID instead of keeping a separate list.

## After finishing any task

1. Verify the implementation.
2. Run the relevant tests where possible. Never invent results; if a check was impossible, say why.
3. Update the task's status, evidence and date in its row in `docs/ROADMAP.md` (edit the row, do not reread the file), and the progress table if a status changed. Mark it `COMPLETED` only after its acceptance criteria were actually checked.
4. Update `docs/PROJECT_STATUS.md`. Phase progress = completed tasks ÷ all tasks in the phase.
5. Update `CHANGELOG.md`.
6. Update only the technical docs the change actually affects (ARCHITECTURE, API, DATABASE, SECURITY, TESTING, DEPLOYMENT, DESIGN_SYSTEM, FEATURES); read just the section you change.
7. Record new technical decisions in `docs/DECISIONS.md`.
8. Append a short note to the end of `REPORT.md` (Russian work log). Only append; never read the whole file (it is large). Use `tail` if you need the last section.

`docs/ROADMAP.md` is the **single source of truth** for tasks. Never create competing roadmaps or task lists.

## Development rules

- No large refactoring without the owner's agreement.
- Do not change the approved visual design without the owner's permission.
- No unnecessary complexity. Do not add technologies just to have them, and no new dependencies without approval.
- Keep separation of concerns, maintainability, security and portability. Make the project easy for a future buyer to take over.
- Separate required features from optional improvements. Do not grow the commercial scope without assessing its value, and do not change agreed priorities on your own.
- Never call the project "Production Ready" before the corresponding checks pass.
- Never commit real passwords, tokens, API keys or other secrets.
- No names or elements of existing book or film franchises anywhere in code, assets or docs, because the product is for commercial use.
- The backend (`api/`) is written by the owner. Do not implement it unless asked; keep the client side in line with `docs/API.md`.
- Do not touch `compose.yaml` or other infrastructure files unless the current roadmap task requires it.

## Useful facts

- Tests: `cd client && pip install -r requirements-dev.txt && playwright install chromium && pytest`. Run them after every frontend change.

- The frontend lives in `client/app/`. Preview: the docker container `mischief-preview` on port 8000 mounts `client/` read-only. Run `docker restart mischief-preview` after edits.
- API contract: `docs/API.md`, implemented on the client side by `client/app/static/js/api.js`.
