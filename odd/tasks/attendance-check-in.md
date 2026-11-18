# Attendance and zone Check-in
Branch: `feat/attendance-check-in` in backend and dashboard; root submodule pointers merged.
Delivery: ask-on-risk. Runners: `bash mvnw test`; `bun run lint`, `bun run build`, `bun test`.

## Specs

S1 (#57, Check in someone else): "Workers without a phone or an account session still need to be recorded. From the Attendance page, on today, a person with the right can check in an absent person; the Check-in keeps who recorded it." A member with `MANAGE_PLAN` may check in any active company member. A Crew leader may check in members of that Crew when the leader can open the Site. Acceptance: absent rows show "Check in" only to permitted members and only today; the sheet opens for that person with the expected zone; unauthorized callers get 403; planners may check in people without Site access; leaders may check in only their Crew; suspended, departed, and unknown targets get 404; the page shows the recorder; no new permission action; English and Spanish strings and tests.

S2 (#58, Crew roll call): "A Crew leader, or a member with `MANAGE_PLAN`, checks in a whole Crew in one action from the Attendance page. The dialog lists the Crew's members pre-ticked; the person unticks whoever is missing and confirms. One Check-in is created per person present, all in one transaction." Acceptance: "Roll call" appears today only for an expected Crew the caller may check in; already-present members are shown and disabled; the Crew assignment zone is preselected and may be changed or cleared; a nonmember in the request rejects all writes with 400; an empty list gets 400; duplicate members result in one check-in; existing same-zone check-ins are skipped; nonleaders and nonplanners get 403; English and Spanish strings, phone width, and tests.

S3 (integration): Implement tickets #53 through #61 on the single integration branch for spec #62, review the integrated change, and resolve tickets according to the GitHub issue tracker after local verification and remote authorization.

## Tasks

- T1 → S1: Complete backend and dashboard #57; route delegated implementer, then merger; done; backend `267c452`, dashboard `e41cf41`.
- T2 → S2: Complete backend and dashboard #58 after T1; route delegated implementers in parallel, then mergers; done; backend `65fe5a6`, dashboard `a32cf59`.
- T3 → S3: Check full spec, review, and integrate root submodule pointers; done; root `cdbbc52`, backend `ac6bd52`, dashboard `d160f08` on main; #53-#62 closed.

## Log

L1 (2026-11-14): "puedes continuar necesito acabar con esos tickets estaba usando $implement-spec"
L2: Earlier local work already integrated #53-#56, #59-#61, and dashboard #60 into the backend/dashboard feature branches. Backend #57 exists at `cdeb306` but is not merged. Dashboard #57 branch contains integration of #56, not the #57 feature. Root has unrelated dirty files and uncommitted submodule pointers; preserve them.
L3: The GitHub issue text and dependency graph were recovered from local Claude Code session `5199d4d9-7bee-49bd-b87a-29100044e770`, record 56 and record 63. Engram mirror pending because memory tools are unavailable in this session.
L4: #57 backend integration passed 697 tests (13 focused); dashboard integration passed lint, build, and 822 tests (51 focused). Both merges were clean and preserve unrelated untracked files.
L5: #58 API decision: GET Attendance includes `me.rollCallCrews`, containing only expected Crews eligible for this caller today, each with `crewId`, `name`, `expectedZone`, and `members` (member reference plus current `checkIn`). POST `/attendance/roll-calls` accepts `{ crewId, membershipIds, zoneId }` and returns a list of created or existing Check-ins. The server validates the complete request before writing in one transaction. This is a project-local design decision because the ticket does not prescribe an API shape.
L6: #58 backend merge passed 702 tests; dashboard merge passed lint, build, and 826 tests. Independent verifier found an S1 blocker: a Crew leader could see the absent-row action for a person outside their Crew. Correction adds per-row `checkInAllowed` from backend authorization and gates the dashboard action on it. RED was observed in backend and dashboard tests; corrected focused tests and 703 backend / 826 dashboard full tests pass. The independent scoped recheck passed, including unchanged data after the unauthorized request.
L7: Receipt-driven development is globally off by user choice, so no native review was started. Engram mirror remains pending because memory tools are unavailable.
L8: Two-axis full-branch review found a confirmed floor-plan overlay bug for absent people with multiple assignments; the dashboard forms bypass a documented shared form convention; Attendance repeats latest-check-in/profile reads; and the branch changes the global default locale outside the attendance spec. A separate browser acceptance check remains pending. One review-fix unit is authorized by the implement-spec workflow before final verification.
L9 (2026-11-15): Claude Code finished T3: backend 704 / dashboard 829 tests pass, browser check of own Check-in, removal, ES and phone width passed. Restored the Spanish default locale that the review fix had reverted (already on main via PR #26). Fast-forwarded main in all three repos, pushed, closed #53-#62.
