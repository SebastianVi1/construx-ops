---
tags: [architecture, frontend]
verified: 2026-10-28
---
# Financial UI and materials catalogue

financeApi models project expense data; pricingApi models materials, suppliers and recorded prices, including latest-price comparisons. These are separate domains despite both involving money.

Money crosses the API as decimal strings in the inspected schemas. Do not resolve the pricing currency discrepancy by changing a label alone: confirm the intended contract first. Hidden financial fields and zero amounts have different meanings.

## Connections
- [[backend/Finance]]
- [[backend/Pricing]]
- [[frontend/API Boundary]]
- [[Questions]]

## Source evidence
Paths are relative to the repository root (the parent of this vault). Line references describe the inspected working tree.

- `construx-dashboard/src/features/finance/financeApi.ts` — lines 5–31.
- `construx-dashboard/src/features/materials/pricingApi.ts` — lines 13–45.
- `construx-dashboard/src/features/goals/goalsApi.ts` — lines 6–44.
