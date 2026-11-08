# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Detailed conventions live in `.claude/CLAUDE.md`. This file adds a quick reference layer.

## Repository layout

Three Git submodules under one Docker Compose umbrella:

| Directory | Role | Stack |
|---|---|---|
| `construx/` | Backend REST API | Java 21, Spring Boot, Maven, JPA, PostgreSQL |
| `construx-dashboard/` | Web dashboard | React 19, TypeScript, Vite, Bun |
| `construx-landing-page/` | Marketing site | Astro, Tailwind CSS 4, Bun |

After cloning: `git submodule update --init --recursive`

## Commands

**Dev stack (repo root)**
```sh
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build
# via nginx: dashboard+API http://app.localhost  landing http://localhost
# no direct web ports; DB on 127.0.0.1:5433
docker compose -f docker-compose.yml -f docker-compose.dev.yml restart backend   # after Java changes
```

**Backend (`construx/`)**
```sh
./mvnw test
./mvnw -Dtest=GlobalExceptionHandlerTest test   # single class
./mvnw spring-boot:run
```
> `ConstruxApplicationTests` loads the full Spring context against a real Postgres — use a disposable DB.

**Dashboard (`construx-dashboard/`)**
```sh
bun install && bun run dev
bun run lint && bun run build && bun test        # run all three before finishing
bun test src/features/auth/auth.test.ts          # single file
```

**Landing (`construx-landing-page/`)**
```sh
astro dev --background    # start
astro dev stop|status|logs
bun run build
```

## Architecture notes

- **API → Dashboard**: Vite proxies `/api` to `localhost:8080` in dev (`VITE_API_PROXY_TARGET`). CORS is intentionally disabled — dev works only through this proxy.
- **Auth**: HttpOnly JWT + rotating opaque refresh token, `auth_session` row checked on every request, CSRF required on unsafe methods. Details: `construx/docs/security.md` and `construx/auth.md`.
- **Schema changes**: Flyway only — add `V<n>__*.sql` in `construx/src/main/resources/db/migration`. Hibernate is set to `validate`; a missing migration crashes startup.
- **Domain vocabulary**: `Organization` = Company, `Project` = Site, `Activity` = Task. Full glossary in `GLOSSARY.md`.
- **User table**: named `"user-account"` (quoted in SQL).

## Conventions

- All user-facing strings must be bilingual EN/ES. Code, identifiers, and commit messages are English only.
- Conventional Commits for dashboard/landing (`feat(scope): …`); short imperative lowercase for backend.
- No AI/Co-Authored-By attribution in commits.
- Read the subproject's own `CLAUDE.md` / `AGENTS.md` before editing it.
- Commit submodule pointer updates from the root after committing inside the submodule.
