# Built-in roles are editable per company and kept in sync from one definition file; nobody acts above their own role

Status: accepted (2026-11-22)

Every company gets the Owner role plus the Built-in roles listed in `built-in-roles.yml`. A company may change a Built-in role's permissions (not its name), restore the defaults, and create its own Custom roles. The definition file stays the single source of truth for Built-in roles. On every boot a sync applies it to every company:
- roles the company never changed follow the file exactly;
- roles the company changed get only the new name and the defaults for actions they have never seen;
- roles added to the file appear everywhere;
- roles removed from the file become Custom roles where they exist.

All role writes, assignments and invitations follow one rule: the role or permission set must fit within the caller's own role. Nobody edits or reassigns their own role.

Why: companies need to adjust "Worker" or "Finance" to how they really work, and forking a copy for every change would leave a pile of near-duplicate roles. Engineers need to rename a role or change its defaults by editing one file. Before this decision that change meant a hand-written Flyway backfill per change (V11, V13, V15, V20) plus edits to the dashboard's role labels. Tracking `customized` and a per-role set of known actions is what lets the file keep moving without overwriting a company's deliberate choices. The fit-within rule is what makes it safe to give `MANAGE_ROLES` to anyone other than the Owner: without it, an Administrator could create or assign a role holding `MANAGE_BUDGET` and escalate themselves or a colleague.

Considered and rejected:
- **Built-in roles locked, custom roles only.** Simpler, but it forces copies and makes the defaults useless to any company that disagrees with one grant.
- **Editable Built-in roles with no sync.** File changes would reach only new companies, so backfill migrations would still be needed forever.
- **Sync that always overwrites.** It erases company choices on every release.
- **Explicit deny rules and per-member overrides.** They need conflict resolution and make "why can this person do X?" hard to answer. One role per member plus Custom roles covers the cases.
- **Fine-grained "edit only what you hold" for roles above the caller.** Hard to explain and test; such roles are read-only instead.

Consequences:
- Flyway migrations no longer grant role permissions. A new action is added to the catalog and to the file, and the sync does the rest, including the Owner role.
- Role and action codes are permanent ids. Renaming means changing display names; removing a Built-in role converts existing copies rather than deleting access.
- Custom role names cannot reuse a Built-in role's EN or ES name, and custom codes live in a separate `CUSTOM_` namespace, so the file can never collide with company data.
- The sync runs at startup in one transaction. With many companies it may need batching, and with several backend instances it needs a lock. Neither applies today.
- Only an Owner can change roles stronger than the Administrator role (e.g. Finance). That is intended.
