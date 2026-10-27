# Internal assignment only, no public marketplace

Status: accepted (2026-10-26)

The "marketplace" of workers is internal assignment: an organization assigns people it already has (members with an account, given a `ProjectAccess` on a site) to tasks. There are no public listings, no cross-organization search of workers or sites, and no account-less workers. Tenant isolation stays strict: every business query is filtered by organization and a user of another organization gets 404.

Why: a public marketplace needs cross-tenant visibility, trust, verification and payments, which contradicts the strict per-Organization isolation the whole authorization model relies on. Doing it later is additive (a separate module with explicit sharing), while loosening isolation inside v1 would be hard to undo.

Consequences: a crew member who never logs in cannot be assigned in v1 (revisit open decision 4 with a real need). A person working for several companies has one account with one membership per organization.
