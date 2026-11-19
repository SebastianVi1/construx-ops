# Finanzas

↑ [[INDEX]] · Módulo `finance` · Dashboard: `features/finance`, `org-finance`

## Presupuesto y gastos de obra
`GET /budget`, CRUD `/expenses` por obra; también a nivel tarea (`.../activities/{id}/budget|expenses`).

## Finanzas de organización
`/finance/summary` y `/finance/expenses/monthly`. Solo cuentan obras con presupuesto (ADR 0006). Contrato: `construx/docs/org-finance.md`.

## Mano de obra
El costo laboral se acumula por día de check-in (ADR 0009) → ver [[Asistencia]].

Endpoints: [[03-endpoints/API#Finanzas]].
