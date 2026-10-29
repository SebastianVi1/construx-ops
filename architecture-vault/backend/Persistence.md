---
tags: [architecture, backend]
verified: 2026-10-28
---
# Persistence and schema

The backend uses Spring Data JPA with PostgreSQL. Current configuration uses Hibernate ddl-auto=validate and enables Flyway migrations under db/migration. Hibernate validates the schema; it is not configured here to create missing schema changes automatically.

Migration files are source evidence, not proof they ran against a deployed database. No database was started or queried for this documentation.

## Connections
- [[backend/Backend]]
- [[backend/Projects]]
- [[Runtime]]

## Source evidence
Paths are relative to the repository root (the parent of this vault). Line references describe the inspected working tree.

- `construx/pom.xml` — lines 32–119.
- `construx/src/main/resources/application.properties` — lines 1–10, 33–39.
