# Construx v1 API contract

Status: proposed, 2026-10-26. Author: Lead Architect. Scope: onboarding intent, organizations, roles seeding, invitations, projects, goals, activities (tasks), project access. Backend Dev and Frontend Dev build against this document; contract changes go through the Architect.

Decisions behind it: ADR 0001 (Task = Activity), ADR 0002 (registration intent vs role), ADR 0003 (internal assignment only). Terms: Company = `Organization`, Site = `Project`, Phase = `Goal`, Task = `Activity`, site staff = `ProjectAccess`.

## 0. Conventions

- Base path `/api`. JSON, camelCase. IDs are UUIDs. Timestamps (`Instant`) are ISO-8601 UTC. Calendar dates (`LocalDate`) are `YYYY-MM-DD`.
- Authentication: existing HttpOnly cookies. All endpoints below require an authenticated session. Unsafe methods need the CSRF header (`GET /api/auth/csrf`). The caller is always `authentication.getName()`; no endpoint accepts a user id from the client.
- Errors: existing RFC 7807 `ProblemDetail` from `GlobalExceptionHandler` with a `code` property. Codes used: `VALIDATION_FAILED` 400 (with `errors` map), `INVALID_ARGUMENT` 400 (entity invariant, `IllegalArgumentException`), `UNAUTHORIZED` 401, `FORBIDDEN` 403, `NOT_FOUND` 404, `STATE_CONFLICT` 409 (`IllegalStateException`), `DATA_CONFLICT` 409 (unique constraint). No new codes in v1.
- Lists are plain JSON arrays, unpaginated in v1 (see open question Q6).
- `PATCH` is partial: absent field = unchanged. `null` is not accepted for required fields.

### 0.1 Tenant scoping and authorization algorithm (mandatory for every business endpoint)

Every endpoint under `/api/organizations/{organizationId}/...` carries the tenant in the path. The service layer (never the controller) does, in this order:

1. `requireActiveMember(userId, organizationId)`. Not an active member of that organization: **404 NOT_FOUND** (same as a missing organization, so ids cannot be enumerated). This is the existing pattern in `OrganizationService`.
2. Load every referenced resource with an organization-filtered query (for example `findByIdAndOrganizationId`, `findByIdAndProjectId...`). A resource that exists in another organization, or is not under the given parent in the path: **404 NOT_FOUND**. Never `findById` alone.
3. `DomainAuthorization.require(userId, organizationId, projectId, assigneeMembershipId, action)`. Denied (missing permission or scope): **403 FORBIDDEN**.
4. Mutate through entity methods that enforce invariants. Invariant violations surface as 400 (`IllegalArgumentException`) or 409 (`IllegalStateException`).

Rules for the arguments of `require`:

- `projectId`: pass the project whenever the operation concerns a project, goal or activity. `PROJECT` scope only passes if the caller has a `ProjectAccess` on it. Pass `null` for organization-level operations and for creating a project.
- `assigneeMembershipId`: pass the membership of the activity's current assignee **only** for `start` and `complete`. Pass `null` for every other operation, which makes `OWN` scope deny by construction (a Worker cannot create, edit, reassign or delete tasks).
- Permission is read from the database on each call, never from the JWT.

**Gap in current code (Backend Dev, `shared/security`)**: `require` is a yes/no gate and cannot filter lists. Add one read method:

```java
/** Scope the caller holds for an action in an organization, empty if none. Requires active membership. */
Optional<PermissionScope> scopeOf(UUID userId, UUID organizationId, PermissionAction action)
```

List endpoints call it: empty -> 403; `ORGANIZATION` -> all rows of the organization; `PROJECT` -> only rows whose project has a `ProjectAccess` for the caller's membership; `OWN` -> only rows assigned to the caller (activities only). List queries filter by organization in the query itself, not in memory.

### 0.2 Role summary used in the tables

`O` Owner, `A` Administrator, `M` Member, `W` Worker, `F` Finance. Full matrix in section 8.

---

## 1. Onboarding intent

Self-service, user-scoped (no organization, no `DomainAuthorization`; the row is keyed by the authenticated user id). It is a hint for the dashboard and analytics; it grants nothing (ADR 0002).

Storage: new identity-module entity `UserOnboarding` (PK = user account id via `@MapsId`, like `UserProfile`). Not a column on `UserProfile`, because profile columns `fullName` and `phoneNumber` are NOT NULL and a new user has no profile yet.

### GET /api/onboarding

200:
```json
{ "intent": null, "businessType": null, "updatedAt": null }
```
`intent`: `null | "RUN_COMPANY" | "WORKER_OR_INVITED"`. `businessType`: `null | "OWNER_DEVELOPER" | "GENERAL_CONTRACTOR" | "ARCHITECT_ENGINEER" | "SUBCONTRACTOR"` (the four answers of the existing dashboard modal, unchanged meaning: descriptive only). No row yet returns the all-null body, not 404.

### PUT /api/onboarding

Request:
```json
{ "intent": "RUN_COMPANY", "businessType": "GENERAL_CONTRACTOR" }
```
- `intent` required. `businessType` optional (nullable).
- 200 with the same shape as GET. Idempotent upsert; may be called again to change the answer.
- Errors: 400 `VALIDATION_FAILED` (missing or unknown enum value -> `MALFORMED_BODY` for unknown enum), 401.
- Does not create an organization and does not change any role. Creating the organization is an explicit `POST /api/organizations`.

Flow note for the dashboard: registration needs email verification, so the user has no session at signup. The dashboard keeps the answer in `localStorage` until the first authenticated session, calls `PUT /api/onboarding`, then drops the local copy. Same path for Google login.

### Profile extension (existing `/api/profile`)

`GET`/`PUT /api/profile` gain one optional field `trade` (string, max 80, nullable), e.g. `"electrician"`. Trade is profile data, not a permission. Existing fields and validation unchanged; a request without `trade` keeps the stored value untouched on PUT (so current clients do not break).

---

## 2. Organizations

Existing controller/service (`/api/organizations`, create/list/get/rename) is kept. Changes: role seeding on create, and `myRole` added to responses.

Common response `OrganizationResponse`:
```json
{
  "id": "uuid",
  "name": "Acme Builders",
  "status": "ACTIVE",
  "myRole": { "code": "OWNER", "name": "Propietario" }
}
```
(`myRole` is the caller's role in that organization.)

### POST /api/organizations

- Request: `{ "name": "Acme Builders" }`, name 1..160 after trim.
- Permission: none beyond being authenticated (anyone may found a company; intent is not checked, ADR 0002). Scope: creates a new tenant.
- Behavior, one transaction, invariants inside the `Organization` constructor: persist the organization, seed the five system roles (section 8) with their permissions, create the creator's `OrganizationMembership` with role `OWNER` (ACTIVE).
- 201 `OrganizationResponse`. Errors: 400 `VALIDATION_FAILED` / `INVALID_ARGUMENT` (blank or >160 name), 401.
- Backfill: organizations created before this change have only the Owner role. A one-off data migration must add the four other roles to them (see open question Q5).

### GET /api/organizations

- Lists organizations where the caller has an ACTIVE membership. Filter: by membership, not by a client parameter. No permission check needed (own data). 200 `OrganizationResponse[]`, empty array if none.

### GET /api/organizations/{organizationId}

- Permission: active member only. Tenant: step 1 of 0.1. 200 `OrganizationResponse`. Errors: 404 (non-member or unknown).

### PATCH /api/organizations/{organizationId}

- Request `{ "name": "..." }`. Permission `MANAGE_ORGANIZATION` scope `ORGANIZATION` (Owner only in v1). 200 `OrganizationResponse`. Errors: 400, 403, 404.

### GET /api/organizations/{organizationId}/me

Lets the dashboard gate UI. The server stays the authority; this is display data.

- Permission: active member. 200:
```json
{
  "membershipId": "uuid",
  "role": { "code": "WORKER", "name": "Trabajador" },
  "permissions": [ { "action": "VIEW_PROJECT", "scope": "PROJECT" } ]
}
```
- Errors: 404.

### GET /api/organizations/{organizationId}/roles

- Permission: `MANAGE_MEMBERS` / `ORGANIZATION`. 200 `[ { "id": "uuid", "code": "WORKER", "name": "Trabajador", "system": true } ]`. Used by the invite form. Errors: 403, 404.

### GET /api/organizations/{organizationId}/members

- Permission: `MANAGE_MEMBERS` / `ORGANIZATION`. Filter by organization in the query. Query: `status` optional (`ACTIVE` default, `SUSPENDED`, `LEFT`).
- 200:
```json
[ { "membershipId": "uuid", "userId": "uuid", "email": "ana@acme.com", "fullName": "Ana Perez",
    "role": { "code": "MEMBER", "name": "Miembro" }, "status": "ACTIVE" } ]
```
`fullName` is `null` if the user has no profile. Errors: 403, 404.

Member removal, role change and suspension endpoints are out of v1 scope (entity methods exist; add with the members screen).

---

## 3. Invitations

Entity change (Backend Dev): `OrganizationInvitation` gains nullable `project` (`@ManyToOne`, must belong to the same organization; checked in the constructor like role and inviter). Accepting creates the membership and, when `project` is set, a `ProjectAccess`, in one transaction. Raw token is never stored or returned by the API; only its hash is stored (same hashing approach as the existing opaque tokens) and the raw value is sent in the email.

Invitation response `InvitationResponse`:
```json
{
  "id": "uuid", "email": "bob@example.com",
  "role": { "code": "WORKER", "name": "Trabajador" },
  "projectId": "uuid or null",
  "status": "PENDING", "expiresAt": "2026-11-02T10:00:00Z"
}
```

### POST /api/organizations/{organizationId}/invitations

Request:
```json
{ "email": "bob@example.com", "roleCode": "WORKER", "projectId": "uuid (optional)" }
```
- Permission: `MANAGE_MEMBERS` / `ORGANIZATION`. If `projectId` is present, additionally `MANAGE_PROJECT` on that project (it grants site access).
- Tenant: role resolved by `(organizationId, roleCode)`, project by `(organizationId, projectId)`; either missing -> 404.
- Rules:
  - `roleCode` may not be `OWNER` (400 `INVALID_ARGUMENT`); there is one owner, the creator.
  - Email is normalized (`UserAccount.normalizeEmail`). If that email already belongs to a member of this organization in ANY status -> 409 `STATE_CONFLICT`.
  - A previous PENDING invitation for the same organization and email is revoked and replaced (this is also "resend").
  - Expiry: now + 7 days (configurable `app.invitations.ttl`).
  - Response is identical whether or not an account exists for the email (no account enumeration). The email contains `${FRONTEND_URL}/invitations/accept?token=<raw>`.
- 201 `InvitationResponse`. Errors: 400 `VALIDATION_FAILED` (bad email), 400 `INVALID_ARGUMENT`, 403, 404, 409.
- Mail failure: the invitation is still created (201); sending is best-effort and logged, and the admin can resend by repeating the call. (Matches how `AuthMailer` is used.)

### GET /api/organizations/{organizationId}/invitations

- Permission `MANAGE_MEMBERS` / `ORGANIZATION`. Query `status` optional, default `PENDING`. 200 `InvitationResponse[]`. Errors: 403, 404.

### DELETE /api/organizations/{organizationId}/invitations/{invitationId}

- Permission `MANAGE_MEMBERS` / `ORGANIZATION`. Revokes (`revoke()`). 204. Errors: 403, 404 (not in this organization), 409 (not pending).

### POST /api/invitations/accept

Not under an organization path: the token identifies the tenant. Tenant safety comes from the token hash lookup plus the email check.

Request: `{ "token": "<raw token from the email link>" }`

- Permission: authenticated user only; no `DomainAuthorization` (the caller has no membership yet). The authenticated account is already active with a verified email.
- Algorithm (one transaction, row locked with `PESSIMISTIC_WRITE` on the invitation so double-submit cannot create two memberships):
  1. Hash the token, look it up. Unknown -> 404.
  2. Invitation email must equal the caller's email. Mismatch -> 404 (do not reveal that the token is valid).
  3. Status not PENDING or expired -> 409 `STATE_CONFLICT`.
  4. Caller already has a membership in that organization (any status) -> 409 `STATE_CONFLICT`.
  5. `invitation.accept(user, now)` creates the membership; if `project` is set, create `ProjectAccess(project, membership)`.
- 200:
```json
{ "organization": { "id": "uuid", "name": "Acme Builders" },
  "membershipId": "uuid",
  "role": { "code": "WORKER", "name": "Trabajador" },
  "projectId": "uuid or null" }
```
- Errors: 400 `VALIDATION_FAILED` (blank token), 401, 404, 409.
- Rate limit: add `/api/invitations/accept` to the existing `AuthRateLimitFilter` paths (token guessing).

Deferred: preview-before-login endpoint, "my pending invitations" by email, reactivating a `LEFT` membership via re-invite.

---

## 4. Projects (sites)

Entity change: `Project` gains `address` (nullable, max 255), `startDate` (nullable `LocalDate`), `expectedEndDate` (nullable `LocalDate`), `status` (`PLANNED` default, `ACTIVE`, `ON_HOLD`, `COMPLETED`, `ARCHIVED`). Invariant in the entity: `expectedEndDate` not before `startDate` (400 `INVALID_ARGUMENT`). Client and budget are not part of v1 (CRM and finance modules).

`ProjectResponse`:
```json
{
  "id": "uuid", "name": "Torre Norte", "address": "Av. Siempre Viva 742",
  "startDate": "2026-11-01", "expectedEndDate": "2027-05-30", "status": "ACTIVE",
  "activityCount": 12, "doneCount": 4
}
```
`activityCount`/`doneCount` are `null` when the caller does not hold `VIEW_ACTIVITY` covering the project (e.g. Finance).

| Method and path | Permission / scope | Notes |
|---|---|---|
| `POST /api/organizations/{orgId}/projects` | `MANAGE_PROJECT` / `ORGANIZATION` (`projectId` null) | Body `{name (req, 1..160), address?, startDate?, expectedEndDate?, status?}`. 201. |
| `GET /api/organizations/{orgId}/projects` | `VIEW_PROJECT`, filtered by scope (0.1) | Query `status` optional; default excludes `ARCHIVED`. A Worker only gets projects where they have `ProjectAccess`. 200 array. |
| `GET /api/organizations/{orgId}/projects/{projectId}` | `VIEW_PROJECT` on the project | 200. |
| `PATCH /api/organizations/{orgId}/projects/{projectId}` | `MANAGE_PROJECT` on the project | Any subset of the create fields. 200. |

No hard delete in v1: set `status` to `ARCHIVED`.

Errors for all: 400 (validation, date order), 403 (permission or scope, including Worker without access to that project), 404 (non-member, other tenant, unknown id).

---

## 5. Project access (assignment of people to sites)

Assignees must have an account (no account-less workers in v1, ADR 0003). People enter a site through `ProjectAccess` and tasks are assigned to a `ProjectAccess`.

`AccessResponse`:
```json
{ "accessId": "uuid", "membershipId": "uuid", "userId": "uuid",
  "fullName": "Ana Perez", "role": { "code": "WORKER", "name": "Trabajador" } }
```
(No email here: Workers can read this list.)

| Method and path | Permission / scope | Notes |
|---|---|---|
| `GET /api/organizations/{orgId}/projects/{projectId}/access` | `VIEW_PROJECT` on the project | 200 array of ACTIVE members only. |
| `POST /api/organizations/{orgId}/projects/{projectId}/access` | `MANAGE_PROJECT` on the project | Body `{ "membershipId": "uuid" }`. 201 `AccessResponse`. |
| `DELETE /api/organizations/{orgId}/projects/{projectId}/access/{accessId}` | `MANAGE_PROJECT` on the project | 204. |

Rules and errors:
- POST: membership resolved by `(organizationId, membershipId)` -> 404 if absent. Membership must be ACTIVE (entity -> 400). Already has access -> 409 `DATA_CONFLICT`.
- DELETE: access resolved by `(organizationId, projectId, accessId)` -> 404. If any activity is assigned to it (any status) -> 409 `STATE_CONFLICT`; the caller must reassign first (the activity assignee column is NOT NULL).
- Owners and Administrators have `ORGANIZATION` scope and do not need a `ProjectAccess` themselves; to be assignable to a task they must be given one like anyone else.

---

## 6. Goals (phases)

Entity change: `Goal` gains `rename`, `changeStartAt`, `changeDueAt`, `changeDates` and `shift` methods with invariants: name 1..160; `startAt <= dueAt`; a new `startAt` may not be after the earliest `startAt` of its activities and a new `dueAt` may not be before the latest `dueAt` of its activities (400 `INVALID_ARGUMENT`). When a PATCH sends both dates they are checked as a pair. Migration `V9__start_dates.sql` backfilled existing phases with `startAt = min(earliest task dueAt, phase dueAt)`.

`GoalResponse`:
```json
{ "id": "uuid", "projectId": "uuid", "name": "Foundations",
  "startAt": "2026-11-01T00:00:00Z", "dueAt": "2026-12-15T23:59:00Z",
  "activityCount": 5, "doneCount": 2, "completed": false }
```
`completed` = existing `Goal.isCompleted()` (has activities and all DONE).

| Method and path | Permission / scope | Notes |
|---|---|---|
| `POST /api/organizations/{orgId}/projects/{projectId}/goals` | `MANAGE_GOAL` on the project | Body `{name, startAt, dueAt}` all required. 201. |
| `GET /api/organizations/{orgId}/projects/{projectId}/goals` | `VIEW_GOAL` on the project | Ordered by `dueAt`. 200 array. |
| `GET /api/organizations/{orgId}/projects/{projectId}/goals/{goalId}` | `VIEW_GOAL` on the project | 200. |
| `PATCH /api/organizations/{orgId}/projects/{projectId}/goals/{goalId}` | `MANAGE_GOAL` on the project | `{name?, startAt?, dueAt?}`. 200. |
| `POST /api/organizations/{orgId}/projects/{projectId}/goals/{goalId}/shift` | `MANAGE_GOAL` on the project | Body `{ "days": int }`, non-zero, -3650..3650. Moves the goal's `startAt`/`dueAt` and every activity's `startAt`/`dueAt` by `days` in one transaction. 200 `GoalResponse`. `days = 0` -> 400 `INVALID_ARGUMENT`; missing or out of range -> 400 `VALIDATION_FAILED`. |
| `DELETE /api/organizations/{orgId}/projects/{projectId}/goals/{goalId}` | `MANAGE_GOAL` on the project | 204. Goal has activities -> 409 `STATE_CONFLICT`. |

Tenant: goal resolved by `(organizationId, projectId, goalId)`. Errors: 400, 403, 404, 409 as noted. `activityCount`/`doneCount` are `null` when the caller lacks `VIEW_ACTIVITY` on the project.

---

## 7. Activities (tasks)

Task = Activity (ADR 0001). Required assignee: `Activity.assigneeAccess` is NOT NULL, so every task has an assignee at creation (open question Q3 for an unassigned backlog).

`ActivityResponse`:
```json
{
  "id": "uuid", "goalId": "uuid", "projectId": "uuid", "name": "Pour slab level 1",
  "startAt": "2026-11-20T08:00:00Z", "dueAt": "2026-12-01T18:00:00Z", "status": "TODO", "completedAt": null,
  "assignee": { "accessId": "uuid", "membershipId": "uuid", "fullName": "Ana Perez" }
}
```
`status`: `TODO | IN_PROGRESS | DONE`.

| Method and path | Permission / scope | Notes |
|---|---|---|
| `POST /api/organizations/{orgId}/projects/{projectId}/goals/{goalId}/activities` | `MANAGE_ACTIVITY` on the project (assignee arg `null`) AND `ASSIGN_ACTIVITY` on the project | Body `{name, startAt, dueAt, assigneeAccessId}` all required. 201. |
| `GET /api/organizations/{orgId}/projects/{projectId}/goals/{goalId}/activities` | `VIEW_ACTIVITY`, filtered by scope | Query `status`, `assigneeAccessId` optional. 200 array ordered by `dueAt`. |
| `GET .../activities/{activityId}` | `VIEW_ACTIVITY` on the project | 200. |
| `PATCH .../activities/{activityId}` | `MANAGE_ACTIVITY` on the project (assignee arg `null`) | `{name?, startAt?, dueAt?}`. Not for status or assignee. Both dates are checked as a pair. 200. |
| `PUT .../activities/{activityId}/assignee` | `ASSIGN_ACTIVITY` on the project | Body `{ "assigneeAccessId": "uuid" }`. 200. |
| `POST .../activities/{activityId}/start` | `MANAGE_ACTIVITY` with the current assignee's membership id | TODO -> IN_PROGRESS. 200. |
| `POST .../activities/{activityId}/complete` | `MANAGE_ACTIVITY` with the current assignee's membership id | TODO or IN_PROGRESS -> DONE, sets `completedAt` to server time. 200. |
| `DELETE .../activities/{activityId}` | `MANAGE_ACTIVITY` on the project (assignee arg `null`) | 204. |
| `GET /api/organizations/{orgId}/activities/mine` | `VIEW_ACTIVITY` or `MANAGE_ACTIVITY`, any scope | Caller's own assigned tasks across all projects of the organization. Query `status` optional. 200 array ordered by `dueAt`. For the Worker home screen. |

(`...` = `/api/organizations/{orgId}/projects/{projectId}/goals/{goalId}`.)

Tenant and rules:
- Resolve by `(organizationId, projectId, goalId, activityId)`: wrong parent or other tenant -> 404.
- `assigneeAccessId` is resolved within `(organizationId, projectId)`: access of another project or tenant -> 404. Assignee must be an ACTIVE member (entity -> 400).
- `startAt <= dueAt`, `startAt` may not be before the goal's `startAt` and `dueAt` may not be after the goal's `dueAt` (entity -> 400 `INVALID_ARGUMENT`). PATCH re-checks both dates together. V9 backfilled existing tasks with `startAt = dueAt`.
- Transitions: `start` on a non-TODO activity -> 409; `complete` on a DONE activity -> 409. Reopening a DONE task is not in v1 (Q4).
- A Worker (`MANAGE_ACTIVITY` = `OWN`) passes `start`/`complete` only on tasks assigned to them; on create, patch, reassign and delete the `null` assignee argument makes `OWN` deny -> 403. A Worker's `GET` of the list is filtered to the project's tasks (`VIEW_ACTIVITY` = `PROJECT`); the single-activity GET passes if `PROJECT` access holds.
- Errors: 400, 403, 404, 409 as noted.

---

## 8. Seeded permission matrix

Five system roles are created for every new organization by the `Organization` constructor. `code` is the stable identifier used by the API; `name` is informational and stored in Spanish like the existing Owner (`Propietario`). The dashboard localizes display by `code`.

Entity invariant (Backend Dev): today `OrganizationRole.systemRole` means "Owner" (`OrganizationMembership` rejects a `systemRole` for anyone but the creator and blocks suspend/leave). Do NOT mark the other four roles `systemRole`. Add a second flag `seeded` (boolean, default false): seeded roles cannot be renamed, regranted or revoked (same guards as `systemRole` in `rename/grant/revoke`), and codes `ADMINISTRATOR`, `MEMBER`, `WORKER`, `FINANCE` become reserved for custom roles like `OWNER`. Factory: `OrganizationRole.seeded(organization, code, name, grants)` where each grant goes through `Permission.changeScope` validation.

Scopes: `ORG` = `ORGANIZATION`, `PRJ` = `PROJECT` (needs a `ProjectAccess`), `OWN` = assignee is the caller. `-` = not granted. All pairs below pass the `Permission.changeScope` rules (admin actions need `ORG`; project and goal actions cannot be `OWN`; `ASSIGN_ACTIVITY` cannot be `OWN`).

| Action | Owner `OWNER` | Administrator `ADMINISTRATOR` | Member `MEMBER` (office) | Worker `WORKER` (field) | Finance `FINANCE` (placeholder) |
|---|---|---|---|---|---|
| `MANAGE_ORGANIZATION` | ORG | - | - | - | - |
| `MANAGE_ROLES` | ORG | ORG | - | - | - |
| `MANAGE_MEMBERS` | ORG | ORG | - | - | - |
| `VIEW_PROJECT` | ORG | ORG | ORG | PRJ | ORG |
| `MANAGE_PROJECT` | ORG | ORG | - | - | - |
| `VIEW_GOAL` | ORG | ORG | ORG | PRJ | - |
| `MANAGE_GOAL` | ORG | ORG | ORG | - | - |
| `VIEW_ACTIVITY` | ORG | ORG | ORG | PRJ | - |
| `MANAGE_ACTIVITY` | ORG | ORG | ORG | OWN | - |
| `ASSIGN_ACTIVITY` | ORG | ORG | ORG | - | - |

Notes:
- Owner is built by the existing `OrganizationRole.owner()` (every action at `ORG`).
- Administrator "all except billing, organization deletion and Owner transfer": the enum has no billing or deletion action, so those currently live under `MANAGE_ORGANIZATION`. Until the enum is split, Administrator does not get `MANAGE_ORGANIZATION`, which also means it cannot rename the organization (Q2). Owner transfer does not exist in v1; the Owner role can never be assigned by invitation or `changeRole`.
- When role-management endpoints are built later (not in v1), the rule must be "a caller cannot grant an action/scope they do not hold" because Administrator has `MANAGE_ROLES`.
- Finance holds only `VIEW_PROJECT` now; finance actions are added to the enum and to this role with the finance module (needs a data migration for existing organizations).
- Worker sees every task on their sites (`VIEW_ACTIVITY` = `PRJ`) because site-level awareness is the product pitch; Q7 if this should be `OWN`.

Behavior check per role (acceptance cases for QA):
- Worker: `GET projects` returns only sites with their `ProjectAccess`; direct GET of another project -> 403; can `start`/`complete` own task; `complete` on a colleague's task -> 403; cannot create/edit/delete/reassign tasks; cannot create goals or projects; cannot invite.
- Member: sees all projects, goals, tasks; creates and manages goals; creates, edits, reassigns, completes any task; cannot create projects or grant project access; cannot invite.
- Finance: lists/gets projects only; `activityCount` null; goals/activities -> 403.
- Administrator: everything except renaming the organization.
- Any user of tenant A calling any tenant B path -> 404, never 403 and never data.

---

## 9. Cross-cutting requirements

- Tests per endpoint (QA, RED first): happy path, 401, 403 for a role without the permission, 404 cross-tenant (user of organization A using organization B ids, and A's ids under B's path), scope denial (Worker), invariant 400/409 cases above.
- Disposable DB or H2 only; do not run against the dev schema.
- `ddl-auto=update` cannot add NOT NULL columns to populated tables, and the seeded-role backfill is a data change: this feature should land together with the Flyway baseline (roadmap item 4) or ship an explicit SQL script reviewed by the Architect.
- UI strings are EN/ES; error `code` values are the stable key for translating messages.

## 10. Open questions (not assumed)

- Q1 RESOLVED (user): Member manages goals (`MANAGE_GOAL` / `ORG`).
- Q2 RESOLVED (user): Owner only edits organization details in v1; split `MANAGE_ORGANIZATION` when billing arrives.
- Q3 (product, user): are unassigned tasks (office backlog) needed? Would require `Activity.assigneeAccess` nullable. Recommendation: no for v1, assignee required.
- Q4 (product, user): may a DONE task be reopened (worker marked it by mistake)? Needs a `reopen()` entity method and endpoint. Recommendation: add `POST .../reopen` for `MANAGE_ACTIVITY` non-`OWN` in the first fix iteration if users ask.
- Q5 (Backend Dev + Architect): organizations already in the dev/prod database lack the four seeded roles. Needs a one-off backfill; confirm whether any real data exists before choosing script vs Flyway migration.
- Q6 (Architect, later): pagination for lists. Unpaginated in v1; add `page`/`size` before activities per organization grow large.
- Q7 RESOLVED (user): Worker `VIEW_ACTIVITY` stays `PRJ` (all tasks on assigned sites).
- Q8 (product, user): cap on organizations a user can create and on pending invitations per organization (abuse). Not enforced in v1 beyond the auth rate limiter.
