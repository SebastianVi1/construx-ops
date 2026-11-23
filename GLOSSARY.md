# Construx

Construx digitizes the operations of construction companies: their sites, people, tasks and the costs of building.

## Prices

The terms in this section describe a proposed future catalog. The current application only keeps a placeholder `/prices` page; it has no pricing services or stored catalog.

**Catalog**:
A company's own list of everything building costs it, imported from the cost database it holds a licence for or typed by hand; a company has exactly one Catalog and never sees another company's.
_Avoid_: Price list, database, ConstruBASE (the licensed source, not the Catalog itself)

**Resource**:
One entry of the Catalog with a code and a Unit, which may have a current Cost: a Material, a Labor category, a Gang, an Equipment rate or a Work item.
_Avoid_: Item, insumo (for Work items), product, article

**Material**:
A Resource the company buys to build, such as a bag of cement or a steel bar; its Cost is what one Unit of it costs.
_Avoid_: Product, item, article, supply

**Supplier**:
A business the company buys Materials from, as named in the Catalog; two branches with different prices are two Suppliers.
_Avoid_: Vendor, store, provider

**Cost**:
What one Unit of a Resource costs the company when a Cost is recorded, in Mexican pesos; for a Work item it is worked out from its Unit price analysis, for any other Resource it is the latest Cost history entry.
_Avoid_: Price (that is what the company sells at), rate, tariff

**Cost history entry**:
One Cost of a Resource from the moment it was recorded until the next entry, with where it came from (an import, a hand edit or a wage recalculation) and who recorded it; entries are never changed or backdated.
_Avoid_: Price observation, quote, revision

**Work item**:
A Resource that is a unit of finished work, such as one square meter of block wall, whose Cost is the sum of its Unit price analysis.
_Avoid_: Concept (in English UI), task, activity, precio unitario (that is the selling price)

**Unit price analysis**:
The recipe of a Work item, Gang or other composite Resource: which Resources it uses, in what quantity or at what output per day, and therefore what it costs.
_Avoid_: Matrix (in English UI), bill of materials, breakdown

**Labor category**:
A Resource for one trade or position, such as peón or oficial albañil, with the daily wage agreed with the worker and the Real wage it costs the company.
_Avoid_: Role, position, worker, Crew

**Gang**:
A Resource that is a standard combination of Labor categories priced together for Unit price analyses, such as one oficial with one peón; a Gang is a cost figure in the Catalog, while a Crew is a group of real people on the Team page.
_Avoid_: Crew (real people), squad, team

**Equipment rate**:
A Resource for a kind of machine or tool with an Hourly cost, such as a 350 L mixer; an Equipment rate prices a kind of machine, while Equipment is a specific machine the company owns.
_Avoid_: Equipment (the physical machine), machinery, rate card

**Hourly cost**:
The Cost of using an Equipment rate for one hour, covering ownership, upkeep, fuel and operator.
_Avoid_: Rental, daily cost, tariff

**Family**:
The group a Resource is filed under in the Catalog, such as aceros or cemento y agregados.
_Avoid_: Category, class, type (that is Material, Labor, Equipment or Work item)

**Unit**:
The measure a Resource is counted and costed in, such as m², kg, jornada or hora.
_Avoid_: UoM, measure

**FASAR parameters**:
The yearly figures the company uses to turn a daily wage into a Real wage: social security and housing contributions, the UMA and minimum wage, paid and unworked days, bonuses and other charges.
_Avoid_: Factors, settings, FSR (that is the resulting factor)

**Real wage**:
What one day of a Labor category really costs the company: the daily wage times the real wage factor given by the FASAR parameters.
_Avoid_: Salary, wage (alone), daily rate, cost (alone)

**Labor rate**:
The daily amount one person costs on one Site: either the Real wage of a Labor category, which follows the Catalog, or a fixed amount negotiated with that person, which does not.
_Avoid_: Salary, wage, pay rate, rate (alone)

**Accrued labor cost**:
The labor a Site has consumed so far: one Labor rate for every day a person checked in on it, counted against the Site's budget beside recorded Expenses but never recorded as one.
_Avoid_: Payroll, wages paid, labor expense

**Estimate** (phase 2):
A priced proposal for a Site made of Sections and Work items with quantities, with overheads and profit added to the Costs; an Estimate is what the company offers to charge, while a Budget is what it allows itself to spend.
_Avoid_: Budget, presupuesto (in English UI), quote, bid

**Section** (phase 2):
A heading of an Estimate that groups Work items, such as preliminares or cimentación, possibly nested.
_Avoid_: Partida (in English UI), Phase, chapter, WBS

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

**Member**:
A person who belongs to a company, whether or not they are assigned to any Site; the company's members are listed under People.
_Avoid_: Team (for the whole company), employee, user, staff

**Organization role**:
The named set of Permissions a member holds in a company, such as Administrator, Worker or a company's own "Foreman with prices"; each member holds exactly one.
_Avoid_: Task role, position, profile

**Permission**:
One action a role allows, such as managing plans, at one reach: the member's own Tasks, the Sites they are assigned to, or the whole company; anything a role does not grant is denied.
_Avoid_: Right, privilege, deny rule

**Owner role**:
The Organization role of the company's creator, which always holds every Permission and can never be edited, given to anyone else or taken away.
_Avoid_: Admin, superuser

**Built-in role**:
An Organization role every new company starts with, such as Administrator or Worker; a company may change its Permissions and later restore the defaults.
_Avoid_: Seeded role (in the UI), system role, default role

**Custom role**:
An Organization role a company creates itself, from scratch or by duplicating another role.
_Avoid_: User role, personal role

**Team**:
The people of a Site assigned to one Task; a Task always has at least one person in its Team.
_Avoid_: Crew (for the whole team), assignee (for the group), Team (for all of a company's Members)

**Crew**:
A named, reusable group of company members with one leader, kept on the Team page and assigned together to a floor plan zone; unlike a Team it belongs to the company, not to one Task.
_Avoid_: Team (for this group), squad

**Equipment**:
A machine or tool of the company (an excavator, a mixer) that can be assigned to a floor plan zone; never people.
_Avoid_: Team, crew

**Task role**:
The position a person holds in one Task's Team: Lead, Foreman or Crew, in that order of seniority.
_Avoid_: Organization role, rank

**Lead**:
The one person who answers for a Task; the Lead may record Expenses on that Task and see its spending.
_Avoid_: Owner, manager, responsible

**Expense**:
Money spent on a Site, optionally charged to one Task, which reduces the Site's remaining budget.
_Avoid_: Cost, purchase, payment

**Budget execution**:
How much of a budget has been spent, as a percentage of it.
_Avoid_: Consumption, usage

**Budget status**:
Where a Site stands against its budget: within budget, near the limit (80 % or more spent), over budget, or without a budget.
_Avoid_: Health, alert level

**Site Report**:
A persistent PDF snapshot of a Site's budget, expenses, phase progress, and team, generated at a point in time by an authorized member and shared across all Site members.
_Avoid_: Completion report, closing ticket, informe final, project report

## Floor plan pins

**Pin**:
A spot marked on a floor plan with photos attached; it is either an Issue or a Progress photo.
_Avoid_: Marker, annotation, note

**Issue**:
A Pin for a defect or pending item on site, assigned to one person and tracked from open, to resolved, to closed.
_Avoid_: Task (it is not planned work), ticket, snag, incident

**Progress photo**:
A Pin that only records how the work looked at that spot on a date; it has no status and no assignee.
_Avoid_: Issue, evidence, attachment

## Attendance

**Check-in**:
One person recorded as present on a Site at a moment, optionally in a floor plan zone, made by that person or by someone answering for them.
_Avoid_: Clock-in, presence, roll call (for the record)

**Attendance**:
Who is on a Site on one day, built from that day's Check-ins; a person expected in a zone with no Check-in counts as absent.
_Avoid_: Timesheet, payroll, headcount
