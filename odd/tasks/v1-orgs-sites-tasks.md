# v1: onboarding, organizations, sites, tasks
Objective: first usable flow, registration -> organization -> site -> invited worker -> assigned task.
Branch: construx `feat/organizations` (backend), dashboard branch TBD. Delivery: ask-on-risk. Runner: `sh ./mvnw test` (JDK 21), `bun test`.
Contract: .agents/contracts/v1-api.md (binding). Plan: ~/.claude/plans/help-me-creating-a-quizzical-frost.md

## Specs
S1. Marketplace = internal assignment only; tenant isolation per Organization.
S2. Registration intent: "I run a company" (creates Organization, user = Owner) vs "I'm a worker / was invited". Stored in `UserOnboarding` (`GET`/`PUT /api/onboarding`).
S3. Task = `Activity` under `Goal` under `Project`; assignee = `ProjectAccess`; assignee required.
S4. Seeded roles per organization: Owner, Administrator, Member (office staff, manages goals), Worker (field, PRJ view, OWN manage), Finance (placeholder). Matrix: contract section 8.
S5. Only Owner edits organization details. Worker sees all tasks on assigned sites.
S6. Existing DB is disposable: no backfill; schema changes via Flyway V4+.

## Tasks
- [x] T1 (S4) seeded roles in `Organization` constructor + V4 migration. inline. RED: compile failure `isSeeded`; GREEN 9/9. commit: construx "seed administrator, member, worker and finance roles..."
- [x] T1b (S4,S6) seeded roles moved to `seeded-roles.properties`, validated at load. commit: construx "load seeded roles from seeded-roles.properties"
- [x] T2 (S3,S5) `DomainAuthorization.scopeOf`. inline. RED: compile failure; GREEN 9/9. commit: construx "add DomainAuthorization.scopeOf..."
- [x] T3 (S2) `UserOnboarding` + `/api/onboarding` + V5 migration. inline. RED 3/4 failing; GREEN 4/4. commit: construx "add GET and PUT /api/onboarding..." (profile `trade` field deferred, see T3b)
- [x] T3b (S2) optional `trade` on `/api/profile` + V8; omitted keeps value. GREEN 198. commit: construx "add optional trade to the user profile"
- [x] T4 (S2,S4) invitations: entity+V6, mailer, create/list/revoke, accept (locked, one tx), rate limit, docs. inline. GREEN full suite 155 tests. commits: construx b75bd90, 03e5372, 97919ce, b6d933e + rate limit + docs
- [x] T5 (S3,S5) sites (V7), site access, goals, tasks + /activities/mine, MembershipGuard, docs/projects.md. inline, RED then GREEN per slice. GREEN full suite 196. commits: construx fe0934d..0b281b8
- [ ] T6 dashboard (EN/ES), delegated to frontend-dev per unit (trigger: long-session context backstop):
  - [x] U1 API client, onboarding intent to backend, create company, current organization. Parent re-ran lint 0 / build 0 / bun test 106 pass. commits: dashboard 8f3c182, 806e612
  - [x] T5b backend gap found in U1: `myRole` + `/me`, `/roles`, `/members` (contract section 2). inline, RED 5/5 then GREEN 203. commit: construx 7043aa3
  - [x] U2 sites, people on a site, invitations, permission gating. Parent re-ran lint 0 / build 0 (no chunk warning) / bun test 150 pass. commits: dashboard 71bc3ba, 7093156
  - [x] U2 fix (inline): sign-in lands on /sites directly, /account bookmark stays; removed AccountPage forwarding. lint 0 / build 0 / 149 pass. commit: dashboard f1da8cd
  - [x] T5c backend gap found in U2: PATCH project `clear` dates. RED 1 then GREEN 204. commit: construx 141f8c8
  - [x] U3 phases, task board, my tasks, accept invitation, role-based landing, ?next= return path. Parent re-ran lint 0 / build 0 / 193 pass; hardened safeReturnPath (tab/newline/backslash) RED->GREEN. commits: dashboard 78dc7f2, 931fb33
  - [x] T5d backend (from U3): goalName/projectName on task responses. RED 1 then GREEN 204. commit: construx a39ec38
  - [ ] Home page mock data: still unused/mock (`/` now routes to WorkspaceHome); decide remove or replace
  - [x] U4 silent refresh on 401 (single-flight, one retry per kind, no refresh on /auth/*) + return path across email verification. Parent reviewed refresh logic; lint 0 / build 0 / 208 pass. commit: dashboard (feat(auth) refresh)
- [ ] T7 housekeeping: rename "user-account" table, CI

## Log
L1 (user, 2026-10-26): "help me creating a plan to start implementing the app ide until now, we have auth created, have in mind we have backend (springboot) frontend (react) and help me start building the service using this context @.agents/CONTEXT.md make something to define what kind of user is when hes registering, and help me with the basic options like create a construction site project assign tasks, like a marketplace any questions are welocome.."
L2 (user): "i want owner, member, worker, administator, finance..."
L3: Prior commit on feat/organizations: "add organization create, list, get and rename" (pre-existing uncommitted work, committed first at user's choice).

L4 (user): "continue remember to test everything and make little commits"
L5 (user): "continue with the implementation dont cut off the sessions"
L6: Backend v1 API complete on construx feat/organizations (T1-T5, T3b). Full suite 198 tests green (ConstruxApplicationTests excluded: hits configured PostgreSQL). Next: T6 dashboard.
L7: Dashboard U1-U4 committed on construx-dashboard feat/organizations-ui. Pending: browser end-to-end run (needs user OK on which database), HomePage mock removal decision, CLAUDE.md/CONTEXT.md doc refresh, umbrella submodule pointers (user decision).
