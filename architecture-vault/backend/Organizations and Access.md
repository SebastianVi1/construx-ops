---
tags: [architecture, backend]
verified: 2026-10-28
---
# Organizations and access

Organization is the tenant boundary. OrganizationMembership joins a user to an organization and its role. ProjectAccess joins an organization membership to a project.

A user identity alone does not describe which organization or project they may act in. ProjectService documents the order: active membership, tenant-filtered resource lookup, then permission checks. Frontend route protection is not a replacement for these server-side checks.

## Connections
- [[backend/Identity]]
- [[backend/Projects]]
- [[backend/Security]]
- [[frontend/Workspace]]

## Source evidence
Paths are relative to the repository root (the parent of this vault). Line references describe the inspected working tree.

- `construx/src/main/java/org/andre/construx/modules/organization/model/Organization.java` — lines 33–50.
- `construx/src/main/java/org/andre/construx/modules/organization/model/OrganizationMembership.java` — lines 25–45.
- `construx/src/main/java/org/andre/construx/modules/project/service/ProjectService.java` — lines 31–45.
