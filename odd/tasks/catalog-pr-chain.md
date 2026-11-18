# Catalog PR chain

Objective: Deliver the existing local changes through coherent commits and dependent pull requests, then merge them to main.
Branches: backend, dashboard, landing, and deployment PR branches merged to main. Delivery: chained PRs with approved size exceptions for indivisible units. Test runners: Maven, Bun, PostgreSQL 16.

## Specs

S1. Publish and merge the authorized local changes. User request: "haz un pr y un merge a main de los cambios"; clarified with "si haz el pr". Scope includes the root repository and submodules, excluding generated local caches.
S2. Deliver by important behavior units. User request: "dividelo en una cadena de commits y pr por cambios importantes". Acceptance: each PR has a coherent diff and declared dependencies.
S3. Permit size exceptions for units that cannot be split safely. User response: "si" to the proposed exception. Acceptance: explain the overage and preserve tests and docs with their behavior.

## Tasks

- [x] T1 (S1-S3, inline): Backend catalog cutover and migration verified; `f574bf3`, backend PR #21 merged.
- [x] T2 (S1-S3, inline): Dashboard catalog UI and archived-filter fix verified; `0859128`, `1672a54`, dashboard PRs #28 and #29 merged.
- [x] T3 (S1-S2, inline): Landing draft PRD published; `1ab46a0`, landing PR #3 merged.
- [x] T4 (S1-S2, inline): Root domain docs, agent roles, Ponytail skill, and submodule pointers verified; `151c774`, `1fdb652`, `50143e8`, `6e56a88`, deployment PRs #76-#79 merged.
- [x] T5 (S1-S2, inline): Backend finance docs and local Compose published; `8d86222`, `234f3ca`, backend PRs #22-#23 merged.

## Log

L1 (2026-11-17): "haz un pr y un merge a main de los cambios"
L2 (2026-11-17): "si haz el pr"
L3 (2026-11-17): "dividelo en una cadena de commits y pr por cambios importantes"
L4 (2026-11-17): "si" (approved size exceptions for units that cannot be split safely).
L5: Backend compile and 67 focused tests passed on H2. V38 converted representative prior data on disposable PostgreSQL 16. Dashboard lint, build, and 840 tests passed. Engram mirror pending because memory tools are unavailable in this session.
L6 (2026-11-18): Backend PRs #21-#23, dashboard PRs #28-#29, landing PR #3, and deployment PRs #76-#79 were merged to main. The agent-role and domain-contract reviews found and resolved concrete mismatches before those PRs. Three empty skills-lock hashes were recalculated and checked with the installed CLI.
L7 (2026-11-18): Concurrent password-policy edits in backend/dashboard, a local `docker-compose.dev.yml` override, `backend-worktree/`, and generated `.codegraph/` / `.playwright-mcp/` artifacts appeared during delivery and were not included. The current delivery logbook is published separately after the product and deployment PRs.
