# Producto

↑ [[INDEX]]

Construx es un SaaS multi-tenant para constructoras: **organización → obras (sitios) → personas, tareas, planos, finanzas**. El diferenciador es ubicar personas y trabajo sobre **zonas dibujadas en los planos** de la obra.

## Flujo de usuario
```
Usuario → registro
  ├── Con invitación → entra a la organización (y opcionalmente a una obra)
  └── Sin invitación → crea su organización (queda como Owner)
```
El onboarding (`intent`, `businessType`) es solo una pista descriptiva; los roles vienen de crear la organización o de una invitación (ADR 0002).

## Estado actual (resumen)
| Área | Estado |
|---|---|
| Auth, perfil, onboarding | ✅ |
| Organizaciones, roles, miembros, invitaciones | ✅ |
| Obras, staff, fases, tareas, Gantt | ✅ |
| Finanzas (presupuestos, gastos, resumen org) | ✅ |
| Planos, floor plans, zonas, pines, asignaciones | ✅ |
| Asistencia (check-in por zona) | ✅ |
| Cuadrillas, equipo, documentos, reportes PDF | ✅ |
| Catálogo de precios | 🟡 en reconstrucción (`odd/tasks/prices-reset.md`) |
| Excel | 🟡 local (IndexedDB), migrando a AWS compartido por org |
| CRM, facturación SaaS, waitlist de landing | ❌ → [[06-features-futuras/Backlog]] |

Fuente ampliada (puede estar desactualizada): `.agents/CONTEXT.md`.
