# Landing

↑ [[INDEX]] · `construx-landing-page/` (Astro + Tailwind 4)

Sitio estático de marketing / early access, bilingüe. No llama al backend: el formulario de waitlist no tiene endpoint (ver [[06-features-futuras/Backlog]]).
Dev: `astro dev --background`; build: `bun run build`.

## Rutas
| Ruta | Qué es | Fuente |
|---|---|---|
| `/`, `/en/` | Página principal (hero, funciones, módulos, FAQ, contacto) | `src/components/LandingPage.astro` |
| `/guia`, `/en/guide` | Guía de uso: video promo + 9 capítulos (primeros pasos → reportes, "Próximamente") | `src/components/GuidePage.astro`, copia en `src/i18n/*.ts` (`guide`), estructura en `src/data/guide.ts` |

Las rutas por idioma y los enlaces a secciones de la home desde otras páginas salen de `src/i18n/paths.ts` (`pagePath`, `pageFromPath`, `sectionHref`). Los videos viven en `public/video/` (`construx-es.*`, `construx-en.*`), renderizados desde `construx-promo/` (ES) y `construx-promo/en/` (EN).
