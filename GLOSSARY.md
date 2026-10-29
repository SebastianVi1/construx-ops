# Construx

Construx digitizes the operations of construction companies: their sites, people, tasks and the costs of building.

## Material prices

**Material**:
A product a company buys to build, identified by its name, unit of measure and brand (for example "Cemento gris 50 kg, saco, Cemex").
_Avoid_: Product, item, article

**Supplier**:
One store or branch where Materials are sold; two branches of the same chain are two Suppliers, because their prices differ.
_Avoid_: Vendor, store, provider

**Price observation**:
The price of one Material at one Supplier on one date, as the company saw it on a shelf, ticket or quote.
_Avoid_: Quote, listing, offer

## Sites and tasks

**Site**:
One construction project of a company, with its own people, phases, budget and expenses.
_Avoid_: Project (in the UI), job, work

**Phase**:
A stage of a Site with its own dates, grouping the Tasks done in it.
_Avoid_: Goal (in the UI), milestone, stage

**Task**:
One piece of work inside a Phase, with dates, a status and a Team.
_Avoid_: Activity (in the UI), job, ticket

**Organization role**:
What a member is allowed to do across the company's Sites, such as Administrator, Member, Worker or Finance.
_Avoid_: Task role, position

**Team**:
The people of a Site assigned to one Task; a Task always has at least one person in its Team.
_Avoid_: Crew (for the whole team), assignee (for the group)

**Task role**:
The position a person holds in one Task's Team: Lead, Foreman or Crew, in that order of seniority.
_Avoid_: Organization role, rank

**Lead**:
The one person who answers for a Task; the Lead may record Expenses on that Task and see its spending.
_Avoid_: Owner, manager, responsible

**Expense**:
Money spent on a Site, optionally charged to one Task, which reduces the Site's remaining budget.
_Avoid_: Cost, purchase, payment
