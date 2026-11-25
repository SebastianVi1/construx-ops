# Field updates come in through WhatsApp menus on one Construx number, with no AI in v1

Status: accepted (2026-11-24)

People on site update their own Tasks from WhatsApp without logging in. Construx knows who is writing from their Linked number: a WhatsApp number they proved is theirs by sending a one-time code from the dashboard. Each Field update is built with WhatsApp interactive lists and buttons (Site → open Task → Start / Finish / Note → optional photos → summary → YES / NO). Nothing is saved until the person confirms the summary. On YES the backend checks again with the same `SiteScope` permissions as the app. Every company uses one Construx number on Meta's WhatsApp Cloud API directly, with no BSP. The person always writes first, so every reply is a free-form message inside WhatsApp's 24-hour service window and no approved templates are needed.

Why: field staff already live in WhatsApp, and logging into the dashboard on site is the main reason Tasks go stale. Without AI, matching typed Site and Task names fails on small differences ("losa 2" vs "Colado losa N2"), and a worker who gets three rejections stops using the bot. Lists and buttons only offer Tasks the person can change, so names never need matching. Trusting the WhatsApp sender only after a code proves ownership closes the gap that the profile phone number is unverified. Reusing `SiteScope` means WhatsApp can never do more than the app.

Considered and rejected:
- **Fixed text format** (`Obra: … / Terminé: …`): fragile name matching.
- **AI that parses free text, now**: it adds cost, data sent to a third party and prompt-injection exposure before the basic flow has been proven. It may come later on top of the menus, which would stay as the fallback.
- **AI writing to the app directly**: it would bypass permissions and could invent IDs.
- **Construx sending a verification code by WhatsApp**: it needs an approved authentication template and costs a message per link.
- **One WhatsApp number per company**: it means becoming a Meta Tech Provider with embedded signup.
- **A BSP such as Twilio**: it adds a per-message markup for no v1 benefit.

Consequences:
- One message covers one Task. More Tasks mean "Another task" after each confirmation.
- Photos from WhatsApp have no spot on a floor plan, so they attach to a Progress note, not to a Pin.
- The webhook is a public endpoint outside the cookie session and CSRF. Its only trust is Meta's `X-Hub-Signature-256` signature.
- The bot speaks the language saved with the Linked number, because there is no AI to detect it.
- If Meta disables the number or changes its policy, Field updates stop for every company at once.
