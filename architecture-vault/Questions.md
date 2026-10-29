---
tags: [architecture, architecture]
verified: 2026-10-28
---
# Open questions and evidence limits

**Pricing currency discrepancy:** frontend pricingApi comments say USD including IVA; backend PriceObservation comments say MXN including IVA. This is a verified disagreement between comments, not proof of actual conversion or incorrect stored amounts. Confirm the intended unit and then inspect formatting, API documentation and stored data before fixing anything.

**Deployment:** production hosting and runtime wiring remain unverified.

**Scope:** this is a source-grounded conceptual map, not an exhaustive class catalogue or a certification that every permission, migration and browser flow works at runtime.

## Connections
- [[backend/Pricing]]
- [[frontend/Finance and Materials]]
- [[Runtime]]

## Source evidence
Paths are relative to the repository root (the parent of this vault). Line references describe the inspected working tree.

- `construx-dashboard/src/features/materials/pricingApi.ts` — lines 13.
- `construx/src/main/java/org/andre/construx/modules/pricing/model/PriceObservation.java` — lines 17–19.
