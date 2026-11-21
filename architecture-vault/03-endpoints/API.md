# API (endpoints)

↑ [[INDEX]] · Fuente: `construx/.../modules/*/controller/*Controller.java` · Contratos: `.agents/contracts/v1-api.md`, `construx/docs/`

Prefijos: `ORG = /api/organizations/{organizationId}` · `SITE = ORG/projects/{projectId}` · `TASK = SITE/goals/{goalId}/activities/{activityId}`

## Identidad
| Método | Ruta |
|---|---|
| POST | `/api/auth/register`, `/resend`, `/verify`, `/login`, `/refresh`, `/logout` |
| POST | `/api/auth/password`, `/password/forgot`, `/password/reset`, `/google/link` |
| GET | `/api/auth/me`, `/api/auth/csrf` |
| GET, PUT | `/api/profile` |
| POST | `/api/profile/avatar/uploads` |
| PUT, DELETE | `/api/profile/avatar` |
| GET, PUT | `/api/onboarding` |

## Organizaciones
| Método | Ruta |
|---|---|
| POST, GET | `/api/organizations` |
| GET, PATCH, DELETE | `ORG` |
| GET | `ORG/me`, `ORG/roles`, `ORG/members` |
| PATCH, DELETE | `ORG/members/{membershipId}` |
| PATCH | `ORG/members/{membershipId}/status` |
| POST, GET | `ORG/invitations` |
| DELETE | `ORG/invitations/{invitationId}` |
| POST | `/api/invitations/accept` |

## Guía de inicio
Progreso propio del miembro, sin permiso (`OrgScope`). Contrato: `construx/docs/guide.md` · [[02-funcionalidades/Guía de inicio]]

| Método | Ruta |
|---|---|
| GET, PUT | `ORG/guide` |
| PUT | `ORG/guide/steps/{stepId}` |

## Obras
| Método | Ruta |
|---|---|
| POST, GET | `ORG/projects` |
| GET, PATCH | `SITE` |
| PUT | `SITE/budget` |
| GET, POST | `SITE/access` |
| DELETE | `SITE/access/{accessId}` |

## Fases y tareas
| Método | Ruta |
|---|---|
| POST, GET | `SITE/goals` |
| GET, PATCH, DELETE | `SITE/goals/{goalId}` |
| PUT | `SITE/goals/{goalId}/budget` |
| POST | `SITE/goals/{goalId}/shift` |
| POST, GET | `SITE/goals/{goalId}/activities` |
| GET, PATCH, DELETE | `TASK` |
| PUT | `TASK/budget`, `TASK/assignees` |
| POST | `TASK/start`, `TASK/complete` |
| GET | `ORG/activities/mine` |

## Finanzas
| Método | Ruta |
|---|---|
| GET | `SITE/budget` |
| GET, POST | `SITE/expenses` |
| PATCH, DELETE | `SITE/expenses/{expenseId}` |
| GET | `TASK/budget` |
| GET, POST | `TASK/expenses` |
| GET | `ORG/finance/summary`, `ORG/finance/expenses/monthly` |

## Precios
🟡 En reconstrucción — ver [[02-funcionalidades/Precios]].

## Planos
| Método | Ruta |
|---|---|
| POST | `SITE/plans/uploads`, `SITE/plans/{planId}/complete` |
| GET | `SITE/plans`, `SITE/plans/{planId}` |
| DELETE | `SITE/plans/{planId}` |
| GET | `ORG/plan-library` |
| POST | `ORG/plan-folders` |
| PATCH, DELETE | `ORG/plan-folders/{folderId}` |
| PUT | `SITE/plans/{planId}/folder` |

## Floor plans
Prefijo `FP = SITE/floor-plans/{floorPlanId}`

| Método | Ruta |
|---|---|
| POST | `SITE/floor-plans/uploads`, `FP/complete` |
| GET | `SITE/floor-plans`, `SITE/floor-plans/roster`, `FP`, `FP/state` |
| DELETE | `FP` |
| PUT, GET | `FP/calibration` |
| POST, GET | `FP/zones` |
| PATCH, DELETE | `FP/zones/{zoneId}` |
| GET | `FP/zones/{zoneId}/audit` |
| POST, GET | `FP/zones/{zoneId}/assignments` |
| POST | `FP/zones/{zoneId}/assignments/{id}/close`, `.../reassign` |
| GET | `FP/assignments`, `FP/zones/assignment-counts` |
| POST | `FP/pins/photo-uploads` |
| POST, GET | `FP/pins` |
| GET, PATCH, DELETE | `FP/pins/{pinId}` |
| POST | `FP/pins/{pinId}/status`, `FP/pins/{pinId}/photos` |
| DELETE | `FP/pins/{pinId}/photos/{photoId}` |
| GET | `FP/pins/{pinId}/audit` |

## Asistencia
| Método | Ruta |
|---|---|
| GET | `SITE/attendance`, `SITE/attendance/zones` |
| POST | `SITE/attendance/check-ins`, `SITE/attendance/roll-calls` |
| DELETE | `SITE/attendance/check-ins/{checkInId}` |

## Cuadrillas y equipo
| Método | Ruta |
|---|---|
| POST, GET | `ORG/crews` |
| DELETE | `ORG/crews/{crewId}` |
| POST | `ORG/crews/{crewId}/members` |
| DELETE | `ORG/crews/{crewId}/members/{membershipId}` |
| POST, GET | `ORG/equipment` |
| PATCH, DELETE | `ORG/equipment/{equipmentId}` |

## Documentos
| Método | Ruta |
|---|---|
| GET, POST | `SITE/document-folders` |
| DELETE | `SITE/document-folders/{folderId}` |
| GET, POST | `SITE/document-folders/{folderId}/entries` |
| POST | `SITE/document-folders/{folderId}/entries/upload-url` |
| DELETE | `SITE/document-folders/{folderId}/entries/{entryId}` |
| GET | `SITE/document-folders/search` |

## Reportes
| Método | Ruta |
|---|---|
| POST, GET | `SITE/reports` |
| GET | `SITE/reports/{reportId}/download` |

## Otros
| Método | Ruta | Nota |
|---|---|---|
| PUT | `/api/storage/upload` | `shared/storage/controller/S3Controller` |
| GET | `/api/test` | placeholder (`RestControllerTest`) |
