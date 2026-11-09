# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

This is the `construx-ops` umbrella repo. The three subprojects are git submodules (see `.gitmodules`), each with its own history, commits and branches. Run git commands from inside the subproject you are changing; after committing there, commit the updated submodule pointer here. Clone with `git clone --recurse-submodules`.

| Directory | Role | Stack |
|---|---|---|
| `construx/` | Backend REST API (called `construx-backend` in docs) | Java 21, Spring Boot, Maven wrapper, JPA, PostgreSQL, Spring Security |
| `construx-dashboard/` | Web app users log into | React 19, TypeScript, Vite 8, Bun |
| `construx-landing-page/` | Marketing / early-access site | Astro, Tailwind CSS 4, Bun |

Construx is a multi-tenant SaaS for construction companies (organizations → sites/projects → people, tasks, plans, finance). Read `.agents/CONTEXT.md` first for product vision, status vs vision, known issues and open design decisions. Domain vocabulary lives in `GLOSSARY.md`; ADRs and API contracts in `.agents/adr/` and `.agents/contracts/`; an Obsidian architecture vault (start at `architecture-vault/Start Here.md`) maps runtime, request flow and domain. Each subproject has its own `AGENTS.md` / `CLAUDE.md` with detailed conventions; read the one for the subproject you touch. The dashboard's `CLAUDE.md` is more accurate than its `AGENTS.md`.

## Commands

**Full stack (repo root, Docker Compose).** `docker-compose.yml` is the base; layer `docker-compose.dev.yml` (bind mounts, hot reload) or `docker-compose.prod.yml` on top. Secrets go in `docker.env` (copy `docker.env.example`); ports and build-time vars in the root `.env`. Both are gitignored.
- Dev: `docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build` → nginx gateway routes `app.localhost` (dashboard + `/api`, `/oauth2`) and `localhost` (landing) on :80; nginx is the only web entry (backend, dashboard and landing publish no ports); Postgres stays on 127.0.0.1:5433. Gateway hosts/upstreams/ports come from the root `.env` (`.env.example`); template in `nginx/dev/`.
- Frontends hot-reload; after a Java change, `... restart backend`. `down -v` also drops the DB volume.
- Prod overlay publishes only the `nginx` gateway (:80/:443, `nginx/prod/`): it terminates HTTPS with a Let's Encrypt cert from the `certbot` service and routes `DASHBOARD_HOST` (dashboard + `/api`, `/oauth2`) and `LANDING_HOST` (landing). `LANDING_HOST`, `DASHBOARD_HOST` and `LETSENCRYPT_EMAIL` are required in the root `.env`.

Subproject commands run from inside each subproject.

**Backend (`construx/`)**
- `./mvnw compile` · `./mvnw test` · `./mvnw package` · `./mvnw spring-boot:run`
- One test class: `./mvnw -Dtest=GlobalExceptionHandlerTest test`
- Caution: `ConstruxApplicationTests` loads the full context against the configured PostgreSQL and runs the Flyway migrations on it. Use a disposable database. OAuth client values come from environment variables.

**Dashboard (`construx-dashboard/`)**
- `bun install`, `bun run dev`, `bun run lint`, `bun run build` (typecheck + bundle), `bun test`
- One test file: `bun test src/features/auth/auth.test.ts`
- Run lint + build + test before finishing. No formatter is configured; don't run Prettier.

**Landing page (`construx-landing-page/`)**
- `bun run dev` / `bun run build` / `bun run preview`. Per its `CLAUDE.md`, start the dev server with `astro dev --background` and manage it with `astro dev stop|status|logs`. No test or lint scripts.

## Architecture

- **How the pieces connect:** the dashboard calls the backend under `/api`. In dev, Vite proxies `/api` to `localhost:8080` (`VITE_API_PROXY_TARGET`); the backend's `FRONTEND_URL` defaults to `localhost:5173`. The landing page is static and does not call the backend.
- **Backend:** modular monolith in `src/main/java/org/andre/construx` with `modules/{identity,organization,project,plan,pricing,finance}` and `shared` (config, security, validation, errors). Layering is controllers → services → Spring Data repositories, with entity invariants inside the model classes. Vocabulary mapping: Company = `Organization`, Site = `Project`, site staff = `ProjectAccess`, task = `Activity` (under a `Goal`).
- **Auth** is the only finished vertical: HttpOnly cookies (JWT access token + rotating opaque refresh token), a DB `auth_session` row checked on every request, and CSRF required on all unsafe requests (token from `GET /api/auth/csrf`). Contract details live in `construx/docs/security.md` and `construx/auth.md`.
- **v1 domain API:** organizations (seeded roles from `construx/src/main/resources/seeded-roles.properties`), invitations, sites, site access, goals and activities have services and endpoints; every call goes through `MembershipGuard` (404 for non-members) and `DomainAuthorization` (403). Plans, material pricing, budgets and site expenses build on the same guards. Contracts: `construx/docs/` (`organizations.md`, `projects.md`, `plans.md`, `pricing.md`, `user-profile.md`) and `.agents/contracts/v1-api.md`. The dashboard uses them; `features/home/HomePage.tsx` is unrouted mock data.
- **Known pitfalls:** CORS config is not actually active (dev works only via the Vite proxy); the user table is literally named `"user-account"`. Schema changes are Flyway migrations in `construx/src/main/resources/db/migration` (take the next free `V<n>__`); Hibernate only validates (`ddl-auto=validate`), so an entity change without a migration fails at startup.

## Conventions

- All UI is bilingual EN/ES in both frontends: add every user-facing string in both languages. Code, identifiers and commit messages are in English.
- Backend: four-space indent, no formatter, match nearby code; commits are short, imperative, lowercase. Dashboard/landing: Conventional Commits (`feat(scope): ...`). No AI/Co-Authored-By attribution anywhere.
- Agent tooling is tracked in each subproject: skills (`.agents/skills/`, linked from `.claude/skills/`, pinned in `skills-lock.json`), `AGENTS.md` and `CLAUDE.md`. Plans and specs (`specs/`, `.specify/`, `.agents/specs/`), `.claude/settings.local.json` and the skill registry (`.atl/`) are not committed.

## Agent skills

### Issue tracker

Issues live in GitHub Issues (`SebastianVi1/construx-ops`). See `docs/agents/issue-tracker.md`.

### Domain docs

Single-context layout: `GLOSSARY.md` at root, ADRs in `.agents/adr/`. See `docs/agents/domain.md`.
