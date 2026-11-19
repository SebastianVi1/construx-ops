# Floor plans, zonas y pines

↑ [[INDEX]] · Módulo `floorplan` · Dashboard: `features/floor-plans` (`/sites/:siteId/floor-plans`)

El diferenciador del producto: trabajo y personas sobre el plano.

## Floor plan
Subida prefirmada + `complete`, `/state`, `/roster` (personas disponibles).

## Calibración
`PUT/GET /calibration`: escala del plano para medir.

## Zonas
Polígonos sobre el plano. CRUD + `/audit`.

## Asignaciones de zona
Asignar gente/cuadrillas a zonas: crear, `close`, `reassign`, conteos (`/zones/assignment-counts`).

## Pines
Incidencias/notas sobre el plano: estado, fotos (subida prefirmada), auditoría. Contrato: `construx/docs/floor-plan-pins.md`.

Endpoints: [[03-endpoints/API#Floor plans]]. Relacionado: [[Asistencia]].
