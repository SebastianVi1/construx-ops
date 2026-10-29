---
tags: [architecture, backend]
verified: 2026-10-28
---
# Identity and sessions

Identity answers who the user is. UserAccount, UserProfile and AuthSession represent account, profile and authentication-session concepts. AuthController and token services expose authentication behavior.

Do not confuse a persisted refresh-session record with the API HTTP session: the API security chain is stateless. Membership and project permissions belong to separate domain concepts.

## Connections
- [[backend/Security]]
- [[backend/Organizations and Access]]
- [[frontend/Authentication]]

## Source evidence
Paths are relative to the repository root (the parent of this vault). Line references describe the inspected working tree.

- `construx/src/main/java/org/andre/construx/shared/config/SecurityConfig.java` — lines 46–90.
- `construx-dashboard/src/features/auth/AuthProvider.tsx` — lines 7–39.
