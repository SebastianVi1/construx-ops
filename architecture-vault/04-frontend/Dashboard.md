# Dashboard

↑ [[INDEX]] · `construx-dashboard/` · Convenciones: su `CLAUDE.md`

## Estructura
- Rutas: `src/App.tsx`. Una carpeta por feature en `src/features/`; cada una con su `*Api.ts` (fetch + validación Zod).
- Bilingüe EN/ES (`src/i18n`) — todo texto visible en ambos idiomas.
- `features/home/HomePage.tsx` es mock sin ruta.

## Rutas
| Ruta | Feature | Funcionalidad |
|---|---|---|
| `/login`, `/register`, `/forgot-password`, `/reset-password`, `/verify-email`, `/auth/complete` | auth | [[02-funcionalidades/Identidad y cuenta]] |
| `/organizations/new`, `/invitations/accept`, `/members` | organizations, invitations, members | [[02-funcionalidades/Organizaciones y miembros]] |
| `/sites`, `/sites/:siteId` | sites | [[02-funcionalidades/Sitios y acceso]] |
| `/sites/:siteId/phases`, `.../phases/:goalId/tasks/:taskId`, `/tasks` | goals, tasks, gantt | [[02-funcionalidades/Fases y tareas]] |
| `/finance` | org-finance, finance | [[02-funcionalidades/Finanzas]] |
| `/prices` | prices | [[02-funcionalidades/Precios]] |
| `/sites/:siteId/plans` (+ `/folders/:folderId`) | plans | [[02-funcionalidades/Planos]] |
| `/sites/:siteId/floor-plans` (+ `/:floorPlanId`) | floor-plans | [[02-funcionalidades/Floor plans, zonas y pines]] |
| `/sites/:siteId/attendance` | attendance | [[02-funcionalidades/Asistencia]] |
| `/crews`, `/equipment` | crews | [[02-funcionalidades/Cuadrillas y equipo]] |
| `/documents` (+ `/sites/:siteId`, `/folders/:folderId`) | documents | [[02-funcionalidades/Documentos]] |
| `/excel` (+ `/folders/:folderId`, `/:fileId`) | excel | [[02-funcionalidades/Excel]] |
| `/account` | profile | [[02-funcionalidades/Identidad y cuenta]] |

## Comandos
`bun run lint && bun run build && bun test` antes de terminar.
