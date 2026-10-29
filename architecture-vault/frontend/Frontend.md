---
tags: [architecture, frontend]
verified: 2026-10-28
---
# Dashboard architecture

The dashboard is a React 19 and TypeScript SPA built with Vite. React Router selects screens; feature folders organize domain UI and API adapters. Axios and Zod appear in the dependency set.

Read the app from its entry point, then providers, routes, a feature API client and the matching backend controller. The public landing page is a separate application.

## Connections
- [[frontend/Routing and State]]
- [[frontend/Workspace]]
- [[frontend/Project Features]]
- [[frontend/Finance and Materials]]
- [[frontend/Authentication]]
- [[frontend/Landing]]
- [[backend/Backend]]

## Source evidence
Paths are relative to the repository root (the parent of this vault). Line references describe the inspected working tree.

- `construx-dashboard/package.json` — lines 6–42.
- `construx-dashboard/src/main.tsx` — lines 12–28.
- `construx-dashboard/src/App.tsx` — lines 33–60.
