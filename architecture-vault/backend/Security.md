---
tags: [architecture, backend]
verified: 2026-10-28
---
# API security boundary

The API chain is stateless. Spring Security resolves the bearer JWT from the access_token cookie. Because browsers send cookies automatically, a custom CSRF filter protects unsafe methods. Public authentication endpoints are permitted by authentication rules, not exempted from every other protection.

OAuth login has a separate filter chain that may require an HTTP session. Credentialed CORS and authentication do not replace tenant and resource permission checks. These statements describe source configuration, not a penetration test or deployed verification.

## Connections
- [[backend/Identity]]
- [[backend/Organizations and Access]]
- [[frontend/Authentication]]
- [[Request Flow]]

## Source evidence
Paths are relative to the repository root (the parent of this vault). Line references describe the inspected working tree.

- `construx/src/main/java/org/andre/construx/shared/config/SecurityConfig.java` — lines 46–120.
