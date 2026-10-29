---
tags: [architecture, backend]
verified: 2026-10-28
---
# Budgets and expenses

BudgetAllocation expresses the nested allocation rules across project, phase and task. ExpenseService handles actual spending, with project/task links and permission checks. Allocating a budget and recording a cost are different operations.

Follow the financial API separately from material-price observations: a supplier price is not automatically a project expense. Frontend expense comments describe USD; pricing currency has a separate unresolved documentation discrepancy.

## Connections
- [[backend/Projects]]
- [[backend/Tasks and Team]]
- [[backend/Pricing]]
- [[frontend/Finance and Materials]]
- [[Questions]]

## Source evidence
Paths are relative to the repository root (the parent of this vault). Line references describe the inspected working tree.

- `construx/src/main/java/org/andre/construx/modules/project/model/BudgetAllocation.java` — lines 7–43.
- `construx/src/main/java/org/andre/construx/modules/finance/service/ExpenseService.java` — lines 28–33.
- `construx-dashboard/src/features/finance/financeApi.ts` — lines 5–31.
- `construx/src/main/resources/db/migration/V18__expense_task_link.sql` — lines file.
