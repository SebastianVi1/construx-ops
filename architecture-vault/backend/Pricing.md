---
tags: [architecture, backend]
verified: 2026-10-28
---
# Materials, suppliers and price observations

Pricing contains Material, Supplier and PriceObservation. An observation records a material price from a supplier on a date. The backend documents observations as immutable: correction means replacing the observation, not rewriting its historical meaning.

Controllers expose material and supplier operations plus recording, CSV import and deletion of observations. MaterialService and PriceImportService coordinate these use cases. This is a price catalogue, not evidence of a stock-control subsystem.

## Connections
- [[frontend/Finance and Materials]]
- [[backend/Finance]]
- [[backend/Organizations and Access]]
- [[Questions]]

## Source evidence
Paths are relative to the repository root (the parent of this vault). Line references describe the inspected working tree.

- `construx/src/main/java/org/andre/construx/modules/pricing/controller/MaterialController.java` — lines 26–74.
- `construx/src/main/java/org/andre/construx/modules/pricing/controller/PriceObservationController.java` — lines 29–68.
- `construx/src/main/java/org/andre/construx/modules/pricing/model/PriceObservation.java` — lines 17–45.
- `construx/src/main/java/org/andre/construx/modules/pricing/service/PriceImportService.java` — lines 101 onward.
