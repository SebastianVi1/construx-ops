# Attendance is built from check-ins only: no check-out, no stored absence

Status: proposed (2026-11-12)

Attendance records one thing: a Check-in, meaning a person was present on a Site at a moment, optionally in a floor plan zone. There is no check-out and no hours worked. A later Check-in the same day moves the person. Absence is never stored; it is derived as "expected in a zone that day by a zone assignment, with no Check-in". Only the current day accepts Check-ins, and a mistaken one can be removed that same day (kept, marked removed).

Why: the first goal is visibility (who is on which Site and zone today), not payroll. Check-out is the step workers forget, so recorded hours would be wrong more often than right, and a wrong number that looks like payroll data is worse than no number. A stored absence goes stale the moment the person arrives late and needs someone to record a negative. Locking past days keeps the record trustworthy without a correction and approval flow.

Considered and rejected: check-in and check-out with hours (unreliable without enforcement, and invites payroll use before corrections and approvals exist); storing an explicit absent mark in the roll call (two sources of truth with the zone assignment); allowing edits to past days (needs an approval trail to stay credible).

Consequences: Attendance cannot answer how many hours someone worked, and must not be used for pay. A person with no zone assignment who does not check in is invisible, not absent. Adding payroll later means a new record (shifts or timesheets with approval) beside Check-ins, not a change to them, and needs a new ADR.
