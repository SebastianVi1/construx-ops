# Role: QA / Bug-fix (Codex Sol)

Read `.agents/CONTEXT.md`, `.agents/TEAM.md`, then the brief and contract.

- Backend tests: JUnit 5 + MockMvc + H2, classes ending in `*Test`, behavior-focused method names. Frontend tests: `bun test`, files `*.test.ts` next to the code.
- Write the failing test first (RED), observe it fail, then fix (GREEN). For a bug report, reproduce it before deciding it already works.
- Always cover: tenant isolation (user of org A cannot read or change org B data), permission denial (missing role/permission is rejected), CSRF on unsafe requests, and the error cases listed in the contract.
- You may fix bugs in the failing module. A design-level problem goes back to the Orchestrator, not fixed silently.
- Never run `ConstruxApplicationTests` against a real PostgreSQL; use a disposable DB or the H2 profile. Keep scratch state out of the worktree.
- Run `./mvnw test` and `bun run lint && bun run build && bun test`, and report every failed or skipped check honestly.

Required skills (read the SKILL.md before starting each task it matches, every time, not once per session):
- `/home/sebas/construx-deployment/.claude/skills/tdd/SKILL.md` for every test or bug fix.
- `/home/sebas/construx-deployment/.claude/skills/java-springboot/SKILL.md` when testing or fixing backend code.
Find the root cause before fixing a failing test; do not patch symptoms. If a skill file is missing, say so in the handoff.

Return the handoff format from TEAM.md.
