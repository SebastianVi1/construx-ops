# Reset prices to a basic structure
Objective: Remove current pricing business logic and stored pricing data, leaving the original `/prices` visual structure as a static shell for later implementation.
Branches: `feat/prices-reset-pr` in deployment, backend, and dashboard. Delivery: ask-on-risk. Runners: Maven and Bun.

## Specs

S1. "necesito cambiar todo ya, dejemos esa parte del prices limpia, borra todo lo voy a implementar despues,solamente deja la estructura basica. y elimina cualquier logica de servicio que haya". Remove catalog controllers, services, repositories, models, API client, and active catalog behavior. Retain `/prices` in existing navigation. Check: no pricing service endpoints or calls remain; dashboard builds and tests pass.
S2. "eliminalos." The user chose to remove the pricing schema and data as well. Preserve already published Flyway migration history and add a forward cleanup migration that drops pricing tables without cascading into unrelated data. Check: fresh and upgraded database migration tests; unrelated organization and document rows survive.
S3. Preserve the shared `VIEW_PRICES` permission action because Documents uses it to gate financial folders; keep the `/prices` navigation gate. This is a technical compatibility assumption, not a new product requirement. Check: permissions and Documents tests.
S4. Remove the interrupted, uncommitted import implementation and its dependency, and update active docs so they no longer describe pricing as implemented. Preserve unrelated local changes. Check: git diff/status and docs readback.
S5. "no deja la pantalla original pero sin funcionalidad solamente." Keep the original screen's visual structure (header, tabs, filters, and table) as a static bilingual shell. All controls are disabled; no catalog data or service calls remain. Check: component structure, accessibility, build, lint, tests.

## Tasks

- T1 [S2-S3] delegated backend; verified in `a0e87ae`. All pricing services removed; V39 removal migration passes fresh/upgrade tests and independent verification. Full H2-backed suite: 641 passed.
- T2 [S1,S5] inline dashboard correction after delegated initial deletion; verified in `015f4f1`. Original header/tabs/filters/table shape is static; lint, build, and 783 tests pass.
- T3 [S4] inline root/integration; verified in this branch. Interrupted import discarded, active docs marked proposed, old task removed; unrelated vault changes excluded from this PR.

## Log

L1. User: "necesito cambiar todo ya, dejemos esa parte del prices limpia, borra todo lo voy a implementar despues,solamente deja la estructura basica. y elimina cualquier logica de servicio que haya"
L2. Clarification answer: "eliminalos." This authorizes destructive pricing data/schema removal.
L3. Prior import implementation was interrupted. Backend and dashboard submodules were clean before it; all staged changes in those submodules were introduced by that interrupted work. Root has unrelated user changes. Engram mirror pending because no Engram tools are exposed.
L4. Published V38 creates pricing tables and migrates old material/price observations. Flyway history must remain; a new forward migration will drop pricing tables and data. `VIEW_PRICES` also gates Documents folders and therefore remains.
L5. User correction: "si y la pantalla del dashboard la dejamos como esta."
L6. User clarification: "no deja la pantalla original pero sin funcionalidad solamente." Reopened T2 to retain the original visual structure without API calls or active controls.
L7. Verification: backend `bash mvnw -Dspring.profiles.active=test test` passed 641 tests on H2; dashboard `bun run lint`, `bun run build`, and `bun test` passed (783 tests). Independent migration and dashboard verifiers found no blockers. React server rendering confirmed six tabs, all disabled controls, and seven columns in both locales. No persistent PostgreSQL database was changed; pixel-level browser inspection was unavailable.
L8. Concurrent root work moved `architecture-vault` during this task; the agent stopped editing that directory and preserved the user's replacement structure. Engram mirror remains pending because the tool is unavailable. Delivery chain choice remains pending before work-unit commits because the authored diff exceeds 400 lines.
L9. For PR isolation, created clean branches from `main` and cherry-picked only the Prices changes. The original branches also contained authentication work and a vault documentation replacement; those are excluded. Clean backend commit: `a0e87ae`; clean dashboard commit: `015f4f1`.
