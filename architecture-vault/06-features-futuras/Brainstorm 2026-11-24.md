# Feature brainstorm: 2026-11-24

↑ [[INDEX]] · [[Backlog]]

Product trio session (PM, Designer, Engineer) for Construx as it stands today: auth, companies and roles, sites, phases and tasks, Gantt, budgets and expenses, attendance with daily labor cost, floor plans with zones and pins, crews and equipment, documents, PDF site report. The home view is still mock data.

**Assumed objective:** get field staff (residents, superintendents, workers) using Construx **every day**, not only office staff once a week, and give owners a reason to pay.
**Segment:** small and mid-size construction companies in Mexico and LatAm (Spanish-first).
**Outcomes:** daily active members per site, sites with activity on most workdays, retention after the first site.

## 1. Ideas by perspective

### Product Manager (business value)
1. **Auto-drafted site log (bitácora de obra).** Each evening, draft the day's log from attendance, finished tasks, new pins, expenses and photos; the resident edits and signs it. Mexican public works require a bitácora, and most companies keep one on paper anyway.
2. **Client progress portal.** A read-only link (or guest role) where the client sees progress, photos and the signed logs. Each client who sees it is a lead for Construx.
3. **Progress billing (estimaciones).** Bill the client by measured progress per phase or task, with retention percentage and payment status. This connects field progress to cash.
4. **Cost overrun alerts.** Warn when a phase or task's spend plus accrued labor passes X% of its budget before X% of its work is done.
5. **Subcontractors and purchase orders.** Track subcontractor contracts and POs against the budget, so committed cost shows next to spent cost.

### Product Designer (experience)
1. **Field mode.** A phone-first view with three big actions: check in, take a photo or report an issue (it lands as a pin on the plan), and finish my task. Works with one hand and gloves on.
2. **Real "Today" home.** Replace the mock `HomePage` with what needs me today: overdue tasks, open pins on my sites, who checked in, budgets at risk.
3. **Plan timeline.** A slider on the floor plan that replays zone assignments, pins and finished tasks over time. It shows the main differentiator.
4. **Before and after photos on tasks.** A task can't be marked done without a photo if the site requires it. Photos then feed the log and the client portal.
5. **WhatsApp notifications.** Crews already coordinate on WhatsApp. Send assignment, due date and pin alerts there, with a deep link back.

### Software Engineer (technology and data)
1. **Activity feed from the audit trail.** `shared/audit` already records every write. Project it into a per-site and per-company feed. Notifications, the home view and the bitácora all start from it.
2. **Receipt capture with AI extraction.** Snap a receipt; a vision model extracts supplier, date, total and VAT into a draft expense. This uses the presigned S3 upload flow that already exists.
3. **Earned value metrics.** Phase and task budgets, completion dates and actual cost (expenses plus attendance labor) are already stored. Compute planned value, earned value, CPI and SPI per site.
4. **Offline-first field sync.** Queue check-ins, photos and pins locally (IndexedDB is already used by Excel) and sync them when there is signal again.
5. **Geofenced check-in.** Check the phone's location against the site address or polygon at check-in. This is a cheap first answer to the open "location model" decision.

## 2. Top 5 (prioritized)

| # | Idea | Alignment | Impact | Effort | Differentiation |
|---|---|---|---|---|---|
| 1 | Auto-drafted bitácora | High | High | Medium | High |
| 2 | Activity feed + Today home | High | High | Low–Medium | Medium |
| 3 | Field mode (PWA) with photo-to-pin | High | High | Medium–High | High |
| 4 | Earned value and overrun alerts | Medium–High | High (owners) | Low–Medium | Medium–High |
| 5 | Client progress portal | Medium | Medium–High (growth) | Medium | Medium |

### 1. Auto-drafted site log (bitácora de obra)
**What:** Each workday, Construx drafts the site's log from real data; the resident reviews, adds notes and signs; the signed log is locked, exported as a PDF and filed in Documents.
**Why it's on the list:** It turns admin work residents already do into a daily habit inside Construx. Every module that exists feeds into it: attendance, tasks, pins, expenses and reports. Generic project tools don't offer it, and in Mexico it has legal weight.
**Assumptions to validate:**
- Residents keep a daily log today (paper, Word or WhatsApp), and it takes them 20 minutes or more.
- A drafted log they only correct is better than a blank form, and they trust what was filled in for them.
- A signed digital log is accepted by clients and supervisors (private works first; public works use BESOP).

### 2. Activity feed and real "Today" home
**What:** Turn the audit trail into a feed per site and per company, then build the home page on it: my overdue tasks, open pins, today's check-ins and budgets at risk.
**Why it's on the list:** The home view is still mock data, so the first screen people see is empty. The data already exists, so the effort is low. The feed is also the base for notifications (backlog), the bitácora and the client portal.
**Assumptions to validate:**
- Managers open the dashboard to find out what changed, not to edit things.
- Audit events can be turned into readable EN/ES sentences without a second event model.
- Permission filtering per event (for example, expenses only for `VIEW_PRICES`/budget roles) can be done cheaply.

### 3. Field mode with photo-to-pin
**What:** A phone-first view (PWA first, Expo later) with check-in, "report an issue" (photo → pin on the current zone) and "finish my task", that keeps working without signal.
**Why it's on the list:** Floor plans with pins are the main differentiator, but they only pay off if the field feeds them. Adoption by workers and residents is the stated outcome. It also answers the open "PWA for field check-in" backlog item.
**Assumptions to validate:**
- Workers have smartphones with a camera and will use them on site. Check Android share and data plans.
- Signal on site is unreliable enough that offline support is needed in v1, or it can wait.
- Showing a pin on the plan is understood without training (test with five residents).

### 4. Earned value and overrun alerts
**What:** A per-site health panel (planned vs earned vs actual cost, CPI/SPI) with alerts when a phase is burning budget faster than it makes progress.
**Why it's on the list:** It gives owners (the buyers) a reason to pay, and it costs little because budgets, dates, completion and actual cost (with ADR 0009 labor) are already stored. It turns Finanzas from bookkeeping into decisions.
**Assumptions to validate:**
- Task completion is a good enough proxy for physical progress, or a "% complete" field per task is needed.
- Enough sites have budgets per phase and task (ADR 0006 already excludes sites without a budget).
- Owners act on an alert (email or WhatsApp) rather than ignore it.

### 5. Client progress portal
**What:** A guest link or guest role per site that shows progress, a photo timeline and signed logs, branded with the construction company's logo.
**Why it's on the list:** It makes the company look professional to its client, cuts down "how's it going?" calls, and puts Construx in front of new companies. It starts the CRM from the backlog with a small scope.
**Assumptions to validate:**
- Companies want clients to see progress (some may prefer to hide delays). Offer an "approve before publishing" step.
- A no-login link with an expiry is secure enough, or clients need accounts. This touches ADR 0003.
- Clients come back to the portal more than once.

## 3. Suggested next step
Run quick discovery interviews with 3–5 residents or superintendents on ideas 1 and 3 (daily log habits, phone use on site). In parallel, build idea 2: it is low risk and the base for 1, 4 and 5.
