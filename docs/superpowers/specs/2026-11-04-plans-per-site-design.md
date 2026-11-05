# Plans Per Site

**Objective:** Move the plan library from a global org-level page to live inside each site, using the same document-folder tree already present on each site.

**Affected subproject:** `construx-dashboard` (frontend), `construx` (backend — folder model change)

---

## Specs

**S1 — Remove global plan library**

The route `/plans` and `/plans/folders/:folderId` are removed. The sidebar nav item "Planos / Plans" that links to `/plans` is removed. The `PlanLibraryProvider` wrapping `WorkspaceBody` in `WorkspaceLayout` is removed. The following files are deleted entirely:

- `src/features/plans/PlanLibraryPage.tsx`
- `src/features/plans/PlanLibraryProvider.tsx`
- `src/features/plans/planLibraryContext.ts`
- `src/features/plans/planLibraryApi.ts`
- `src/features/plans/planTree.ts`

The `workspaceNavItems` helper (or wherever the nav list is built) loses the `plans` entry and the `seesPlans` parameter.

**S2 — New per-site plans routes**

Two new routes are added under the workspace:

```
/sites/:siteId/plans                       SitePlansPage
/sites/:siteId/plans/folders/:folderId     SitePlanFolderPage
```

Both are lazy-loaded from `src/features/plans/SitePlansPage.tsx` and `src/features/plans/SitePlanFolderPage.tsx`.

**S3 — SitePlansPage: folder list (shared with documents)**

`SitePlansPage` calls `getDocumentFolders(org.id, siteId)` — the same API already used by `SiteDocumentsPage`. It displays the document folders as a grid/list (same visual pattern as `SiteDocumentsPage`). Each folder links to `/sites/:siteId/plans/folders/:folderId`. Users with `MANAGE_PROJECT` can create and delete folders from this page (same operations already available on `SiteDocumentsPage`; the folder is shared — creating it here also makes it visible under Documents).

A `BackLink` goes back to `/sites/:siteId`.

**S4 — SitePlanFolderPage: plans inside a folder**

`SitePlanFolderPage` loads:
- `getDocumentFolders(org.id, siteId)` — to resolve the folder name for the header
- Plans for the site scoped to this folder: `GET /api/organizations/:orgId/projects/:siteId/plans?folderId=:folderId`

It renders plan images in a grid (same display as the current `PlanLibraryPage` plan grid). Plans with `folderId` matching this folder are shown; plans with `folderId = null` are only visible from a root/unfoldered view (not in scope for this design — out of scope below). Users with `MANAGE_PROJECT` can upload a plan (opens the existing `PlanUploadDialog`) and delete plans.

A `BackLink` goes back to `/sites/:siteId/plans`.

**S5 — Plan folderId references document-folder IDs**

After this change a plan's `folderId` (in `planSchema`) references a `document-folder` ID (site-scoped), not a `plan-folder` ID (org-scoped). The `PlanUploadDialog` receives a `folderId: string` prop (the current document-folder's ID) instead of letting the user pick the folder.

The `movePlan` function in `plansApi.ts` is removed (folder assignment happens at upload time via the page context; there is no cross-folder move UI in the new design).

**S6 — Backend: drop plan-folders, wire plans to document-folders**

Backend changes required (outside the dashboard):

- `GET /api/organizations/:orgId/plan-library` — removed
- `POST/PATCH /api/organizations/:orgId/plan-folders` — removed
- `DELETE /api/organizations/:orgId/plan-folders/:id` — removed
- `PUT .../plans/:id/folder` — removed (movePlan)
- `GET .../plans` — adds optional `?folderId=` query param so the frontend can fetch plans for one folder
- Plan entity: `folderId` FK now references `document_folder.id` (site-scoped) instead of `plan_folder.id`. Existing plans with an old `folderId` get `folderId = null` during migration (a Flyway migration drops the old FK, adds the new one, nulls out orphaned values).

**S7 — Entry point from SiteDetailPage**

`SiteDetailPage` gains a "Planos / Plans" link in its overview section (a button or card, consistent with any existing links to documents or phases). The link navigates to `/sites/:siteId/plans`. It is visible to any user with `VIEW_PLAN` permission for the site.

**S8 — Bilingual strings**

All new user-facing strings are added in both `en` and `es` to the i18n message files, following the existing bilingual convention. Reuse existing `m.plans` keys where they still apply (upload dialog strings, error messages).

**S9 — PlanUploadDialog receives folderId**

`PlanUploadDialog` currently receives `organizationId` and `siteId`. It gains a `folderId: string` prop. On upload request, `folderId` is passed to `requestPlanUpload` so the backend assigns the plan to the correct document folder immediately at creation.

The `requestPlanUpload` function and its backend endpoint gain a `folderId: string | null` field in the request body. The existing three-step upload flow (request ticket → PUT to storage → complete) is otherwise unchanged.

---

## Out of scope

- Moving existing uploaded plan files to new storage paths (data migration is a backend concern)
- Plans with `folderId = null` (no folder assigned) — a root/unfoldered view is a future concern
- Cross-folder drag-and-drop for plans
- A merged "Documents + Plans" view inside a single folder page
- Changes to the Documents section beyond what S3 implies (shared folder creation/deletion)

---

## Testing

- Unit: `plansApi` changes (folderId in request, removed movePlan)
- Integration: upload flow with folderId through `PlanUploadDialog`
- Manual: create a folder from Plans page → verify it appears in Documents page for the same site (shared folder confirmed)
