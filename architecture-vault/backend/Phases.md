---
tags: [architecture, backend]
verified: 2026-10-28
---
# Goals are phases in the UI

Goal belongs to a Project. It represents a dated phase and contains task-level work. Dates and color are part of the phase representation.

The frontend goals client addresses phases below the organization and project URL. Budget and aggregate fields may be hidden or nullable: absence must not be interpreted as a numeric zero.

## Connections
- [[backend/Projects]]
- [[backend/Tasks and Team]]
- [[frontend/Project Features]]

## Source evidence
Paths are relative to the repository root (the parent of this vault). Line references describe the inspected working tree.

- `construx/src/main/java/org/andre/construx/modules/project/model/Goal.java` — lines 31–54.
- `construx-dashboard/src/features/goals/goalsApi.ts` — lines 6–44.
