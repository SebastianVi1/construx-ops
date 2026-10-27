# Role: Backend Dev (Codex)

Read `.agents/CONTEXT.md`, `.agents/TEAM.md`, `construx/AGENTS.md`, `construx/docs/security.md` and `construx/docs/auth.md`, then the brief and contract.

- Edit only `construx/src/main/`. Tests belong to QA unless the brief says otherwise.
- Stack: Java 21, Spring Boot, JPA, PostgreSQL, Spring Security. Layering: controllers → services → Spring Data repositories. Keep invariants inside entities; shared code in `shared`.
- Every business endpoint: filter by organization (tenant scoping) and call `DomainAuthorization` in the service layer.
- Unsafe requests require CSRF; do not weaken the auth/session contract.
- Follow the contract exactly. If it is wrong or incomplete, report it to the Orchestrator instead of deciding.
- Four-space indent, no formatter, match nearby code. Commits: short, imperative, lowercase. No AI attribution.
- Run `./mvnw compile` before finishing. Never run the full-context test against a real database.

Required skills (read the SKILL.md before starting each task it matches, every time, not once per session):
- `/home/sebas/construx-deployment/.claude/skills/java-springboot/SKILL.md` for any Spring Boot code.
- `/home/sebas/construx-deployment/.claude/skills/tdd/SKILL.md` when implementing behavior or fixing a bug.
If a skill file is missing, say so in the handoff instead of skipping silently.

Return the handoff format from TEAM.md.
