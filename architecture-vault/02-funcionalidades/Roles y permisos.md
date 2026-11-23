# Roles y permisos

↑ [[INDEX]] · Módulo `organization` · Dashboard: `features/roles`, `features/permissions`, `features/members` · Contrato: `.agents/contracts/roles.md` · ADR 0010 · Spec: issue #102

Cada miembro tiene exactamente un **Rol de organización**: un conjunto de **Permisos** (acción + alcance `OWN` < `PROJECT` < `ORGANIZATION`). Solo lista blanca: lo que el rol no concede está denegado. Tres tipos (`kind`):
- **Owner** (`OWNER`): siempre tiene las 16 acciones en `ORGANIZATION`; no se edita, no se asigna, no se quita.
- **Built-in** (`BUILT_IN`): `ADMINISTRATOR`, `MEMBER`, `WORKER`, `FINANCE`, `RESIDENT`, `SITE_MANAGER`, `SUPERINTENDENT`. Cada empresa puede cambiar sus permisos (no su nombre) y restaurar los valores por defecto; queda `customized` mientras difiera del archivo.
- **Custom** (`CUSTOM`): los crea la empresa, en blanco o duplicando otro rol. Código `CUSTOM_` + 10 de `[A-Z2-7]`, nombre único 1–100 (no puede repetir un nombre Owner/Built-in en EN ni ES), descripción ≤ 280, máximo 30 por empresa.

## Fuente única: archivos de definición (backend)
- `construx/src/main/resources/built-in-roles.yml`: nombres y descripciones EN/ES, grants por defecto, y `owner:` (solo nombres). Reemplaza `seeded-roles.properties`. Código: `BuiltInRoles`.
- `construx/src/main/resources/permission-catalog.yml` + `PermissionAction` (grupo, alcances permitidos, requisitos): el **catálogo de permisos**. Código: `PermissionCatalog`, `PermissionRules`.
- Un archivo inválido detiene el arranque (`RoleDefinitionsCheck`).
- Los códigos de rol y de acción son ids permanentes; solo cambian los nombres visibles.

## Sincronización al arrancar
`BuiltInRoleSync` (`ApplicationReadyEvent`, una transacción, idempotente) aplica el archivo a **todas** las empresas:
- Owner recibe toda acción del catálogo en `ORGANIZATION`.
- Built-in que falta → se crea con los defaults (así se cerró v1-api Q5: empresas viejas sin `RESIDENT`/`SITE_MANAGER`/`SUPERINTENDENT`).
- Built-in sin cambios (`customized = false`) → queda exactamente como el archivo.
- Built-in cambiado → solo recibe el default de acciones que nunca vio (tabla `organization_role_known_action`).
- Built-in que salió del archivo → se convierte en Custom (mismos miembros y permisos).
- Auditoría `ORGANIZATION_ROLE` `SYNC` / `ADOPT` / `CONVERT_TO_CUSTOM`, actor null.

Consecuencia: ya no se escriben backfills de permisos en Flyway. Una acción nueva = catálogo + archivo, y el sync hace el resto. Migración del modelo: `V41__editable_roles.sql` (`description`, `customized`, `version` en `organization_role`).

## Autoridad: "nunca por encima de tu propio rol"
`modules/organization/access/RoleAuthority`. Un rol *cabe* en el que llama si este tiene cada acción del rol con alcance igual o mayor; Owner solo cabe en Owner.
- Crear: `MANAGE_ROLES` y el conjunto nuevo cabe.
- Editar / restaurar / borrar: `MANAGE_ROLES`, no Owner (`ROLE_OWNER_LOCKED`), no tu propio rol (`ROLE_OWN`), el rol actual y el nuevo caben (`ROLE_ABOVE_CALLER`).
- Asignar miembro (`PATCH members`): `MANAGE_MEMBERS`, no a ti mismo, ni hacia ni desde Owner, el rol actual del miembro y el destino caben.
- Invitar: `MANAGE_MEMBERS`, no Owner, el rol cabe.
- El dashboard no recalcula: recibe `editable` y `assignable` por rol en `GET /roles`.

Reglas del conjunto (cada escritura y el archivo): alcance permitido por el catálogo y sin acciones repetidas (`ROLE_SCOPE_INVALID`); requisitos, p. ej. `MANAGE_PLAN` pide `VIEW_PLAN` y `VIEW_PROJECT` (`ROLE_DEPENDENCY_MISSING` con `action` y `requires`). Un conjunto vacío es válido.

Los cambios aplican en la **siguiente request** del miembro, sin re-login (el permiso se lee de la BD al construir el `OrgScope`). Toda escritura se audita (`CREATE`, `UPDATE`, `RESTORE`, `DELETE`; asignaciones `ORGANIZATION_MEMBERSHIP` `ROLE_CHANGE`). Concurrencia: `version` optimista, versión vieja → `409 ROLE_CHANGED`.

## Nombres en todas partes
Todo resumen de rol (`/me`, `myRole`, miembros, invitaciones, staff de obra) lleva `{ code, name, names: { en, es } }` (`RoleNames.of`). El dashboard muestra `roleLabel(role, locale)` = `names[locale] ?? name`; ya no traduce por código.

## Dashboard
- Menú: grupo **People / Personal** con **Members / Miembros** (`/members`, con `MANAGE_MEMBERS`) y **Roles & permissions / Roles y permisos** (`/members/roles`, con `MANAGE_ROLES` o `MANAGE_MEMBERS`). En teléfono y tablet un solo enlace y una tira de pestañas (`PeopleTabs`). Guardia de ruta: `RequirePeopleAccess`. Lógica de menú: `features/organizations/workspaceNav.ts`.
- `RolesPage`: lista con tipo, "Modificado", miembros, descripción; "New role" y "Duplicate" (`RoleFormDialog`).
- `RolePage` (`/members/roles/:code`): pestaña Permisos (`PermissionsTab`, editor por grupo del catálogo con control segmentado; enciende requisitos solo y confirma al bajar; "Restore defaults" con vista previa; nombre/descripción y "Delete role" para Custom con `DeleteRoleDialog`) y pestaña People (`PeopleTab`, solo con `MANAGE_MEMBERS`: titulares activos y suspendidos, cambio de rol, "Add person").
- Members: selector de rol por fila (`RoleSelect`), filtro por rol; la invitación solo ofrece roles `assignable`.
- `/me` se vuelve a leer al volver a la pestaña y al cambiar de ruta (`features/permissions/accessRefresh.ts`, mínimo 30 s).
- API: `features/roles/rolesApi.ts` (Zod), errores `roleErrorKind` / `roleErrorMessage`, textos EN/ES en `features/roles/messages.ts`.

Endpoints: [[03-endpoints/API#Roles y permisos]]. Ver también [[Organizaciones y miembros]], [[01-arquitectura/Seguridad y autorización]].
