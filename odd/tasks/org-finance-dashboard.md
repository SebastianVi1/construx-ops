# Organization Finance Dashboard
Branch: feat/org-finance-dashboard
Delivery: single-pr
Test runners: backend `./mvnw test`, frontend `bun run lint && bun run build && bun test`

## Specs

**S1 — Backend: `GET /api/organizations/{orgId}/finance/summary`**
Requires `VIEW_BUDGET` (ORGANIZATION scope). Returns:
```json
{
  "totalBudget": 500000.00,
  "totalSpent": 320000.00,
  "totalRemaining": 180000.00,
  "executionPct": 64.0,
  "sitesOverBudget": 1,
  "sitesNearLimit": 2,
  "byCategory": [
    { "category": "MATERIALS", "amount": 180000.00 }
  ],
  "sites": [
    {
      "siteId": "uuid",
      "siteName": "Torre Norte",
      "allocatedBudget": 200000.00,
      "spent": 190000.00,
      "remaining": 10000.00,
      "executionPct": 95.0,
      "status": "NEAR_LIMIT"
    }
  ]
}
```
- `status` per site: `OK` (< 80%) | `NEAR_LIMIT` (≥ 80%) | `OVER_BUDGET` (> 100%) | `NO_BUDGET` (allocatedBudget null)
- Sites with null `allocatedBudget` are included with status `NO_BUDGET`; excluded from totalBudget/totalSpent/totalRemaining
- `totalBudget` = sum of sites with non-null allocatedBudget
- `executionPct` = (totalSpent / totalBudget) * 100, null if totalBudget = 0

**S2 — Backend: `GET /api/organizations/{orgId}/finance/expenses/monthly?from=YYYY-MM-DD&to=YYYY-MM-DD`**
Requires `VIEW_BUDGET`. Returns:
```json
{
  "totalBudget": 500000.00,
  "months": [
    { "month": "2026-01", "spent": 42000.00 }
  ]
}
```
- `month` is `YYYY-MM` string
- Months with no expenses are included with `spent: 0` (fill gaps)
- `from` defaults to January 1 of current year, `to` defaults to today
- `totalBudget` same calculation as S1

**S3 — Permission guard**
Both endpoints use the existing `MembershipGuard` + `DomainAuthorization` pattern (404 for non-members, 403 for missing VIEW_BUDGET). Follow `ExpenseService` as the reference.

**S4 — Frontend: `orgFinanceApi.ts`**
Axios + Zod wrappers for S1 and S2. Follow `financeApi.ts` patterns (use `getJson`, `organizationPath` from `permissionsApi`).

**S5 — Frontend: `OrgFinancePage`**
Page composed of:
- `OrgFinanceKPIRow`: 4 KPI cards — total budget / total spent / remaining balance / execution %
  - "Remaining" card flips red when `totalRemaining < 0`
- `SiteFinanceTable`: table of all sites with status badge (green OK, yellow NEAR_LIMIT, red OVER_BUDGET, gray NO_BUDGET); click row → navigate to that site's finance tab: `/sites/:siteId?tab=budget`
- `BudgetBurnChart`: monthly bars + flat budget ceiling line (Recharts). Time selector: 3M / 6M / 1Y (year in progress = default)
- `OrgCategoryChart`: donut/pie chart of expenses by category
- Red banner at top of page if any site status is `OVER_BUDGET`, listing the site names

**S6 — Frontend: Routing**
- Add lazy route `/finance` → `OrgFinancePage` inside `WorkspaceLayout` in `App.tsx`
- Change the index route (`/`) from `WorkspaceHome` to `OrgFinancePage` (or redirect `/` → `/finance`)

**S7 — Frontend: Sidebar**
Add "Finance" / "Finanzas" sidebar entry pointing to `/finance` in the workspace sidebar (wherever other nav items like Sites, Members live). Use a chart or bar icon consistent with existing icons.

**S8 — i18n**
All user-facing strings bilingual EN/ES in `messages.ts`. No string literals in JSX.

**S9 — Alerts**
Yellow badge ≥ 80% (NEAR_LIMIT), red badge > 100% (OVER_BUDGET). Red banner lists site names if any OVER_BUDGET.

**S10 — Tests**
Backend: `OrgFinanceControllerTest` covering 200 responses, 403 without VIEW_BUDGET, 404 without membership.
Frontend: `src/tests/features/org-finance/orgFinanceApi.test.ts` covering Zod schema parsing for both endpoints.

## Tasks

| ID | Specs | Route | Status | Commit |
|----|-------|-------|--------|--------|
| T1 | S1, S2, S3, S10(backend) | delegated (backend-dev) | done | construx@f8e8fa5 |
| T2 | S4–S9, S10(frontend) | delegated (frontend-dev) | done | construx-dashboard@7b06b60 |

## Log

L1: "implementa el plan como gustes" — full implementation authorized. Plan: org-level finance dashboard. Backend: 2 new endpoints under /finance aggregating site budgets and expenses. Frontend: new /finance route as org landing + sidebar item. Tech: Spring Boot backend, React 19 + Recharts frontend.
