# Construx — Segundo cerebro (índice principal)

Vault solo Markdown. Cada nota enlaza a su fuente real en el código. Si algo no está aquí, búscalo primero en esta tabla.
Ábrelo en Obsidian (*Open folder as vault*) o léelo en cualquier visor Markdown. Última verificación: 2026-11-19.

## Mapa del vault

| # | Sección | Nota | Qué responde |
|---|---|---|---|
| 0 | Visión | [[00-vision/Producto]] | Qué es Construx, para quién, estado vs visión |
| 0 | Visión | [[00-vision/Vocabulario]] | Company=Organization, Site=Project, Phase=Goal, Task=Activity |
| 1 | Arquitectura | [[01-arquitectura/Sistema]] | Los 3 subproyectos y cómo se conectan |
| 1 | Arquitectura | [[01-arquitectura/Runtime y despliegue]] | Docker Compose, nginx, dev vs prod |
| 1 | Arquitectura | [[01-arquitectura/Backend]] | Monolito modular, capas, módulos, `shared` |
| 1 | Arquitectura | [[01-arquitectura/Seguridad y autorización]] | JWT + refresh, CSRF, `OrgScope`/`SiteScope`, roles |
| 1 | Arquitectura | [[01-arquitectura/Persistencia]] | PostgreSQL, Flyway, JPA validate, S3 |
| 2 | Funcionalidades | [[02-funcionalidades/Identidad y cuenta]] | Registro, login, Google, perfil, onboarding |
| 2 | Funcionalidades | [[02-funcionalidades/Organizaciones y miembros]] | Empresa, roles, miembros, invitaciones |
| 2 | Funcionalidades | [[02-funcionalidades/Sitios y acceso]] | Obras, staff por obra, presupuesto |
| 2 | Funcionalidades | [[02-funcionalidades/Fases y tareas]] | Goals, Activities, equipo, Gantt, mis tareas |
| 2 | Funcionalidades | [[02-funcionalidades/Finanzas]] | Presupuestos, gastos, finanzas de organización |
| 2 | Funcionalidades | [[02-funcionalidades/Precios]] | Catálogo de costos (en reconstrucción) |
| 2 | Funcionalidades | [[02-funcionalidades/Planos]] | Biblioteca de planos por obra |
| 2 | Funcionalidades | [[02-funcionalidades/Floor plans, zonas y pines]] | Zonas, asignaciones, pines, calibración |
| 2 | Funcionalidades | [[02-funcionalidades/Asistencia]] | Check-in por zona, pase de lista |
| 2 | Funcionalidades | [[02-funcionalidades/Cuadrillas y equipo]] | Crews y maquinaria/equipo |
| 2 | Funcionalidades | [[02-funcionalidades/Documentos]] | Carpetas y archivos por obra |
| 2 | Funcionalidades | [[02-funcionalidades/Reportes]] | Reporte PDF de obra |
| 2 | Funcionalidades | [[02-funcionalidades/Excel]] | Hojas de cálculo en el dashboard |
| 3 | Endpoints | [[03-endpoints/API]] | Todos los endpoints REST agrupados por módulo |
| 4 | Frontend | [[04-frontend/Dashboard]] | Rutas, features, capa de API, i18n |
| 4 | Frontend | [[04-frontend/Landing]] | Sitio de marketing (Astro) |
| 5 | Decisiones | [[05-decisiones/ADRs]] | Índice de ADRs y decisiones abiertas |
| 6 | Futuro | [[06-features-futuras/Backlog]] | Features posibles / ideas |
| 6 | Futuro | [[06-features-futuras/_Plantilla feature]] | Plantilla para proponer una feature |

## Índice inverso: ¿dónde está…?

| Busco | Nota | Fuente en código |
|---|---|---|
| Un endpoint concreto | [[03-endpoints/API]] | `construx/src/main/java/org/andre/construx/modules/*/controller/` |
| Una pantalla del dashboard | [[04-frontend/Dashboard]] | `construx-dashboard/src/App.tsx` |
| Permisos de un rol | [[01-arquitectura/Seguridad y autorización]] | `construx/src/main/resources/seeded-roles.properties` |
| Migraciones de BD | [[01-arquitectura/Persistencia]] | `construx/src/main/resources/db/migration/` |
| Contrato de API | [[03-endpoints/API]] | `.agents/contracts/v1-api.md`, `construx/docs/*.md` |
| Glosario completo | [[00-vision/Vocabulario]] | `GLOSSARY.md` |
| Por qué se decidió X | [[05-decisiones/ADRs]] | `.agents/adr/` |
| Variables de entorno | [[01-arquitectura/Runtime y despliegue]] | `.env.example`, `docker.env.example` |
| El vault anterior | `_archivo-anterior/` | Notas y canvas previos (referencia histórica) |

## Cómo mantenerlo
- Una nota por funcionalidad; subtemas como `##` dentro de la nota.
- Toda nota nueva se registra en la tabla **Mapa del vault**.
- Cada afirmación apunta a un archivo fuente; si el código cambia, actualiza la nota y la fecha de verificación.
- Ideas nuevas → copia [[06-features-futuras/_Plantilla feature]] y enlázala desde [[06-features-futuras/Backlog]].
