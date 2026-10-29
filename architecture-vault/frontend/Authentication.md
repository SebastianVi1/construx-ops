---
tags: [architecture, frontend]
verified: 2026-10-28
---
# Browser authentication

AuthProvider restores the session on mount. Its guard avoids duplicate refresh work under StrictMode. The shared auth API includes credentials and fetches CSRF proof before unsafe methods. Refresh is single-flight because refresh-token rotation makes concurrent reuse unsafe.

Feature clients reuse the shared JSON helpers rather than defining independent authentication mechanisms. A successful UI guard is not proof of server authorization. Deployed cookie, CORS and proxy behavior was not exercised for this vault.

## Connections
- [[backend/Security]]
- [[backend/Identity]]
- [[frontend/API Boundary]]
- [[frontend/Routing and State]]

## Source evidence
Paths are relative to the repository root (the parent of this vault). Line references describe the inspected working tree.

- `construx-dashboard/src/features/auth/AuthProvider.tsx` — lines 7–39.
- `construx-dashboard/src/features/auth/authApi.ts` — lines 72–94, 109–130.
