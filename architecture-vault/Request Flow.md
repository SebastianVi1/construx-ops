---
tags: [architecture, flow]
verified: 2026-10-28
---
# Follow a project request

A representative project request crosses these responsibilities. The diagram is a conceptual request trace; it does not claim that a browser/network trace was captured.

```mermaid
sequenceDiagram
    participant UI as Dashboard screen
    participant API as sitesApi + authApi
    participant SEC as Spring Security
    participant CTRL as ProjectController
    participant SVC as ProjectService
    participant DB as JPA / PostgreSQL
    UI->>API: Request projects for organization
    API->>SEC: HTTP request with credentials
    Note over API,SEC: Unsafe methods additionally use CSRF proof
    SEC->>CTRL: Authenticated request
    CTRL->>SVC: Delegate use case
    Note over SVC: Membership, tenant lookup, permissions
    SVC->>DB: Load authorized domain data
    DB-->>SVC: Entities / query result
    SVC-->>CTRL: Result
    CTRL-->>API: HTTP response
    API-->>UI: Parsed feature data or error
```

## Read the source in this order

1. `construx-dashboard/src/features/sites/sitesApi.ts:1–24` — UI Site maps to Project.
2. `construx-dashboard/src/features/auth/authApi.ts:72–130` — credentials, CSRF and refresh boundary.
3. `construx/src/main/java/org/andre/construx/shared/config/SecurityConfig.java:57–90` — API filter chain.
4. `construx/src/main/java/org/andre/construx/modules/project/controller/ProjectController.java:27–45` — HTTP adapter.
5. `construx/src/main/java/org/andre/construx/modules/project/service/ProjectService.java:31–45` — use-case and authorization boundary.

Continue with [[frontend/API Boundary]], [[backend/Security]], [[backend/Organizations and Access]] and [[backend/Persistence]].
