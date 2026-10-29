---
tags: [architecture, frontend]
verified: 2026-10-28
---
# Routing and provider state

The entry tree is StrictMode → BrowserRouter → LocaleProvider → ThemeProvider → AuthProvider → OnboardingProvider → OrganizationsProvider → App. Provider order makes authentication available to organization and onboarding state.

App defines guest screens and protected workspace routes. RequireAuth handles loading and redirects unauthenticated users with a return path. GuestOnly redirects authenticated users to a safe next route. These are navigation decisions; backend security still decides whether data access is allowed.

## Connections
- [[frontend/Frontend]]
- [[frontend/Authentication]]
- [[frontend/Workspace]]

## Source evidence
Paths are relative to the repository root (the parent of this vault). Line references describe the inspected working tree.

- `construx-dashboard/src/main.tsx` — lines 12–28.
- `construx-dashboard/src/App.tsx` — lines 33–60.
- `construx-dashboard/src/features/auth/RouteGuards.tsx` — lines 21–45.
