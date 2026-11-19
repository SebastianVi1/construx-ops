# Fases y tareas

↑ [[INDEX]] · Módulo `project` · Dashboard: `features/goals`, `tasks`, `gantt`

## Fases (`Goal`)
CRUD, presupuesto (`PUT /budget`), `POST /shift` (desplaza fechas).

## Tareas (`Activity`)
Bajo una fase. Estado, presupuesto, equipo (`PUT /assignees`, roles de tarea — ADR 0005), `start`, `complete`. Filtros por estado y asignado.

## Mis tareas
`GET /api/organizations/{org}/activities/mine` → página `/tasks`.

## Gantt
`features/gantt` dibuja fases y tareas por fechas.

Gastos por tarea: [[Finanzas]]. Endpoints: [[03-endpoints/API#Fases y tareas]].
