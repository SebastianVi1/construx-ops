# Shared Plans library

Plans live at `/plans` and `/plans/folders/:folderId`, outside site detail pages. Every plan still belongs to exactly one site. Existing plans start at the library root; their file/storage keys do not change.

## Access and folders

- Active organization membership and `VIEW_PLAN` are required. The library includes only sites/plans within that permission's organization or assigned-project scope.
- Folder names/structure are organization-shared. They never carry hidden-site plan counts. Only Owner and Administrator manage the folder tree; a project Member can organize plans they already have `MANAGE_PLAN` for.
- Folder names contain 1–120 characters after trimming. Nested folders cannot be moved into themselves or descendants. Cross-organization references are rejected.
- Deleting a folder **does not delete files or plans**: direct child folders and plans move to its parent, or the root. Moving a plan never changes its site.
- Uploads reuse the existing image compression and private-storage upload flow. If the upload succeeds but a subsequent folder assignment fails, the page reports that the plan is at the root rather than repeating the upload.
- The sidebar and page share the same organization-keyed server snapshot. Refresh or returning focus reloads changes made by other users. There is no browser-local folder persistence or real-time synchronization.

## Additive API

All paths are under `/api/organizations/{organizationId}` and use the existing session-cookie/CSRF contract.

| Method | Path | Contract |
| --- | --- | --- |
| GET | `/plan-library` | `{folders, sites, plans, canManageFolders}`; each site has `id`, `name`, `canManage` |
| POST | `/plan-folders` | `{name, parentId}` → 201 folder |
| PATCH | `/plan-folders/{id}` | Full `{name, parentId}` replacement → 200 folder; null parent is root |
| DELETE | `/plan-folders/{id}` | Promote contents; 204; never deletes storage objects |
| PUT | `/projects/{siteId}/plans/{id}/folder` | `{folderId}` → 200 plan; null folder is root |

Folder records contain `id`, `name`, `parentId`. Existing site-scoped plan APIs are preserved; plan responses gain nullable `folderId`. Tree mutations and plan-folder assignments serialize on the organization's database row to prevent concurrent cycles and references to deleted folders.

## Database and verification

V22 adds `plan_folder` and nullable `project_plan.folder_id`. Do not edit existing migrations or run development startup against a production database to apply it. Hibernate validation expects the migration to have run.

Focused API tests: `bash mvnw -Dtest=PlanLibraryFlowTest,ProjectPlanFlowTest,ProjectPlanTest test` in `construx`. They use H2 and mocked object storage, not live S3. Dashboard checks: `bun test`, `bun run lint`, `bun run build` in `construx-dashboard`. PostgreSQL migration and browser checks are separate from those checks; see the feature log for observed results and remaining limitations.
