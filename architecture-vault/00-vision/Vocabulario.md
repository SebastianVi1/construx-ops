# Vocabulario

↑ [[INDEX]] · Fuente completa: `GLOSSARY.md`

| UI / negocio | Código backend | Pertenece a |
|---|---|---|
| Company / Empresa | `Organization` | — (raíz del tenant) |
| Miembro | `OrganizationMembership` | Organization + `user-account` |
| Site / Obra | `Project` | Organization |
| Staff de obra | `ProjectAccess` | Project + Membership |
| Phase / Fase | `Goal` | Project |
| Task / Tarea | `Activity` | Goal (ADR 0001) |
| Equipo de tarea | `ActivityAssignee` | Activity + ProjectAccess + rol de tarea (ADR 0005) |
| Plano (archivo) | `ProjectPlan` | Project |
| Floor plan / Zona / Pin | `FloorPlan`, `Zone`, `PlanPin` | Project |
| Cuadrilla | `Crew` | Organization |

Trampa: la tabla de usuarios se llama literalmente `"user-account"` (con comillas en SQL).
