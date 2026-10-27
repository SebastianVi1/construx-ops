# Task is Activity

Status: accepted (2026-10-26)

The product vision lists "tasks" and "activities" separately. In v1 they are the same thing: a task is an `Activity`, grouped under a `Goal` (phase) under a `Project` (site), assigned to a `ProjectAccess`. The UI may say "task"; the API and code say `activity`. Two concepts with no behavioral difference would force duplicate models, endpoints and permissions (`VIEW/MANAGE_ACTIVITY` already cover the use case).

Consequences:
- If "what is happening in a zone" later needs its own concept (plans and zones, roadmap item 5), it is added as a zone link on `Activity` or a new entity then, not preemptively.
- Every activity has an assignee with an account (`Activity.assigneeAccess` NOT NULL). Unassigned backlog tasks are out of v1 (contract Q3).
- Glossary: Task (UI) = Activity (code); Phase = Goal.
