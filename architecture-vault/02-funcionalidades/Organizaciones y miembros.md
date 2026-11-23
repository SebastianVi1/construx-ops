# Organizaciones y miembros

↑ [[INDEX]] · Módulo `organization` · Dashboard: `features/organizations`, `members`, `invitations`, `permissions`, `roles`

## Organización
CRUD en `/api/organizations`. Crearla crea el rol Owner más los Built-in de `built-in-roles.yml` y deja al creador como Owner. Contrato: `construx/docs/organizations.md`.

## Miembros y roles
`/me` (mi membresía y permisos), `/members` (cambiar rol, estado, eliminar; filtro `?role=`). Roles editables, roles propios, asignación y la regla "nunca por encima de tu propio rol": [[Roles y permisos]]. En el dashboard Miembros vive bajo el grupo **People / Personal** (`/members`).

## Invitaciones
Invitación a la organización con rol y obra opcional; aceptar crea membresía (+ `ProjectAccess` si hay obra) en una transacción. Aceptar: `POST /api/invitations/accept`. Solo se invita con un rol `assignable` (no Owner, cabe en el rol de quien invita). Asignaciones solo internas (ADR 0003).

Endpoints: [[03-endpoints/API#Organizaciones]].
