# Guía de inicio

↑ [[INDEX]] · Módulo `organization` · Dashboard: `features/guide` · Spec: issue #83

Checklist "Primeros pasos" para miembros nuevos. Cada paso se marca solo cuando el miembro hace la acción de verdad, y puede lanzar un tour con spotlight (driver.js) sobre su página. Se abre sola una vez, después del onboarding de dos preguntas (ADR 0002), que no reemplaza.

## Progreso (backend)
Por `OrganizationMembership`: un usuario en dos empresas tiene dos progresos. Tablas `guide_progress` (`dismissed_at`, `updated_at`) y `guide_progress_step` (`step_id`, `status` `COMPLETED` | `SKIPPED`), migración `V40__guide_progress.sql`. Sin fila = nunca la vio, y solo entonces se abre sola; V40 crea la fila ya descartada para las membresías existentes. `GuideController` y `GuideService` con `OrgScope` y sin permiso: cada miembro solo lee y escribe su propio progreso. Ids de paso `^[a-z][a-z0-9-]{0,63}$`, máximo 50 por miembro. Contrato: `construx/docs/guide.md`.

## Secciones y pasos (dashboard)
El backend no conoce la lista de pasos: vive en `features/guide/catalog.ts` como datos (`guideSections`, `guideSteps`, `guidePages`) y el texto EN/ES en `messages.ts`. Quién ve cada sección sale de los permisos, no del nombre del rol:
- **Dirige tu empresa** (`owner`): `MANAGE_MEMBERS` + `MANAGE_PROJECT` de empresa. Crear obra, datos de la obra, invitar, equipo de obra, crear fase, asignar tarea.
- **Gestiona tus obras** (`siteManager`): `MANAGE_GOAL` + `ASSIGN_ACTIVITY` en cualquier alcance, salvo quien ya ve `owner`. Abrir obra, datos, fase, tarea. Lo reciben Jefe de Obra, Residente, Superintendente y Miembro.
- **Finanzas** (`finance`): `MANAGE_BUDGET` de empresa. Presupuesto de obra, gasto, finanzas de la empresa.

Un paso que el miembro no puede hacer se oculta y no cuenta. Sin ninguna sección, el miembro ve un enlace a la guía larga del landing.

## Cómo se marcan
Las páginas llaman `markGuideStep(stepId, organizationId)` después de que la llamada a la API responde bien (helpers como `saveSiteBudget`, `saveExpense`, `loadSite`). El botón "?" de cada página (`GuideHelpButton`) repite sus tours; los elementos llevan `data-tour`. En teléfono la guía es una hoja inferior y no hay spotlight.

## Agregar una sección o paso
Solo entradas en el catálogo, texto EN/ES, `data-tour`, `GuideHelpButton` y `markGuideStep`; ningún cambio de backend. Receta con el ejemplo de Precios (espera a que vuelva el catálogo, ver [[Precios]]): `construx-dashboard/src/features/guide/README.md`.

Endpoints: [[03-endpoints/API#Guía de inicio]].
