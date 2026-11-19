# Backend

↑ [[INDEX]] · Raíz: `construx/src/main/java/org/andre/construx`

## Capas
controller → service → repository (Spring Data). Las invariantes viven en las entidades (`model/`).

## Módulos (`modules/`)
| Módulo | Funcionalidad |
|---|---|
| `identity` | [[02-funcionalidades/Identidad y cuenta]] + config de seguridad |
| `organization` | [[02-funcionalidades/Organizaciones y miembros]] |
| `project` | [[02-funcionalidades/Sitios y acceso]], [[02-funcionalidades/Fases y tareas]] |
| `finance` | [[02-funcionalidades/Finanzas]] |
| `pricing` | [[02-funcionalidades/Precios]] |
| `plan` | [[02-funcionalidades/Planos]] |
| `floorplan` | [[02-funcionalidades/Floor plans, zonas y pines]] |
| `attendance` | [[02-funcionalidades/Asistencia]] |
| `crew` | [[02-funcionalidades/Cuadrillas y equipo]] |
| `documents` | [[02-funcionalidades/Documentos]] |
| `report` | [[02-funcionalidades/Reportes]] |

## `shared/`
`audit`, `config`, `exception` (`GlobalExceptionHandler`), `security`, `storage` (S3, `ObjectStorage`), `time`, `validation`. No importa nada de `modules`.

## Reglas
- `ModuleBoundariesTest` (ArchUnit) vigila las fronteras entre módulos.
- Cruces entre módulos vía servicios públicos tipo directorio (p. ej. `MembershipDirectory`, `PersonDirectory`).
