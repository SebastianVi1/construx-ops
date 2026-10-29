---
tags: [architecture, backend]
verified: 2026-10-28
---
# Activities are tasks in the UI

Activity belongs to Goal. ActivityAssignee links an activity to ProjectAccess and TaskRole, so a task team is more than an arbitrary list of user IDs.

The frontend represents TODO, IN_PROGRESS and DONE states and LEAD, FOREMAN and CREW task roles. Task roles are not interchangeable with organization roles. Expenses can also link to a task.

## Connections
- [[backend/Phases]]
- [[backend/Organizations and Access]]
- [[backend/Finance]]
- [[frontend/Project Features]]

## Source evidence
Paths are relative to the repository root (the parent of this vault). Line references describe the inspected working tree.

- `construx/src/main/java/org/andre/construx/modules/project/model/Activity.java` — lines 35–53.
- `construx/src/main/java/org/andre/construx/modules/project/model/ActivityAssignee.java` — lines 22–46.
- `construx-dashboard/src/features/tasks/tasksApi.ts` — lines 6–43.
