---
tags: [architecture, frontend]
verified: 2026-10-28
---
# Workspace and organization selection

Protected workspace composition is RequireAuth → OrganizationGate → WorkspaceLayout. OrganizationGate waits for organization state, exposes retry on failure and handles the no-organization case before rendering the workspace.

This gate provides a usable navigation context. It does not confer organization membership or project permissions on the server.

## Connections
- [[frontend/Routing and State]]
- [[backend/Organizations and Access]]
- [[frontend/Project Features]]

## Source evidence
Paths are relative to the repository root (the parent of this vault). Line references describe the inspected working tree.

- `construx-dashboard/src/App.tsx` — lines 33–60.
- `construx-dashboard/src/features/organizations/OrganizationGate.tsx` — lines 8–40.
