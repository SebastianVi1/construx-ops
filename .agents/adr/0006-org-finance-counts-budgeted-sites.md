# Company finance totals count only budgeted, non-archived sites

Status: proposed (2026-11-04)

The company finance view (`construx/docs/org-finance.md`) adds up budgets and spending across Sites. Every company total (budget, spent, remaining, execution %, spending by category and by month) counts only Sites that have a budget and are not archived. Sites without a budget are still listed one by one with their own spending and a "no budget" status.

Why: the totals are only meaningful if they reconcile. Spending by category must add up to total spent, and the monthly bars are drawn against the budget line, so both must cover the same Sites as the budget. Counting the spending of unbudgeted Sites would make execution % overstate how much of the budget is used. Archived Sites are left out because the Site list hides them by default and the view is about current operations.

Considered and rejected: counting all spending in spent and by category while the budget counts only budgeted Sites (totals that do not reconcile and an inflated execution %); including archived Sites (old, closed spending dominates the burn chart of the current year).

Consequences: money spent on an unbudgeted or archived Site does not appear in company totals or the monthly chart; it is visible only in that Site's row (unbudgeted) or its own page (archived). The UI should say so near the totals. Changing either rule later changes numbers users already rely on, so it needs a new ADR.
