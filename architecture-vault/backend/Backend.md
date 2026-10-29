---
tags: [architecture, backend]
verified: 2026-10-28
---
# Backend architecture

The backend is a Spring Boot application organized by business modules, with controller, service, repository and model packages inside those modules. This is a descriptive modular-monolith view, not a claim of enforced hexagonal boundaries. Java 21 and Spring Data JPA are declared in Maven.

Controllers translate HTTP requests; services coordinate use cases and authorization; entities hold domain state; repositories provide persistence. These responsibilities are different even when they serve the same feature.

## Connections
- [[backend/Identity]]
- [[backend/Organizations and Access]]
- [[backend/Projects]]
- [[backend/Pricing]]
- [[backend/Finance]]
- [[backend/Persistence]]
- [[backend/Security]]

## Source evidence
Paths are relative to the repository root (the parent of this vault). Line references describe the inspected working tree.

- `construx/pom.xml` — lines 5–44.
- `construx/src/main/java/org/andre/construx/modules/project/controller/ProjectController.java` — lines 27–45.
- `construx/src/main/java/org/andre/construx/modules/project/service/ProjectService.java` — lines 31–45.
