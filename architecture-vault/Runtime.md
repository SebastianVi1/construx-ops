---
tags: [architecture, architecture]
verified: 2026-10-28
---
# Runtime boundaries and verification limits

The inspected source identifies three applications: Spring Boot API, React dashboard and Astro landing. PostgreSQL is the backend persistence target.

No deployment manifest was verified in this checkout. Do not infer a production proxy, host, container topology, network or running service from the repository name. Source inspection is not an operational health check.

## Connections
- [[backend/Backend]]
- [[backend/Persistence]]
- [[frontend/Frontend]]
- [[frontend/Landing]]
- [[Questions]]

## Source evidence
Paths are relative to the repository root (the parent of this vault). Line references describe the inspected working tree.

- `construx/pom.xml` — lines 5–44.
- `construx-dashboard/package.json` — lines 6–42.
- `construx-landing-page/package.json` — lines 8–22.
