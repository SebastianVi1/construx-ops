# Construx: global project context

Read this first. It gives an AI assistant (or a new contributor) the big picture of Construx: what the product is, how the three repositories fit together, what exists today, and which decisions are still open. Snapshot as of 2026-10-25.

## 1. Product in one sentence

Construx is a multi-tenant SaaS that digitizes and centralizes the operations of construction companies. It connects companies, job sites (projects), workers, tasks, activities, architectural plans and finances in one platform.

The pitch: *"A digital operating system for construction companies: know what is happening on every site, who is involved, what is being done and how resources are being used."* The goal is to connect field operations with back-office management, not to be just an HR tool or just a project tracker.

### The problem

Construction information is scattered across spreadsheets, chat messages, documents and separate tools. It is hard to know who is working, on which site, doing what, which tasks are pending and how money is being spent.

### Core hierarchy

```
Company / Organization  →  Sites / Projects  →  People (staff and workers)
```

A company manages many sites and assigns different users and workers to each one. Data is isolated per organization (multi-tenant).

### Planned capabilities

| Area | What it covers |
|---|---|
| People | Worker profiles, roles and permissions, assigning workers to sites, managing organization members |
| Sites / projects | Create and manage sites, general project info, staff involved, activities and progress |
| Tasks and activities | Assign tasks to workers, see pending and completed tasks, see what is happening on a site |
| On-site operations | See where each employee is working; link workers and activities to **zones of a site**, drawn on top of **architectural plans / PDFs** (floors, areas). This is the main differentiator. |
| Finance | Record purchases and expenses, tie them to projects, show how money is used |
| CRM | Clients and other project stakeholders (the landing page shows a client pipeline) |
| Overview dashboard | Site status, active staff, activities, tasks, expenses and other KPIs |

### Conceptual user flow

The experience starts with a **user**, not with a company:

```
User
 ├── Sign up
 ├── Has an invitation to a site ──> joins that project
 └── No invitation
       ├── Owner / Manager ──> sets up a site (and the organization)
       └── Worker ──> completes their profile
```

Later a user can belong to an organization, take part in one or more sites, and hold different roles and permissions depending on the context.

```
                     CONSTRUX
                        │
         ┌──────────────┼──────────────┐
      COMPANY         SITES          PEOPLE
         └──────────────┼──────────────┘
                 ON-SITE OPERATIONS
         ┌──────────────┼──────────────┐
       Tasks        Activities      Location
         └──────────────┼──────────────┘
                    INFORMATION
                 ┌──────┴──────┐
              Finance         CRM
```

## 2. Repositories

All three live under GitHub user `SebastianVi1`.

| Repo | Role | Stack |
|---|---|---|
| `construx-backend` | REST API, auth, domain model | Java 21, Spring Boot 4.1, Maven wrapper, Spring Web MVC, Spring Data JPA, Spring Security (OAuth2 client for Google + resource server for the app's own JWT), Spring Mail, PostgreSQL, Lombok. Tests: JUnit 5, MockMvc, H2. |
| `construx-dashboard` | The web app users log into | React 19, TypeScript, Vite 8, Bun (package manager and `bun test`), react-router, axios, zod, React Compiler. i18n EN/ES. |
| `construx-landing-page` | Marketing site for early access | Astro 7, Tailwind CSS 4, GSAP animations, EN/ES. Fonts: Inter, Space Grotesk, JetBrains Mono. |

### How they connect

- The dashboard calls the backend under `/api`. In development the Vite dev server proxies `/api` to `localhost:8080`; the backend's `FRONTEND_URL` defaults to `localhost:5173`.
- The landing page is static and does **not** call the backend yet. Its "Get Early Access" form has nowhere to store requests.

## 3. Backend

### Layout

Modular monolith in `src/main/java/org/andre/construx`:

- `modules/identity`: users, credentials, sessions, email verification, Google login
- `modules/organization`: organizations, memberships, roles, permissions, invitations
- `modules/project`: projects, project access, goals, activities
- `shared`: config, security, validation, error handling

Intended architecture: controllers → services (business logic) → Spring Data repositories. Entity invariants live inside the model classes.

### Auth (the most finished part)

- Register with email verification, login with password or Google, refresh, logout, change password.
- App-issued JWT `access_token` (15 min) and opaque `refresh_token` (30 days), both HttpOnly, Secure, SameSite=Lax cookies.
- Every request checks a DB `auth_session` row, so logout and account disabling apply immediately. Refresh tokens rotate; reuse revokes the session.
- CSRF enforced on all unsafe requests (token from `GET /api/auth/csrf`).
- Google login creates the same app session; linking Google to an existing verified password account is supported.
- Full contract in the repo: `auth.md` and `docs/security.md`.

### Domain model

```
UserAccount ─< OrganizationMembership >─ Organization ─< OrganizationRole ─< Permission(action, scope)
                     │                        │
                     └─< ProjectAccess >─ Project ─< Goal ─< Activity (assignee = ProjectAccess)
Organization ─< OrganizationInvitation (email, token hash, role, expiry)
```

- Vision term → code term: Company = `Organization`, Site = `Project`, staff on a site = `ProjectAccess`, task/activity = `Activity` (grouped under a `Goal`).
- Permission actions: `MANAGE_ORGANIZATION`, `MANAGE_ROLES`, `MANAGE_MEMBERS`, `VIEW/MANAGE_PROJECT`, `VIEW/MANAGE_GOAL`, `VIEW/MANAGE_ACTIVITY`. Scopes: `OWN`, `PROJECT`, and organization-wide.
- `Activity` has a name, assignee, due date, status (`TODO`, `IN_PROGRESS`, …) and `completedAt`.
- `DomainAuthorization` can check membership, role permission, project access and scope. It has tests but **nothing calls it yet**.

### Exposed today

Only the auth endpoints and a placeholder `GET /api/test`. Organizations, roles, projects, goals and activities exist as JPA entities with **no services or endpoints** (only a few repositories).

Branch `feat/user-profile` (unmerged) adds `UserProfile` (full name, E.164 phone) with `GET`/`PUT /api/profile`. It also contains a test-only `Startup.java` that must be removed before merging.

## 4. Dashboard

- Routes: `/`, `/login`, `/register`, `/verify-email`, `/auth/complete` (after Google OAuth), `/account`.
- Auth is fully wired to the backend contract (login, register, Google, email verification, session handling).
- The home view (sites and an activity feed) uses **hardcoded mock data**.
- An onboarding modal after registration asks "What best describes your role?" (Owner/Developer, General contractor, Architect/Engineer, Subcontractor). Answers are stored **only in `localStorage`**; no backend endpoint exists for them. The questions are config-driven (`src/features/onboarding/questions.ts`) so they can later come from the backend.
- Reusable pieces: a form system (`components/form`) and an accessible modal plus question modal (`components/modal`).
- Design tokens live in `design.md`: a precise, blue-led look (primary `#175CD3`, ink `#14263D`, canvas `#F5F8FC`), IBM Plex Sans and IBM Plex Mono.

## 5. Landing page

- Single landing page built from sections: Header, Hero, ProblemSolution, Features, HowItWorks, Benefits, Contact, Footer.
- Feature mockups with demo data: Dashboard, Plan (activities pinned to plan areas), TaskBoard, Gantt, Workforce, Finance, CRM pipeline.
- Visual identity: a "blueprint" style with survey-drawing motion (dimension lines, crosshair, plan-sheet reveals). The chosen logo is the "a-brace" mark; alternative concepts are kept under `src/assets/logo/`.
- Dev server: `astro dev --background` (see the repo's `CLAUDE.md`).

## 6. Status vs vision

Legend: ✅ exists · 🟡 partial (modeled without API, or incomplete) · ❌ missing

| Capability | Status | Notes |
|---|---|---|
| User accounts (signup, login, Google) | ✅ | Password recovery is missing |
| Multi-tenant isolation | 🟡 | `Organization` is the root, but no business endpoints exist to scope yet |
| Organization CRUD | 🟡 | Entity only |
| Roles and permissions | 🟡 | Modeled and evaluated, not enforced; no default roles (Owner, Manager, Worker) |
| Member management and invitations | 🟡 | Entities only; invitations target the organization, not a site |
| Assign workers to sites | 🟡 | `ProjectAccess`, no API |
| Worker profiles | 🟡 | Only the unmerged `feat/user-profile` (name, phone); no trade or specialty |
| Sites / projects | 🟡 | `Project` has only a name; no address, dates, status, client or budget |
| Activities, tasks and progress | 🟡 | `Goal` → `Activity`, no API, no progress calculation |
| Onboarding flow (invited vs Owner vs Worker) | ❌ | Dashboard asks the role but keeps it in `localStorage` |
| Worker location on site | ❌ | No check-in, attendance or location |
| Plans / PDFs, zones, floors | ❌ | No entities and no file storage |
| Finance (purchases, expenses) | ❌ | |
| CRM | ❌ | |
| Overview dashboard with real data | ❌ | UI exists with mock data |
| SaaS plans and billing | ❌ | |
| Early-access waitlist endpoint | ❌ | Landing form has no backend |

## 7. Known technical issues

- **CORS is not really active.** `CorsConfigurer` lacks `@Configuration`, maps `/api/` instead of `/api/**`, hardcodes `localhost:5173`, and Security never calls `.cors()`. Dev works only through the Vite proxy. Production needs a proper CORS setup or a same-site reverse proxy.
- **Schema management:** `ddl-auto=update` with `show-sql=true`, no Flyway/Liquibase (one hand-written `docs/security-migration.sql`).
- **The user table is named `"user-account"`** (hyphen), which forces quoting in SQL. Rename to `user_account` before real data exists.
- **`ConstruxApplicationTests` loads the full context against the configured PostgreSQL** and can alter its schema. It should use the H2 test profile.
- `RestControllerTest` is a placeholder endpoint in `main`.
- Open items from commit history: rate limiting on auth endpoints, and enforcing domain authorization on business endpoints.
- No CI and no deploy config (Docker, env-based settings) yet.

## 8. Open design decisions

1. **Task vs Activity.** RESOLVED (ADR 0001): same thing. Task (UI) = `Activity` under a `Goal` (phase), assigned to a `ProjectAccess`. A zone concept, if needed, comes with plans and zones (item 6).
2. **Invitations to a site.** RESOLVED (`.agents/contracts/v1-api.md` §3): the invitation targets the organization with a role and an optional `project`; accepting creates the membership and, if a project is set, a `ProjectAccess`, in one transaction.
3. **Default roles.** RESOLVED (contract §8, ADR 0002): five seeded roles per organization (Owner, Administrator, Member, Worker, Finance placeholder) with a fixed permission matrix. The dashboard's onboarding answers do not map to roles: they are a descriptive hint (`intent`, `businessType`) stored via `PUT /api/onboarding`; roles come only from creating an organization (Owner) or from an invitation. Sub-questions still open for the user are listed in contract §10 (Q1, Q2, Q7).
4. **Worker vs user.** v1 stance (ADR 0003): assignees must have an account; no account-less workers and no public marketplace. Revisit when a real crew-without-login need appears.
5. **Location model.** Start with check-in/attendance per zone, or real-time GPS? Check-in per zone is the suggested first step.
6. **Plans and zones.** How zones are drawn on a PDF plan (polygons over a page, floor levels), and where files are stored (S3 or similar).
7. **Production topology.** CORS vs a reverse proxy serving dashboard and API on the same site.
8. **Billing.** Plan/subscription model per organization (e.g. Stripe) and limits per plan.

## 9. Suggested roadmap

1. Onboarding and organization API: create an organization (seed default roles), list my organizations, invite by email (to the organization and optionally a site), accept an invitation, save the onboarding role.
2. Sites, people and activities/tasks API, with `DomainAuthorization` in the service layer and every query filtered by organization. Extend `Project` (address, dates, status). Replace the dashboard's mock data.
3. Worker profile: merge `feat/user-profile` without `Startup.java` and add trade and job data.
4. Housekeeping: Flyway baseline, rename the user table, fix CORS, rate limiting, H2 for the context test, CI running `./mvnw test`.
5. Plans and zones: upload PDFs, define zones/floors, link activities and workers to zones.
6. Finance: expenses and purchases per site, with category, supplier and receipt.
7. CRM: clients and stakeholders linked to sites.
8. On-site location: check-in/attendance per zone.
9. SaaS: plans and subscriptions, and a waitlist endpoint for the landing page.

## 10. Conventions

- **Languages:** the UI is bilingual (English and Spanish) in both the dashboard and the landing page; add every user-facing string in both. Code, identifiers and commit messages are in English.
- **Backend:** four-space indentation, `PascalCase` classes, `camelCase` members, descriptive domain names (`OrganizationMembership`, `ProjectAccess`). Keep invariants in entities and cross-module code in `shared`. Test classes end in `*Test` or `*Tests` with behavior-focused method names. No formatter configured; match nearby code. Commands: `./mvnw compile`, `./mvnw test`, `./mvnw spring-boot:run`.
- **Commits (backend):** short, imperative, lowercase subjects, e.g. `add Activity and Goal models with validation`. The dashboard and landing page use Conventional Commits, e.g. `feat(onboarding): …`.
- **Dashboard:** feature folders under `src/features/<feature>`, shared UI under `src/components`, tests next to code (`*.test.ts`, run with `bun test`). Follow the tokens in `design.md`.
- **Landing page:** sections in `src/components/sections`, mockups in `src/components/mockups`, primitives in `src/components/ui`.
- **Security:** never commit `.env` files or credentials; OAuth client values come from environment variables. Every new business endpoint must enforce tenant scoping and `DomainAuthorization`.

## 11. Further reading

- `notes/backend-map.md`: detailed technical map of the backend.
- `notes/backend-vs-vision.md`: capability-by-capability comparison (in Spanish).
- Backend repo: `AGENTS.md`, `auth.md`, `docs/security.md`.
- Dashboard repo: `design.md`, `src/components/form/README.md`, `src/components/modal/README.md`.
