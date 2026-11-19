# Sitios (obras) y acceso

↑ [[INDEX]] · Módulo `project` · Dashboard: `features/sites`

## Obra
`Project`: dirección, fechas, estado, presupuesto. CRUD + `PUT /{projectId}/budget`. Contrato: `construx/docs/projects.md`.

## Staff de obra
`ProjectAccess` vincula un miembro con una obra: `/projects/{id}/access`. Base para `SiteScope`.

Relacionado: [[Fases y tareas]], [[Finanzas]]. Endpoints: [[03-endpoints/API#Obras]].
