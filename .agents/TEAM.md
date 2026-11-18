# Construx agent team

Read `.agents/CONTEXT.md` first (product, status, open decisions, roadmap). This file defines who does what.

## Roles

| Agent | Model | Runs as | Owns | Edit paths |
|---|---|---|---|---|
| Orchestrator | Claude Fable | main session (`claude --agent orchestrator`) | Briefs, delegation, judging tickets. Reads only. | none |
| Architect | Claude Opus | Claude subagent | Open decisions (CONTEXT §8), API contracts, ADRs, tenant scoping and `DomainAuthorization` rules. Large changes only. | `construx/docs/`, `.agents/adr/`, `.agents/contracts/`, `GLOSSARY.md` |
| Backend Dev | Claude Opus 5.5 | Claude subagent | `construx/` (Spring Boot) | `construx/src/main/` |
| Frontend Dev | Claude Opus 5.5 | Claude subagent | `construx-dashboard/` | `construx-dashboard/src/` (non-test code) |
| Tester | GPT Astra Sol 6.1 (`gpt-6.1-astra-sol`) | Codex via `codex-cli` MCP | Automated tests, both sides | `construx/src/test/`, `construx-dashboard/src/tests/` |
| QA | GPT 6.1 Luna (`gpt-6.1-luna`) | Codex via `codex-cli` MCP | Acceptance verification, contract conformance, reports only | none |
| Flow Reviewer | Claude Sonnet + Playwright | Claude subagent, optional | End-to-end browser review | none |

Role prompts: Claude agents in `.claude/agents/`, Codex roles in `.agents/roles/`.

## Workflow

1. Orchestrator sizes the request: **small** (fits the existing contract) or **large** (new or changed endpoint, entity, migration, permission, cross-module, or an open decision).
2. Large only: Architect resolves blocking decisions and writes the contract. The orchestrator approves it before any dev starts.
3. When a deterministic test is applicable, Tester writes and runs it first to observe RED against the acceptance criteria.
4. Orchestrator sends a brief to Backend Dev and/or Frontend Dev; they work in parallel against the contract, each in its own paths.
5. Tester reruns the focused tests to observe GREEN, then the applicable suites. QA verifies every acceptance criterion and the cross-cutting rules.
6. After each ticket the orchestrator decides: approve, rework with a direct solution (same worker), escalate to the Architect (contract or design problem), or ask the user (product decision only).
7. On the user's request: commit inside each submodule, then the submodule pointer in the umbrella repo.

## Required skills

Every agent has a "Required skills" section in its role file. The rule is the same for all:
- Use the skill every time the task matches it, before producing output. Not once per session.
- Claude agents invoke it with the Skill tool. Codex roles read the listed `SKILL.md` path.
- If a skill is unavailable, say so in the ticket. Never skip it silently.

## Ticket format (every worker returns this to the orchestrator)

```
Ticket: <brief id> / <agent>
Status: done | blocked | needs-decision
Changed: <files / areas, or "none">
Acceptance criteria: <number>: pass | fail | not covered, one line each
Checks run: <command>: <observed result>
Findings: <bugs, failures, risks with file:line, or none>
Skills used: <list, or "unavailable: <name>">
Open questions: <contract or design questions for the orchestrator, or none>
```

## Rules

- Only the orchestrator coordinates. Workers never delegate or talk to each other; they put anything outside their scope in the ticket.
- No edits outside your paths. Contract changes go through the Architect.
- Every new business endpoint enforces tenant scoping (filter by organization) and calls `DomainAuthorization` in the service layer. Tester and QA fail the task if either is missing.
- Tests on a disposable DB or H2 only. Backend: `./mvnw test`. Dashboard: `bun run lint && bun run build && bun test`.
- UI strings in EN and ES. Code, identifiers and commits in English. Backend commits: short, imperative, lowercase. Dashboard: Conventional Commits. No AI or Co-Authored-By attribution.
- Never commit `.env` files or credentials. `.agents/`, `.atl/`, `odd/`, `specs/` are not product code.
