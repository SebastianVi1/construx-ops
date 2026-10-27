# Registration intent is a hint, not a role

Status: accepted (2026-10-26)

At first login the user answers an onboarding question: `RUN_COMPANY` or `WORKER_OR_INVITED` (plus an optional descriptive `businessType`: Owner/Developer, General contractor, Architect/Engineer, Subcontractor). It is stored server-side in `UserOnboarding` and only steers the dashboard (create a company vs complete profile and accept invitations). It never grants permissions and never creates an organization.

Roles come only from membership: the creator of an organization becomes Owner (seeded role `OWNER`); everyone else gets the role carried by an invitation. Trade or specialty is a profile field, not a permission. Anyone may create an organization regardless of their stated intent.

Why: trusting a self-declared answer for authorization is a privilege-escalation risk, and a person can be a company owner in one organization and a worker in another. Considered and rejected: mapping the four business types to roles; auto-creating an organization when intent is `RUN_COMPANY` (hidden side effect, hard to undo).

Consequences: onboarding answers can change at any time via `PUT /api/onboarding` without side effects; the old `localStorage` answer is migrated by the dashboard on the first authenticated session.
