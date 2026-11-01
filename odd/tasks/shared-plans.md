# Shared Plans library
Move Plans to its own workspace destination while preserving site ownership and authorization.
Branches: `feat/shared-plans` in API/dashboard. Delivery: ask-on-risk; forecast ~1,000 authored lines, no publishing. Runners: Maven/H2, Bun, lint/build.

## Specs
- S1: "Vamos a cambiar el apartado de planos a la barra lateral, que sea igual que el deexcel por carpetas y"; "bueno mas bien que el apartado de planos sea independiente que no este dentro de obras". Independent Plans page and folder navigation; remove embedded site section.
- S2: "si" to retaining association with an obra. Existing plans and project-scoped operations remain compatible.
- S3: "si" to shared folders backed by the server. Nested folder creation, rename, move, deletion and plan organization persist across sessions/users.
- S4: "si" to only owners/admins managing shared folders and other users keeping current plan permissions. No hidden project plans or metadata in library responses.
- S5: "si" to API and dashboard tests, preserving plans and their site when deleting a folder. Deletion promotes direct children and plans to the parent (root when absent), never deletes files.

## Tasks
- T1 [S2-S5] inline / done: additive folder schema and authenticated library API; API-flow RED/GREEN. Full suite 411/411. Commit `147c320` (construx).
- T2 [S1-S5] inline / done: independent page, sidebar folders, folder actions, reuse upload/view/delete; Bun 506/506, lint and build. Commits `beb6031`, `85459bb` (construx-dashboard).
- T3 [S1-S5] done: independent scoped review (no blockers; 6 minor findings fixed), disposable PostgreSQL 17 migration check (`V1..V22` applied, `ddl-auto=validate` startup OK). Browser check still pending (no dev credentials).

## Log
- L1 User: "Vamos a cambiar el apartado de planos a la barra lateral, que sea igual que el deexcel por carpetas y". Clarification: "bueno mas bien que el apartado de planos sea independiente que no este dentro de obras". Confirmations above were each "si".
- L2 User authorized `gpt-6-luna` substitution for unavailable `gpt-6.1-luna`. Read-only map completed. Existing Excel folder state is browser-local, whereas plans are backend-owned.
- L3 Preserve dirty API application.properties, .agents/specs and untracked docker-compose.yml; umbrella and landing changes unrelated. Baselines API 25243d1, dashboard f29dddb. No backend app startup against configured database.
- L4 API contract: GET /organizations/{org}/plan-library -> folders, sites (id/name/canManage), plans, canManageFolders. Folder POST/PATCH/DELETE at /plan-folders; PUT site-scoped /plans/{plan}/folder accepts nullable folderId. Existing plan responses gain optional folderId. Folder updates use full name/parentId replacement. Tree writes serialize on organization row. No new permission grants.

- L5 API RED: folder POST returned 404. GREEN: lifecycle API test passed. Administrator regression RED: 403 with correct ADMINISTRATOR role; fixed role code. Focused API 14 tests passed. Dashboard RED missing library helper; GREEN 26 focused tests, lint and build (existing Excel large-chunk warning). No source changes in unrelated files.
- L6 (2026-10-31) Finish pass: independent review found no blockers (authorization, tree integrity and contract verified; `SELECT ... FOR UPDATE` observed on every mutation). Fixed minors: sidebar opens the active folder's ancestors on deep links, distinct "No parent (root)" option, removed a duplicate retry button, deleted the dead `SitePlans`/`listPlans`, and replaced the per-site plan query with one `projectId in (...)` query. Documented the endpoints and `folderId` in `construx/docs/plans.md`. Verification: API full suite 411/411; dashboard 506/506, lint and build; disposable PostgreSQL 17 with Flyway V1..V22 and `ddl-auto=validate` started cleanly. Privacy trade-off confirmed as specified: Members see organization folder names, never hidden-site plans or counts. Browser check remains pending.
