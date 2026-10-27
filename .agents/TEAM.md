# Construx agent team

Read `.agents/CONTEXT.md` first (product, status, open decisions, roadmap). This file defines who does what.

## Roles

| Agent | Model | Owns | Edit paths |
|---|---|---|---|
| Orchestrator | Codex | Task briefs, assignment, decisions. Never codes. | `.agents/briefs/` |
| Lead Architect | Claude Fable 5.1 | Open decisions (CONTEXT §8), API contracts, ADRs, tenant scoping and `DomainAuthorization` rules | `construx/docs/`, `.agents/adr/` |
| Frontend Dev | Claude Opus 5.5 | `construx-dashboard/` | `construx-dashboard/src/` |
| Backend Dev | Codex | `construx/` (Spring Boot) | `construx/src/main/` |
| QA / Bug-fix | Codex Sol | Tests and fixes, both sides | `*/src/test/`, `*.test.ts`, plus fixes in the failing module |
| Flow Reviewer | Claude Sonnet 5.5 + Playwright | End-to-end flow review | none (reports only) |

Role prompts: Claude agents in `.claude/agents/`, Codex roles in `.agents/roles/`.

## Workflow per roadmap item

1. Orchestrator writes a brief in `.agents/briefs/<item>.md`: goal, acceptance criteria, agents, allowed paths.
2. Architect resolves blocking open decisions and writes the contract (endpoints, DTOs, errors, permissions).
3. Backend Dev and Frontend Dev work in parallel against the contract, in their own paths only.
4. QA writes tests (RED first), fixes failures, runs the full checks.
5. Flow Reviewer drives the real app and reports findings.
6. Orchestrator decides: ship, rework (naming the agent), or escalate to the Architect. Real product decisions go to the user.
7. Commit inside each submodule, then the submodule pointer in the umbrella repo.

## Required skills

Every agent has a "Required skills" section in its role file. The rule is the same for all:
- Use the skill every time the task matches it, before producing output. Not once per session.
- Claude agents invoke it with the Skill tool (they have it enabled). Codex roles read the listed `SKILL.md` path.
- If a skill is unavailable, say so in the handoff. Never skip it silently.

| Agent | Skills |
|---|---|
| Architect | `superpowers:brainstorming`, `domain-modeling`, `java-springboot` |
| Frontend Dev | `tdd`, `vercel-react-best-practices`, `frontend-design`, `ui-taste`, `superpowers:verification-before-completion` |
| Backend Dev | `java-springboot`, `tdd` |
| QA / Bug-fix | `tdd`, `java-springboot` |
| Flow Reviewer | `agent-browser`, `superpowers:verification-before-completion` |

## Handoff format (every worker returns this, short)

```
Task: <brief id>
Changed: <files / areas>
Skills used: <list, or "unavailable: <name>">
Checks run: <command>: <observed result>
Open questions: <or none>
```

## Rules

- Only the Orchestrator coordinates across agents. Workers do not delegate to each other.
- No edits outside your paths. Contract changes go through the Architect.
- Every new business endpoint enforces tenant scoping (filter by organization) and calls `DomainAuthorization` in the service layer. QA fails the task if either is missing.
- Tests: RED before fix. Backend: `./mvnw test` on a disposable DB or H2 (`ddl-auto=update` alters schema). Dashboard: `bun run lint && bun run build && bun test`.
- UI strings in EN and ES. Code, identifiers and commits in English. Backend commits: short, imperative, lowercase. Dashboard: Conventional Commits. No AI or Co-Authored-By attribution.
- Never commit `.env` files or credentials. `.agents/`, `.atl/`, `odd/`, `specs/` are not product code.
