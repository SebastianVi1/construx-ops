# Organizaciones y miembros

↑ [[INDEX]] · Módulo `organization` · Dashboard: `features/organizations`, `members`, `invitations`, `permissions`

## Organización
CRUD en `/api/organizations`. Crearla siembra los 5 roles y deja al creador como Owner. Contrato: `construx/docs/organizations.md`.

## Miembros y roles
`/me` (mi membresía y permisos), `/roles`, `/members` (cambiar rol, estado, eliminar).

## Invitaciones
Invitación a la organización con rol y obra opcional; aceptar crea membresía (+ `ProjectAccess` si hay obra) en una transacción. Aceptar: `POST /api/invitations/accept`. Asignaciones solo internas (ADR 0003).

Endpoints: [[03-endpoints/API#Organizaciones]].
