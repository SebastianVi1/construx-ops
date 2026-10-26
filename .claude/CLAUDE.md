# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

This is the `construx-ops` umbrella repo. The three subprojects are git submodules (see `.gitmodules`), each with its own history, commits and branches. Run git commands from inside the subproject you are changing; after committing there, commit the updated submodule pointer here. Clone with `git clone --recurse-submodules`.

| Directory | Role | Stack |
|---|---|---|
| `construx/` | Backend REST API (called `construx-backend` in docs) | Java 21, Spring Boot, Maven wrapper, JPA, PostgreSQL, Spring Security |
| `construx-dashboard/` | Web app users log into | React 19, TypeScript, Vite 8, Bun |
| `construx-landing-page/` | Marketing / early-access site | Astro, Tailwind CSS 4, Bun |

Construx is a multi-tenant SaaS for construction companies (organizations → sites/projects → people, tasks, plans, finance). Read `.agents/CONTEXT.md` first for product vision, status vs vision, known issues and open design decisions. Each subproject has its own `AGENTS.md` / `CLAUDE.md` with detailed conventions; read the one for the subproject you touch. The dashboard's `CLAUDE.md` is more accurate than its `AGENTS.md`.

## Commands

Run each from inside its subproject.

**Backend (`construx/`)**
- `./mvnw compile` · `./mvnw test` · `./mvnw package` · `./mvnw spring-boot:run`
- One test class: `./mvnw -Dtest=GlobalExceptionHandlerTest test`
- Caution: `ConstruxApplicationTests` loads the full context against the configured PostgreSQL, and `ddl-auto=update` can alter that schema. Use a disposable database. OAuth client values come from environment variables.

**Dashboard (`construx-dashboard/`)**
- `bun install`, `bun run dev`, `bun run lint`, `bun run build` (typecheck + bundle), `bun test`
- One test file: `bun test src/features/auth/auth.test.ts`
- Run lint + build + test before finishing. No formatter is configured; don't run Prettier.

**Landing page (`construx-landing-page/`)**
- `bun run dev` / `bun run build` / `bun run preview`. Per its `CLAUDE.md`, start the dev server with `astro dev --background` and manage it with `astro dev stop|status|logs`. No test or lint scripts.

## Architecture

- **How the pieces connect:** the dashboard calls the backend under `/api`. In dev, Vite proxies `/api` to `localhost:8080` (`VITE_API_PROXY_TARGET`); the backend's `FRONTEND_URL` defaults to `localhost:5173`. The landing page is static and does not call the backend.
- **Backend:** modular monolith in `src/main/java/org/andre/construx` with `modules/{identity,organization,project}` and `shared` (config, security, validation, errors). Layering is controllers → services → Spring Data repositories, with entity invariants inside the model classes. Vocabulary mapping: Company = `Organization`, Site = `Project`, site staff = `ProjectAccess`, task = `Activity` (under a `Goal`).
- **Auth** is the only finished vertical: HttpOnly cookies (JWT access token + rotating opaque refresh token), a DB `auth_session` row checked on every request, and CSRF required on all unsafe requests (token from `GET /api/auth/csrf`). Contract details live in `construx/docs/security.md` and `auth.md`.
- **Not wired yet:** organizations, projects, goals and activities exist only as JPA entities with no services or endpoints. `DomainAuthorization` is tested but nothing calls it. The dashboard home view uses mock data.
- **Known pitfalls:** CORS config is not actually active (dev works only via the Vite proxy); the user table is literally named `"user-account"`; no Flyway/Liquibase.

## Conventions

- All UI is bilingual EN/ES in both frontends: add every user-facing string in both languages. Code, identifiers and commit messages are in English.
- Backend: four-space indent, no formatter, match nearby code; commits are short, imperative, lowercase. Dashboard/landing: Conventional Commits (`feat(scope): ...`). No AI/Co-Authored-By attribution anywhere.
- AI tooling artifacts (`.agents/`, `.atl/`, `specs/`, `odd/`, `skills-lock.json`) are not product code; the dashboard repo gitignores them, so don't re-add them there.
