# Plans Per Site — Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the global plan library and replace it with per-site plan pages that share the site's document-folder tree.

**Architecture:** Delete the global plan library (page, provider, context, library API, tree helpers, library dialogs). Add `getSitePlans` to `plansApi.ts` and `folderId` to the upload request. Create two new per-site pages (`SitePlansPage`, `SitePlanFolderPage`) that use the existing `getDocumentFolders` API for folder navigation and the updated `plansApi` for plan content. Wire routes and add a Plans entry point on `SiteDetailPage`.

**Tech Stack:** React 19, TypeScript, React Router, Zod, Bun test runner

**Spec:** docs/superpowers/specs/2026-11-04-plans-per-site-design.md

## Global Constraints

- All new user-facing strings bilingual EN/ES in `src/i18n/messages.ts` (spec S8)
- No new prod dependencies
- Two-space indent, single quotes, no semicolons (match surrounding code)
- Run `bun run lint && bun run build && bun test` before finishing any task
- Tests live in `src/tests/` mirroring the source tree; no component renderer — test only pure logic and API modules via fake AxiosInstance

## Review Focus

1. **Stale folderId**: a plan's `folderId` now references a `document-folder` ID; if the folder was deleted, the folder page renders empty but the plan is unreachable — SitePlanFolderPage should handle an empty list gracefully (emptyTitle state, same as today).
2. **Permission gate on new routes**: a user without `VIEW_PLAN` who navigates directly to `/sites/:siteId/plans` should be redirected; the page must check `hasPermission(access, 'VIEW_PLAN')` and redirect just like the old `PlanLibraryPage` did.
3. **workspaceNav test**: `src/tests/features/organizations/workspaceNav.test.ts` currently asserts the `plans` item appears when `seesPlans` is true — that assertion must be removed in Task 1 so the suite stays green.
4. **Shared folder mutation**: creating a folder from `SitePlansPage` calls `createDocumentFolder`, which the Documents section already uses. The reverse is also true — verify that the shared `useRemoteData` cache key `${org.id}:${siteId}:doc-folders` is used consistently so both pages share state.
5. **View URL expiry**: `SitePlanFolderPage` must call `refreshExpired` (from `planDisplay.ts`) when a plan thumbnail is opened, same as the old `PlanLibraryPage`, or viewUrl will be stale for long sessions.

---

## File Map

**Delete entirely:**
- `src/features/plans/PlanLibraryPage.tsx`
- `src/features/plans/PlanLibraryProvider.tsx`
- `src/features/plans/planLibraryContext.ts`
- `src/features/plans/planLibraryApi.ts`
- `src/features/plans/planTree.ts`
- `src/features/plans/PlanLibraryDialogs.tsx`
- `src/tests/features/plans/planLibrary.test.ts`

**Keep unchanged:**
- `src/features/plans/planUpload.ts`
- `src/features/plans/planDisplay.ts`
- `src/features/plans/plans.css`
- `src/tests/features/plans/planUpload.test.ts`

**Modify:**
- `src/features/plans/plansApi.ts` — add `getSitePlans`, add `folderId` to `PlanUploadRequest`/`requestPlanUpload`
- `src/features/plans/PlanUploadDialog.tsx` — add `folderId: string` prop
- `src/features/organizations/workspaceNav.ts` — remove `plans` nav item and `seesPlans` param
- `src/features/organizations/WorkspaceLayout.tsx` — remove `PlanLibraryProvider` import and wrapper; remove `seesPlans` arg
- `src/App.tsx` — remove `/plans` routes and `PlanLibraryPage` lazy import; add new lazy imports and routes
- `src/features/sites/SiteDetailPage.tsx` — add Plans link in overview section
- `src/i18n/messages.ts` — remove `m.plans.library`, `m.workspace.plans`; add `m.plans.back`, update `m.plans.description`
- `src/tests/features/plans/plansApi.test.ts` — add tests for `getSitePlans` and `folderId` in upload request; remove any `movePlan` tests
- `src/tests/features/organizations/workspaceNav.test.ts` — remove `seesPlans` assertions

**Create:**
- `src/features/plans/SitePlansPage.tsx`
- `src/features/plans/SitePlanFolderPage.tsx`

---

### Task 1: Delete global library and clean up dependents

**Files:**
- Delete: `src/features/plans/PlanLibraryPage.tsx`, `PlanLibraryProvider.tsx`, `planLibraryContext.ts`, `planLibraryApi.ts`, `planTree.ts`, `PlanLibraryDialogs.tsx`
- Delete: `src/tests/features/plans/planLibrary.test.ts`
- Modify: `src/features/organizations/workspaceNav.ts`
- Modify: `src/features/organizations/WorkspaceLayout.tsx`
- Modify: `src/App.tsx`
- Modify: `src/i18n/messages.ts`
- Modify: `src/tests/features/organizations/workspaceNav.test.ts`

**Interfaces:**
- Produces: nothing new; this task only removes code

- [ ] **Step 1: Delete the seven files**

```bash
rm construx-dashboard/src/features/plans/PlanLibraryPage.tsx \
   construx-dashboard/src/features/plans/PlanLibraryProvider.tsx \
   construx-dashboard/src/features/plans/planLibraryContext.ts \
   construx-dashboard/src/features/plans/planLibraryApi.ts \
   construx-dashboard/src/features/plans/planTree.ts \
   construx-dashboard/src/features/plans/PlanLibraryDialogs.tsx \
   construx-dashboard/src/tests/features/plans/planLibrary.test.ts
```

- [ ] **Step 2: Remove `plans` from `workspaceNav.ts`**

In `src/features/organizations/workspaceNav.ts`:
- Remove `'plans'` from the `WorkspaceNavItem['key']` union type (line 2)
- Remove `seesPlans?: boolean` from the params type and body of `workspaceNavItems` (lines 12, 18, 24)
- Remove `{ key: 'plans', to: '/plans' }` from the `sections` array (line 35)

- [ ] **Step 3: Remove `PlanLibraryProvider` and `seesPlans` from `WorkspaceLayout.tsx`**

In `src/features/organizations/WorkspaceLayout.tsx`:
- Remove the `import { PlanLibraryProvider } from '../plans/PlanLibraryProvider'` line
- Unwrap `<PlanLibraryProvider>` around `<WorkspaceBody />` — the child stays, the wrapper goes
- Remove `seesPlans: hasPermission(access, 'VIEW_PLAN')` from the `workspaceNavItems(...)` call

- [ ] **Step 4: Remove `/plans` routes and `PlanLibraryPage` import from `App.tsx`**

In `src/App.tsx`:
- Remove the `PlanLibraryPage` lazy import (line 15)
- Remove the two routes: `<Route path="/plans" …>` and `<Route path="/plans/folders/:folderId" …>` (lines 76–77)

- [ ] **Step 5: Remove dead i18n keys from `messages.ts`**

In `src/i18n/messages.ts`, in both the `en` and `es` objects:
- Remove the entire `plans.library` block (the nested object, ~10 keys)
- Remove `workspace.plans` key

- [ ] **Step 6: Remove `seesPlans` assertions from workspaceNav test**

In `src/tests/features/organizations/workspaceNav.test.ts`, remove any test case or assertion that passes `seesPlans: true` or checks for a `plans` nav item.

- [ ] **Step 7: Verify build is clean**

Run from `construx-dashboard/`: `bun run build`

Expected: no TypeScript errors, no "module not found" errors.

- [ ] **Step 8: Run tests**

Run: `bun test`

Expected: all pass; `planLibrary.test.ts` is gone so no reference to it fails.

- [ ] **Step 9: Commit**

```bash
git -C construx-dashboard add -A
git -C construx-dashboard commit -m "refactor(plans): remove global plan library"
```

---

### Task 2: Extend `plansApi.ts` — `getSitePlans` + `folderId` in upload

**Files:**
- Modify: `src/features/plans/plansApi.ts`
- Modify: `src/tests/features/plans/plansApi.test.ts`

**Interfaces:**
- Produces:
  - `getSitePlans(org: string, siteId: string, folderId: string): Promise<Plan[]>`
  - `PlanUploadRequest` gains `folderId: string | null`
  - `requestPlanUpload` passes `folderId` in the POST body when non-null

- [ ] **Step 1: Write failing tests**

In `src/tests/features/plans/plansApi.test.ts`, add:

```typescript
test('getSitePlans calls GET .../plans?folderId=...', async () => {
  // fake axios GET returns [planFixture]
  // assert URL contains '/projects/site-1/plans?folderId=folder-1'
  // assert result equals [planFixture]
})

test('requestPlanUpload includes folderId in body when set', async () => {
  // fake axios POST to .../plans/uploads
  // request has folderId: 'folder-1' in body
  // assert body.folderId === 'folder-1'
})

test('requestPlanUpload omits folderId when null', async () => {
  // folderId: null
  // assert 'folderId' not in body
})
```

Use the existing fake `AxiosInstance` pattern already in this test file.

- [ ] **Step 2: Run tests to verify they fail**

Run: `bun test src/tests/features/plans/plansApi.test.ts`

Expected: FAIL — `getSitePlans is not a function`

- [ ] **Step 3: Implement `getSitePlans` in `plansApi.ts`**

Add after the existing `plansPath`/`planPath` helpers:

```typescript
export function getSitePlans(org: string, siteId: string, folderId: string): Promise<Plan[]> {
  return getJson(
    `${plansPath(org, siteId)}?folderId=${encodeURIComponent(folderId)}`,
    z.array(planSchema),
  )
}
```

Add `getJson` to the import from `'../auth/authApi'`.

- [ ] **Step 4: Add `folderId` to `PlanUploadRequest` and `requestPlanUpload`**

In `PlanUploadRequest`:
```typescript
export type PlanUploadRequest = {
  fileName: string
  contentType: string
  sizeBytes: number
  name: string
  description: string
  folderId: string | null
}
```

In `requestPlanUpload`, after the existing `description` conditional:
```typescript
if (request.folderId) body.folderId = request.folderId
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `bun test src/tests/features/plans/plansApi.test.ts`

Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git -C construx-dashboard add src/features/plans/plansApi.ts src/tests/features/plans/plansApi.test.ts
git -C construx-dashboard commit -m "feat(plans): add getSitePlans and folderId to upload request"
```

---

### Task 3: Update `PlanUploadDialog` to accept `folderId`

**Files:**
- Modify: `src/features/plans/PlanUploadDialog.tsx`

**Interfaces:**
- Consumes: `PlanUploadRequest.folderId` (Task 2)
- Produces: `PlanUploadDialogProps` gains `folderId: string`

- [ ] **Step 1: Add `folderId` to `PlanUploadDialogProps`**

```typescript
type PlanUploadDialogProps = {
  organizationId: string
  siteId: string
  folderId: string
  onUploaded: (plan: Plan) => void
  onClose: () => void
}
```

- [ ] **Step 2: Pass `folderId` to `requestPlanUpload`**

In the `submit` function inside `PlanUploadDialog`, find the `requestPlanUpload(...)` call and add `folderId` to the request object passed as the third argument.

- [ ] **Step 3: Build and type-check**

Run: `bun run build`

Expected: no errors. (No test file for this component; type safety catches prop mismatches.)

- [ ] **Step 4: Commit**

```bash
git -C construx-dashboard add src/features/plans/PlanUploadDialog.tsx
git -C construx-dashboard commit -m "feat(plans): pass folderId through PlanUploadDialog"
```

---

### Task 4: Create `SitePlansPage` and add i18n strings

**Files:**
- Create: `src/features/plans/SitePlansPage.tsx`
- Modify: `src/i18n/messages.ts`

**Interfaces:**
- Consumes: `getDocumentFolders` from `../documents/documentFoldersApi`, `createDocumentFolder`, `deleteDocumentFolder`; `getSite` from `../sites/sitesApi`; `usePermissions`, `useCurrentOrganization`, `useRemoteData`, `BackLink`, `LoadingState`, `Notice`
- Produces: `SitePlansPage` component rendered at `/sites/:siteId/plans`

- [ ] **Step 1: Add i18n strings**

In `src/i18n/messages.ts`, in both `en` and `es` objects, add inside `plans`:

EN:
```typescript
back: 'Plans',
foldersDescription: 'Site plans organized by folder.',
```

ES:
```typescript
back: 'Planos',
foldersDescription: 'Planos de la obra organizados por carpeta.',
```

For folder create/delete button labels reuse `m.documents.newFolder`, `m.documents.create`, `m.documents.cancel`, `m.documents.folderName`, and `m.documents.deleteFolderConfirm` — do not duplicate them under `m.plans`.

Also update `m.plans.description` to describe the per-site context:
- EN: `'Drawings and photos of this site, organized by folder.'`
- ES: `'Planos y fotos de esta obra, organizados por carpeta.'`

- [ ] **Step 2: Build to verify i18n types**

Run: `bun run build`

Expected: `Messages` type is satisfied (the type is inferred from the `en` object).

- [ ] **Step 3: Create `SitePlansPage.tsx`**

Model after `SiteDocumentsPage.tsx`. Key differences:
- Route param: `siteId` from `useParams()`
- `BackLink to={'/sites/${encodeURIComponent(siteId)}'}` with `{t.detail.back}` from `m.sites` (reuse the site back label)
- Loads folders: `useRemoteData(\`${org.id}:${siteId}:doc-folders\`, () => getDocumentFolders(org.id, siteId))`
- Uses `hasPermission(access, 'VIEW_PLAN')` guard (redirect to `landingPath(access)` if missing)
- Each folder card links to `\`/sites/${encodeURIComponent(siteId)}/plans/folders/${encodeURIComponent(folder.id)}\``
- `canManage` via `can('MANAGE_PROJECT', siteId)` — same as documents
- Create/delete folder calls `createDocumentFolder` / `deleteDocumentFolder` (shared with documents)
- No search (documents has search; plans folder page doesn't need it)
- `document.title` pattern: `\`${siteName} · ${m.plans.title} | Construx\``

- [ ] **Step 4: Build to verify types**

Run: `bun run build`

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git -C construx-dashboard add src/features/plans/SitePlansPage.tsx src/i18n/messages.ts
git -C construx-dashboard commit -m "feat(plans): add SitePlansPage with shared document folders"
```

---

### Task 5: Create `SitePlanFolderPage`

**Files:**
- Create: `src/features/plans/SitePlanFolderPage.tsx`

**Interfaces:**
- Consumes: `getSitePlans`, `deletePlan`, `planErrorKind` from `./plansApi`; `PlanUploadDialog` from `./PlanUploadDialog`; `viewUrlExpired`, `megabytes` from `./planDisplay`; `getDocumentFolders` from `../documents/documentFoldersApi`; `usePermissions`, `BackLink`, `LoadingState`, `Notice`, `Modal`, `ConfirmDialog`; `'./plans.css'`
- Produces: `SitePlanFolderPage` component rendered at `/sites/:siteId/plans/folders/:folderId`

- [ ] **Step 1: Create `SitePlanFolderPage.tsx`**

Route params: `siteId`, `folderId` from `useParams()`.

Data loading:
- Folder name: `useRemoteData(\`${org.id}:${siteId}:doc-folders\`, () => getDocumentFolders(org.id, siteId))` → find `folder.id === folderId`
- Plans: `useRemoteData(\`${org.id}:${siteId}:${folderId}:plans\`, () => getSitePlans(org.id, siteId, folderId))`

Permissions:
- `hasPermission(access, 'VIEW_PLAN')` guard (redirect if missing)
- `canManage = can('MANAGE_PROJECT', siteId)` for upload/delete

Navigation:
- `BackLink to={\`/sites/${encodeURIComponent(siteId)}/plans\`}>{m.plans.back}</BackLink>`

Plan grid: same layout as the grid in the old `PlanLibraryPage` (use `plans.css` classes). Each plan card shows the image (`viewUrl`) and name. On open, shows a modal with the full image and a delete button for `canManage` users. Call `refreshExpired(plan)` before opening the view modal — if `viewUrlExpired(plan.viewUrlExpiresAt)` is true, reload the list first (same pattern as old `PlanLibraryPage`'s `refreshExpired`).

Upload button (canManage only): opens `<PlanUploadDialog organizationId={org.id} siteId={siteId} folderId={folderId} onUploaded={...} onClose={...} />`; on `onUploaded`, prepend the new plan to the list.

Delete: `ConfirmDialog` → calls `deletePlan(org.id, siteId, plan.id)` → removes from list. Use `planErrorKind` for error messages.

Empty state: show `m.plans.emptyTitle` and `m.plans.emptyBody` / `m.plans.emptyBodyReadOnly` based on `canManage`.

- [ ] **Step 2: Build to verify types**

Run: `bun run build`

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git -C construx-dashboard add src/features/plans/SitePlanFolderPage.tsx
git -C construx-dashboard commit -m "feat(plans): add SitePlanFolderPage"
```

---

### Task 6: Wire routes and add Plans link on `SiteDetailPage`

**Files:**
- Modify: `src/App.tsx`
- Modify: `src/features/sites/SiteDetailPage.tsx`
- Modify: `src/i18n/messages.ts`

**Interfaces:**
- Consumes: `SitePlansPage` (Task 4), `SitePlanFolderPage` (Task 5)
- Produces: working routes at `/sites/:siteId/plans` and `/sites/:siteId/plans/folders/:folderId`; Plans entry point on SiteDetailPage

- [ ] **Step 1: Add lazy imports and routes in `App.tsx`**

Add two lazy imports after the existing site-related imports:
```typescript
const SitePlansPage = lazy(() =>
  import('./features/plans/SitePlansPage').then((m) => ({ default: m.SitePlansPage }))
)
const SitePlanFolderPage = lazy(() =>
  import('./features/plans/SitePlanFolderPage').then((m) => ({ default: m.SitePlanFolderPage }))
)
```

Add routes after `/sites/:siteId/phases/:goalId/tasks/:taskId`:
```tsx
<Route path="/sites/:siteId/plans" element={<SitePlansPage />} />
<Route path="/sites/:siteId/plans/folders/:folderId" element={<SitePlanFolderPage />} />
```

- [ ] **Step 2: Add i18n key for the SiteDetailPage Plans link**

In `src/i18n/messages.ts`, in both `en` and `es`, add inside `sites.detail`:

EN: `plans: 'Plans'`
ES: `plans: 'Planos'`

- [ ] **Step 3: Add Plans link in `SiteDetailPage` overview tab**

In `src/features/sites/SiteDetailPage.tsx`, in the JSX that renders when `tab === 'overview'`, add a `Link` (from react-router) to `/sites/${encodeURIComponent(siteId)}/plans` labeled `{t.detail.plans}`. Wrap it in a `hasPermission(access, 'VIEW_PLAN')` check so only users who can see plans see the link.

- [ ] **Step 4: Final check — lint + build + test**

Run from `construx-dashboard/`:
```bash
bun run lint && bun run build && bun test
```

Expected: lint clean, build passes, all tests pass.

- [ ] **Step 5: Commit**

```bash
git -C construx-dashboard add src/App.tsx src/features/sites/SiteDetailPage.tsx src/i18n/messages.ts
git -C construx-dashboard commit -m "feat(plans): wire per-site routes and SiteDetailPage entry point"
```
