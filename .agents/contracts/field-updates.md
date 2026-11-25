# Field updates by WhatsApp (v1, no AI)

Status: approved in the grilling session of 2026-11-24 (Q1 to Q37). ADR: `.agents/adr/0011-field-updates-by-whatsapp-menus.md`.

Vocabulary (`GLOSSARY.md`): **Field update**, **Linked number**, **Progress note**, plus **Site**, **Task**, **Team**, **Member**. In code: Site = `Project`, Task = `Activity`, Phase = `Goal`. A Field update is never called a "report" (that is the **Site Report** PDF).

Dashboard endpoints follow the existing rules: cookie session, CSRF header on unsafe requests, and `ProblemDetail` errors with a `code` property.

## 1. Decisions

| # | Decision |
|---|---|
| D1 | A Field update can start a Task, finish a Task, or add a Progress note. It cannot create Tasks, Check-ins, Expenses or Pins in v1. (Q3) |
| D2 | WhatsApp gives exactly the reach of the app: the action is checked with `SiteScope` for the user behind the Linked number. A Worker (`MANAGE_ACTIVITY: OWN`) only changes Tasks whose Team they are in. (Q2) |
| D3 | The flow uses interactive lists and buttons, not typed text. One Task per round, then "Another task". (Q4, Q18) |
| D4 | Nothing is saved until the person confirms a summary that uses the stored Site and Task names. NO cancels; there is no correction dialog. (Q5, Q7, Q8) |
| D5 | One WhatsApp number per user and one user per number. A number is linked by sending a one-time code from that number. If the number was linked to another account, it moves to the new one and the old account gets an email. (Q6, Q10, Q11, Q29, Q30) |
| D6 | The bot speaks the language (`es`/`en`) stored on the Linked number. (Q19) |
| D7 | A session (menu or pending summary) expires after 30 minutes idle. A new message after expiry starts over. (Q9, Q23) |
| D8 | On YES everything is checked again: link, account enabled, membership active, Site access, permission, Task status. (Q23, Q26) |
| D9 | Up to 5 photos per Field update. They are stored on the Progress note and never on a Pin. (Q33 to Q36) |
| D10 | Progress notes can also be written in the dashboard with the same permission. They are never edited or deleted. (Q12, Q28) |
| D11 | One Construx number on Meta's Cloud API. No templates, no notifications, no per-company switch. (Q24, Q27, Q31) |
| D12 | Construx keeps only what is saved plus audit events. Raw webhook logs are deleted after 30 days. (Q37) |

## 2. Data model (migration `V42__field_updates.sql`)

All tables must run on PostgreSQL and on H2 in `MODE=PostgreSQL`.

**`whatsapp_link`**: one row per Linked number.

| Column | Type | Meaning |
|---|---|---|
| `id` | `uuid` pk | |
| `user_account_id` | `uuid not null unique` → `"user-account"` | One number per user |
| `wa_id` | `varchar(20) not null unique` | Sender id from Meta (digits only, E.164 without `+`). One user per number |
| `language` | `varchar(2) not null` | `es` or `en` |
| `linked_at` | `timestamptz not null` | |

**`whatsapp_link_code`**: one active code per user.

| Column | Type | Meaning |
|---|---|---|
| `user_account_id` | `uuid` pk → `"user-account"` | A new code replaces the old one |
| `code_hash` | `varchar(64) not null` | SHA-256 of the code; the plain code is never stored |
| `language` | `varchar(2) not null` | Language of the dashboard when the code was made |
| `expires_at` | `timestamptz not null` | 10 minutes after creation |

**`whatsapp_session`**: the conversation state of one number (at most one).

| Column | Type | Meaning |
|---|---|---|
| `wa_id` | `varchar(20)` pk | |
| `step` | `varchar(30) not null` | `PICK_SITE`, `PICK_TASK`, `PICK_ACTION`, `WRITE_NOTE`, `ASK_PHOTOS`, `ADD_PHOTOS`, `CONFIRM` |
| `organization_id`, `project_id`, `goal_id`, `activity_id` | `uuid` null | Choices so far |
| `action` | `varchar(10)` null | `START`, `FINISH`, `NOTE` |
| `note_text` | `varchar(1000)` null | |
| `task_page` | `int not null default 0` | "See more" paging |
| `updated_at` | `timestamptz not null` | Idle expiry is 30 minutes from here |

**`whatsapp_pending_photo`**: photos received before YES.

| Column | Type | Meaning |
|---|---|---|
| `id` | `uuid` pk | |
| `wa_id` | `varchar(20) not null` → `whatsapp_session` (cascade) | |
| `storage_key` | `varchar(300) not null` | Private S3 key |
| `content_type` | `varchar(50) not null` | `image/jpeg` or `image/png` |
| `size_bytes` | `bigint not null` | |

**`progress_note`** and **`progress_note_photo`**: new data in the project module.

| Column | Type | Meaning |
|---|---|---|
| `progress_note.id` | `uuid` pk | |
| `activity_id` | `uuid not null` → `activity` | |
| `author_membership_id` | `uuid not null` → `organization_membership` | |
| `text` | `varchar(1000)` null | Text, photos or both. At least one is required |
| `source` | `varchar(10) not null` | `APP` or `WHATSAPP` |
| `created_at` | `timestamptz not null` | |
| `progress_note_photo.id` | `uuid` pk | |
| `progress_note_id` | `uuid not null` → `progress_note` | At most 5 per note |
| `storage_key`, `content_type`, `size_bytes`, `position` | | `position` 0–4 |

Rules for the cleanup job (every 5 minutes):
- Delete sessions idle for 30 minutes or more, together with their pending photos and the matching S3 objects.
- Delete expired link codes.

## 3. Module layout

- **New module `modules/messaging`**:
  - Meta client (send text, list and buttons; download media).
  - Webhook controller.
  - Signature check.
  - Session state machine.
  - Link service.
- **Business work goes through public services only**:
  - `ActivityService.start` / `complete`, called with a `SiteScope` from `SiteScopes.site(userId, organizationId, siteId)`.
  - A new `ProgressNoteService.add(SiteScope, goalId, activityId, text, photos, source)`.
- **`ModuleBoundariesTest`**:
  - `messaging` may depend on `project`, `organization` and `identity` services and on `shared`.
  - No other module depends on `messaging`.
- **Audit (`shared/audit`)**: `start` and `complete` are not audited today. Add:

  | Entity | Actions |
  |---|---|
  | `ACTIVITY` | `START`, `COMPLETE` |
  | `PROGRESS_NOTE` | `CREATE` |
  | `WHATSAPP_LINK` | `LINK`, `UNLINK`, `MOVE` |

  The after-state carries `"source": "WHATSAPP" | "APP"`.

Configuration (all from environment, never committed):
- `WHATSAPP_PHONE_NUMBER_ID`
- `WHATSAPP_ACCESS_TOKEN`
- `WHATSAPP_APP_SECRET`
- `WHATSAPP_VERIFY_TOKEN`
- `WHATSAPP_DISPLAY_NUMBER`, the number shown in the dashboard.

## 4. Endpoints

### 4.1 Dashboard: Linked number (`/api/profile/whatsapp`)

| Method and path | Body / response | Notes |
|---|---|---|
| `GET /api/profile/whatsapp` | `{ linked: bool, number: "+52…" \| null, language: "es"\|"en" \| null, linkedAt, construxNumber: "+1…" }` | `number` shown masked in the UI except the last 4 digits |
| `POST /api/profile/whatsapp/link-code` | `{ language }` → `{ code: "CX-4821", expiresAt, construxNumber, waMeUrl }` | Replaces any active code. `waMeUrl` = `https://wa.me/<construx>?text=CX-4821` |
| `PUT /api/profile/whatsapp/language` | `{ language }` → same as GET | `404 WHATSAPP_NOT_LINKED` if not linked |
| `DELETE /api/profile/whatsapp` | `204` | Unlinks and clears the session |

The code format is `CX-` plus 4 digits, compared after trimming and uppercasing. Accept 10 wrong codes per number per hour; after that, ignore the number for an hour.

### 4.2 Dashboard: Progress notes

Under `/api/organizations/{organizationId}/projects/{projectId}/goals/{goalId}/activities/{activityId}`:

| Method and path | Permission | Notes |
|---|---|---|
| `GET /progress-notes` | `VIEW_ACTIVITY` | Newest first: `{ id, text, source, author: { membershipId, name }, createdAt, photos: [{ id, url }] }`. `url` is a presigned 10-minute download |
| `POST /progress-notes/photo-uploads` | `MANAGE_ACTIVITY` (Team member for `OWN`) | Presigned upload, same pattern as Pin photos |
| `POST /progress-notes` | `MANAGE_ACTIVITY` (Team member for `OWN`) | `{ text?, photoKeys?[] }`. At least one is required (`PROGRESS_NOTE_EMPTY`), at most 5 photos (`PROGRESS_NOTE_TOO_MANY_PHOTOS`). `source = APP` |

There is no `PUT` and no `DELETE` (D10).

### 4.3 Meta webhook (`/api/webhooks/whatsapp`)

- **Outside auth:** this path is excluded from the JWT session filter and CSRF in `SecurityConfig`.
- **`GET` (verification):** echo `hub.challenge` when `hub.verify_token` matches `WHATSAPP_VERIFY_TOKEN`, else `403`.
- **`POST`:**
  - Reject with `401` unless `X-Hub-Signature-256` is the HMAC-SHA256 of the raw body with `WHATSAPP_APP_SECRET`, compared in constant time.
  - Return `200` immediately and process messages asynchronously, in order per `wa_id`.
  - Ignore duplicate message ids, because Meta retries.
  - Ignore status callbacks (delivered/read) in v1.
- **Rate limit:** 30 inbound messages per minute per `wa_id`. Past that, drop messages for 5 minutes without replying.

## 5. Conversation flow

Every inbound message is routed in this order:

1. **Sender has no link:**
   - Message matches `CX-\d{4}` and a valid code: link it, then reply `LINKED`. If the number belonged to another user, move it, email that user, and audit `MOVE`. If the user already had another number, replace it.
   - Wrong or expired code: `CODE_INVALID`.
   - Anything else: `NOT_LINKED`, at most once per 24 hours per number. The message is not processed.
2. **Linked, but the account is disabled:** treat it as not linked.
3. **Text `BAJA` or `STOP`** (any case): unlink, clear the session, reply `UNLINKED`. This works from any step.
4. **Session missing or expired:** start at step A.
5. **Otherwise:** handle the message by the current step. Anything that is not the expected kind of input gets `USE_BUTTONS` plus the current step's menu again. That includes audio, stickers, location, text when a tap is expected, and images outside `ADD_PHOTOS`.

Steps:

| Step | Bot sends | Accepts |
|---|---|---|
| A. `PICK_SITE` | List of Sites the user has access to in active memberships, by name. With more than one company, the row description is the company name. With one Site, go straight to B. With none, `NO_SITES` and the session ends | A list row |
| B. `PICK_TASK` | List of open Tasks (`TODO`, `IN_PROGRESS`) the user can change, title = Task name, description = Phase · status. Own-Team Tasks first, then by due date. 9 per page, 10th row "See more". With none, `NO_TASKS` and the session ends | A list row |
| C. `PICK_ACTION` | Buttons: `TODO` → Start / Finish / Note; `IN_PROGRESS` → Finish / Note | A button |
| D. `WRITE_NOTE` (Note only) | `WRITE_NOTE` | Text of 1–1,000 characters (longer: `NOTE_TOO_LONG`, ask again) |
| E. `ASK_PHOTOS` | `ASK_PHOTOS` with buttons Yes / No | A button |
| F. `ADD_PHOTOS` | `SEND_PHOTOS` with button Done | Images (`image/jpeg`, `image/png`) are downloaded from Meta at once to `whatsapp/pending/{waId}/{uuid}` in private S3. The 6th image gets `PHOTO_LIMIT`. Done with 0 photos is the same as No |
| G. `CONFIRM` | `SUMMARY` with buttons YES / NO | A button |

On **YES**, in one transaction:
1. Recheck D8.
2. Apply the action:
   - Start: `ActivityService.start`.
   - Finish: `ActivityService.complete`.
   - Note, or any action with photos: `ProgressNoteService.add(..., source = WHATSAPP)`. The pending photos move to the note's keys.
3. Reply `SAVED` with the button "Another task", which goes to B for the same Site.
4. If the recheck fails, reply `CHANGED` and end the session.

On **NO**: delete the pending photos, reply `CANCELLED`, end the session.

## 6. Bot messages

`{…}` are placeholders. Buttons are at most 20 characters and list rows at most 24.

| Key | ES | EN |
|---|---|---|
| `NOT_LINKED` | Este número no está vinculado a Construx. Entra a tu perfil, toca "Vincular WhatsApp" y envía aquí el código. | This number isn't linked to Construx. Open your profile, tap "Link WhatsApp" and send the code here. |
| `CODE_INVALID` | Ese código no es válido o ya venció. Genera uno nuevo en tu perfil. | That code is invalid or expired. Generate a new one in your profile. |
| `LINKED` | ¡Listo, {name}! Tu WhatsApp quedó vinculado. Escribe cualquier mensaje para actualizar tus tareas. Envía BAJA para desvincularlo. | Done, {name}! Your WhatsApp is linked. Send any message to update your tasks. Send STOP to unlink. |
| `UNLINKED` | Tu número se desvinculó de Construx. | Your number was unlinked from Construx. |
| `PICK_SITE` | ¿En qué obra? | Which site? |
| `PICK_TASK` | {site}: ¿qué tarea? | {site}: which task? |
| `SEE_MORE` | Ver más | See more |
| `NO_SITES` | No tienes obras asignadas. | You have no sites assigned. |
| `NO_TASKS` | No tienes tareas abiertas en {site}. | You have no open tasks on {site}. |
| `PICK_ACTION` | {task}: ¿qué hiciste? | {task}: what did you do? |
| buttons | Iniciar · Terminar · Nota | Start · Finish · Note |
| `WRITE_NOTE` | Escribe la nota (máx. 1000 caracteres). | Type the note (max 1000 characters). |
| `NOTE_TOO_LONG` | La nota es muy larga. Escríbela en 1000 caracteres o menos. | The note is too long. Keep it to 1000 characters. |
| `ASK_PHOTOS` | ¿Quieres agregar fotos? | Want to add photos? |
| `SEND_PHOTOS` | Envía hasta 5 fotos y toca Listo. | Send up to 5 photos, then tap Done. |
| `PHOTO_LIMIT` | Ya tienes 5 fotos. Toca Listo para continuar. | You already have 5 photos. Tap Done to continue. |
| `SUMMARY` | 📋 Avance de campo · {site}\n{task} → {Iniciada\|Terminada\|Nota}\n{Nota: "…"}\n{n} fotos\n\n¿Lo guardo? | 📋 Field update · {site}\n{task} → {Started\|Finished\|Note}\n{Note: "…"}\n{n} photos\n\nSave it? |
| buttons | Sí · No · Listo · Otra tarea | Yes · No · Done · Another task |
| `SAVED` | ✅ Guardado en Construx. | ✅ Saved to Construx. |
| `CANCELLED` | Cancelado. Escribe de nuevo cuando quieras. | Cancelled. Send a message to start again. |
| `CHANGED` | Esta tarea cambió mientras tanto. Empieza de nuevo. | This task changed in the meantime. Start again. |
| `USE_BUTTONS` | Por ahora usa los botones. | Please use the buttons for now. |
| `EXPIRED` (prefix when a stale button is tapped) | Pasó mucho tiempo, empecemos de nuevo. | That took a while, let's start again. |

Before `LINKED` the language comes from the link code. Before any link, `NOT_LINKED` and `CODE_INVALID` are sent in both languages, Spanish first.

## 7. Dashboard

- **Profile, new "WhatsApp" card:**
  - Not linked: "Link WhatsApp" shows the code, a countdown, an "Open WhatsApp" link (`waMeUrl`) and a QR of the same link for desktop. It polls `GET` every 3 seconds until linked or expired.
  - Linked: the masked number, a language selector and "Unlink".
- **Task detail, new "Progress" section:**
  - A list of Progress notes with author, date, a WhatsApp badge when `source = WHATSAPP`, and photo thumbnails that open full size.
  - A form for text plus up to 5 photos, shown only with permission.
- All strings in EN and ES.
- Guide: optional step `link-whatsapp` in the Manage your sites section (dashboard only, `features/guide/catalog.ts`).

## 8. Acceptance cases

1. A user generates a code and sends it from WhatsApp. The number is linked with the dashboard's language, and the profile shows it masked.
2. The same code sent twice, or after 10 minutes, gets `CODE_INVALID`.
3. A number linked to user A links to user B with B's code. A loses it and gets an email. The audit records `MOVE`.
4. An unlinked number sends 5 messages in an hour and gets exactly one `NOT_LINKED`.
5. A Worker sees only Sites they can access and only open Tasks of their Team. Finishing one marks it `DONE` with `completedAt`, and the audit shows `ACTIVITY COMPLETE` with source WHATSAPP.
6. A Site manager with `MANAGE_ACTIVITY: PROJECT` sees every open Task of that Site, their own Team's Tasks first.
7. Note with 3 photos, then YES: one Progress note with text and 3 photos, source WHATSAPP. NO: no note, and the 3 S3 objects are deleted.
8. Finish with 2 photos: the Task is `DONE`, and a Progress note with 2 photos and no text is attached.
9. Between the summary and YES, a teammate finishes the Task in the app. YES gets `CHANGED` and nothing is saved.
10. The user is removed from the company before YES: `CHANGED`, nothing saved. The next message no longer lists that company's Sites.
11. 31 minutes idle, then a tap on an old button: `EXPIRED`, a new menu, and the pending photos are already deleted.
12. Audio during `PICK_TASK` gets `USE_BUTTONS` and the same list again.
13. `STOP` from any step unlinks. The next message gets `NOT_LINKED`.
14. A webhook POST with a bad signature returns `401` and nothing is processed. A duplicate message id is processed once.
15. A disabled account gets `NOT_LINKED`.
16. A Worker cannot `POST` a Progress note on a Task outside their Team in the dashboard (`403`). No endpoint edits or deletes a note.
