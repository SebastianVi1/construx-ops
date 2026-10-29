---
tags: [architecture, frontend]
verified: 2026-10-28
---
# Sites, phases and tasks

Sites represent Projects; phases represent Goals; tasks represent Activities. The route tree includes site detail, phases, task detail and task listing screens. Feature clients carry statuses, assignees, dates, colors and budget-related data where defined by their contracts.

Read each layer using both vocabularies: a task screen is backed by Activity, not by a Java entity named Task. Task team role and organization role describe different permission contexts.

## Connections
- [[frontend/API Boundary]]
- [[backend/Projects]]
- [[backend/Phases]]
- [[backend/Tasks and Team]]
- [[frontend/Finance and Materials]]

## Source evidence
Paths are relative to the repository root (the parent of this vault). Line references describe the inspected working tree.

- `construx-dashboard/src/App.tsx` — lines 33–60.
- `construx-dashboard/src/features/sites/sitesApi.ts` — lines 1–24.
- `construx-dashboard/src/features/goals/goalsApi.ts` — lines 6–44.
- `construx-dashboard/src/features/tasks/tasksApi.ts` — lines 6–43.
