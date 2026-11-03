# Repository Guidelines

## Project Structure & Module Organization

This repository coordinates the Construx stack through Docker Compose and three Git submodules:

- `construx/`: Java 21/Spring Boot API; production code in `src/main/java`, configuration in `src/main/resources`, tests in `src/test/java`.
- `construx-dashboard/`: React/TypeScript dashboard; feature modules and colocated tests in `src/`, static assets in `public/`.
- `construx-landing-page/`: Astro marketing site; components, pages, and bilingual content in `src/`, public assets in `public/`.
- `architecture-vault/` and `GLOSSARY.md`: architecture references and domain terminology.

Read each submodule's contributor instructions before editing it. Keep application changes in the owning submodule; update root submodule pointers deliberately.

## Build, Test, and Development Commands

Run the stack from this repository root:

```sh
git submodule update --init --recursive
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build
```

The first command initializes submodules; the second starts PostgreSQL, the API, dashboard, and landing site with development settings.

Run application commands inside the indicated submodule:

- Backend: `bash mvnw test` runs tests; `bash mvnw spring-boot:run` starts the API.
- Dashboard: `bun run dev`, `bun run lint`, `bun test`, and `bun run build` start development, lint, test, and type-check/build respectively.
- Landing: `bun run dev` starts Astro; `bun run build` generates the static site.

There is no root frontend build script.

## Coding Style & Naming Conventions

Match surrounding code: four-space Java indentation, two-space dashboard TypeScript, and tabs in existing landing files. Use PascalCase component/class names and camelCase functions. Dashboard linting uses ESLint. Keep English/Spanish landing dictionaries synchronized.

## Testing Guidelines

Use JUnit/Spring tests named `*Test.java` or `*Tests.java`; dashboard Bun tests use `*.test.ts`. Add regression tests for behavior changes. For landing copy, build both locales and inspect generated content; no dedicated test script is currently defined. Report skipped checks and distinguish mocked checks from live integration verification.

## Commit & Pull Request Guidelines

Follow existing Conventional Commit patterns, such as `feat(docker): ...`, `fix: ...`, and `docs: ...`. Do not add AI attribution. Describe scope, linked issues, verification commands/results, and submodule revisions in PRs; include screenshots for visual changes. Preserve unrelated local work.

## Security & Configuration

Use `docker.env.example` to configure local `docker.env`; never overwrite an existing secrets file. Keep credentials out of commits, logs, and screenshots. Avoid `docker compose down -v` unless database deletion is explicitly intended.
