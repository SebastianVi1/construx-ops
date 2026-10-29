---
tags: [architecture, backend]
verified: 2026-10-28
---
# Projects are sites in the UI

Project belongs to Organization and represents a site in the dashboard. It carries an allocated budget and project access relationships.

A project contains phases (Goal); phases contain tasks (Activity). Keep database/domain names distinct from UI labels when tracing requests. The site API consumes the Project response rather than a separate Site entity.

## Connections
- [[backend/Organizations and Access]]
- [[backend/Phases]]
- [[backend/Finance]]
- [[frontend/Project Features]]

## Source evidence
Paths are relative to the repository root (the parent of this vault). Line references describe the inspected working tree.

- `construx/src/main/java/org/andre/construx/modules/project/model/Project.java` — lines 28–54.
- `construx-dashboard/src/features/sites/sitesApi.ts` — lines 1–24.
