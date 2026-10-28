# Task team with a fixed task role hierarchy

Status: accepted (2026-10-28)

A task (`Activity`) is assigned to a team instead of one person. Each team member has a task role from a fixed list ordered Lead > Foreman > Crew, and every task has exactly one Lead. The task role is stored per assignment, so one person can lead one task and be crew on another. It is separate from the organization role: permissions still come from the organization role, with one explicit exception. The current Lead of a task may record expenses on that task, edit or delete the ones they recorded, and see that task's budget and spending, whatever their organization role. The Lead cannot change how much budget the task is allocated.

Why: crews on a site work in teams with a person in charge, and the single required assignee from v1 could not express that. A fixed list keeps translation and validation simple, where a per-organization catalogue would need its own management screens. Keeping task roles out of the permission model, except for the named expense right, avoids two authorization systems that overlap. Letting the Lead spend but not allocate keeps spending and approval with different people.

Consequences: the single `assignee_access_id` column is replaced by a team table, and existing assignees become Leads. The API returns `assignees` instead of `assignee`. Expenses gain an optional link to a task and record who created them. Supersedes the single-assignee rule of the v1 contract; ADR 0003 (internal assignment only) still holds.
