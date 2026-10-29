---
tags: [architecture, frontend]
verified: 2026-10-28
---
# From UI data to HTTP

Feature API modules describe response schemas and call shared authenticated JSON helpers. Organization-scoped URL construction connects selected workspace context to backend routes.

For example, sitesApi treats Site as the Project response and calls the organization projects route. Domain labels may change at this boundary without creating a second backend entity. Request validation and server permission checks remain backend responsibilities.

## Connections
- [[frontend/Project Features]]
- [[frontend/Finance and Materials]]
- [[frontend/Authentication]]
- [[backend/Backend]]
- [[Request Flow]]

## Source evidence
Paths are relative to the repository root (the parent of this vault). Line references describe the inspected working tree.

- `construx-dashboard/src/features/sites/sitesApi.ts` — lines 1–24.
- `construx-dashboard/src/features/auth/authApi.ts` — lines 72–130.
- `construx/src/main/java/org/andre/construx/modules/project/controller/ProjectController.java` — lines 27–45.
