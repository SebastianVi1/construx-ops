# Guided tour: module seams for #93 (foundation + `tour-site`)

Dashboard-internal design note. No backend change and no API change: tour progress goes through the existing `PUT /api/organizations/{org}/guide/steps/{stepId}` (`construx/docs/guide.md`). Parent design: GitHub #92 (11 steps). This note pins what #93 builds and the shape the later tickets (#94 to #99) extend.

Vocabulary: Company = `Organization`, Site = `Project` (ES "obra"), Phase = `Goal`, Task = `Activity`. **Checklist** = the existing getting-started guide (`guideSteps`). **Guided tour** = the new ordered walk-through. **Tour step** = one entry of the tour catalog (ids start with `tour-`). **Fact** = a checkable truth a tour step needs before you can jump to it. **Staged step** = the tour is on a step and the panel shows it, but nothing has moved yet. **Running step** = the user pressed "Start this step": the tour has navigated, opened the form and (desktop) spotlights. Staged and running are hook state (§6.4), not reducer state.

Revision GT93-arch2 (after the #93 code review): timeline-first flow (D9), availability (D10), replay text (D11), example copy in `sites/messages.ts` (D12), the checklist UX addendum (§6.8), and Q1 to Q5 resolved (§10). Revision GT93-arch3: names aligned with the final GT93-fix code (`prefillOpened/Failed/Closed`, `tourEntryCompletedBy`, `tourSpotlightTexts`, `startTour(…, onEnd?)`, `isModalOpen`, `useCreateSiteDialog`, `replay` and `run` copy). Revision GT93-arch4: §6.8 extended with step-by-step completion, the launcher redesign and the sidebar dot (as built in GT93-flow); `design.md` follow-up in §9.

All paths below are under `construx-dashboard/src/`.

## 1. Decisions (summary)

| # | Decision | Why |
|---|---|---|
| D1 | The tour lives in `features/guide/` next to the checklist and reuses its provider, panel, saves, events and `startTour`. There is no second provider. | The issue says to extend the guide. A Company switch already remounts `GuideProvider`, so the tour is per Company for free. |
| D2 | The tour has its own small catalog (`tourCatalog.ts`), not new rows in `guideSteps`. | Checklist steps are chosen by permissions and counted in "2/5". Tour steps are ordered, gated by facts and never counted. Mixing them would mean changing `selectGuide`, `guideProgressOf` and `acceptsMark`. |
| D3 | The tour reducer is pure, has its own state (`tourState.ts`) and is driven by `useGuidedTour` inside `GuideProvider`. | This follows the `guideState.ts` pattern, and the whole state machine can be tested with `bun test`. |
| D4 | A tour step is completed by the **existing** mark: `markGuideStep('create-site', orgId, site.id)` from `addSite`. The catalog maps `create-site` to `tour-site`. The only change to `markGuideStep` is an optional third argument, `createdId`. | No new marking path. The tour needs the new Site's id for later steps (#94), and `GuideMark` doesn't carry it today. |
| D5 | Only a Site created **during the tour, on `tour-site`, while not replaying** completes `tour-site` and is remembered as "the tour's Site". | Replaying a step must create nothing. A Site created outside the tour is not "my Site" for later tour steps. Resolved (Q1, §10). |
| D6 | Pre-fill is **state, not an event**. The tour exposes "the form `site` is requested". `SitesPage` reads it through `useTourForm('site')`, opens `CreateSiteDialog` with `initialValues = siteTourValues(locale, localToday())`, and reports `opened()` back. | An event fired before `SitesPage` mounts (during navigation) would be lost. State survives the navigation. The guide never imports `features/sites`, so `sites` → `guide` stays the only direction. |
| D7 | A tour step is done when its id is saved COMPLETED or SKIPPED on the server, **or** its `doneWhen` fact holds. `tour-site` uses `doneWhen: 'hasSite'` (the browser remembers the tour's Site). | If the progress PUT fails and the page reloads before the retry, the step still counts as done, so the tour never asks for a second Site. |
| D8 | The dev "Start tour" resets this browser's tour memory for the Company and launches the tour at `tour-site`. The old checklist preview moves to a second dev item, "Preview checklist". Both stay behind `devTools`. | #93 says the existing item launches the tour. The preview is the documented workflow in `guide/README.md` and costs one button to keep. |
| D9 | **Timeline first.** `start`, `startAt`, `continue` and `jump` only *stage* a step: they open the guide panel on the timeline with the current row expanded. Nothing navigates, pre-fills or spotlights until the user presses "Start this step". Only one modal is open at a time (the panel or the form, never both). | The user sees where they are and what comes next before the app moves under them. Staging lives in the hook, so the pure reducer stays as reviewed. |
| D10 | The tour is available only to members who see the checklist's `owner` section **and** can create Sites (`MANAGE_PROJECT`). | Every tour step creates something. A member who can't create a Site would get a 403 on the first step. |
| D11 | Replaying a done step shows the tour step's own title and `replay` text on every spotlight stop, never the checklist target copy (`tourSpotlightTexts`). | The checklist target copy reads like an instruction to create something again, and a replay never creates anything. |
| D12 | The example Site name and address are copy in `features/sites/messages.ts`. `siteTourValues(locale, today)` reads them and keeps its signature. | User-facing strings live in messages files, in EN and ES, like the rest of the dashboard. |

## 2. Tour step catalog: `features/guide/tourCatalog.ts`

```ts
import type { GuidePageId, GuideStepId } from './catalog'
import type { guideMessages } from './messages'

/** Facts a tour step can require. Later tickets add: 'onSiteTeam' | 'hasPhase' | 'hasTask' | 'planReady' | 'planCalibrated' | 'hasZone' | 'zoneAssigned' | 'hasPin'. */
export type TourFact = 'hasCompany' | 'hasSite'

/** What the provider knows when it evaluates prerequisites. Later tickets add fields (phaseId, taskId, planId, …). */
export type TourFacts = {
  /** The member is inside a Company. Always true inside `GuideProvider`; false only for the pre-Company tour (#95). */
  hasCompany: boolean
  /** Site the tour created in this Company (browser memory), or null. */
  siteId: string | null
}

export function factHolds(fact: TourFact, facts: TourFacts): boolean
// 'hasCompany' -> facts.hasCompany ; 'hasSite' -> facts.siteId !== null

/** Forms the tour can open pre-filled. The page that owns the form maps the key to its builder. Later: 'phase' | 'task' | … */
export type TourPrefillKey = 'site'

/** Ids a tour catalog uses. A test catalog uses plain strings (`TourCatalog<TourIds>`), as `GuideIds` does for the checklist. */
export type TourIds = { step: string; page: string; target: string; checklist: string }

export type TourStepEntry<I extends TourIds = TourCatalogIds> = {
  /** Saved on the server like a checklist id: must match GUIDE_STEP_ID, start with 'tour-', never change once shipped. */
  id: I['step']
  /** A page id of `guidePages` (reused, not duplicated). */
  page: I['page']
  /** Prerequisites: every fact must hold to jump to or start at this step. */
  requires: readonly TourFact[]
  /** Optional: the step counts as done while this fact holds, even when no save reached the server. */
  doneWhen?: TourFact
  /** `data-tour` targets spotlighted while the step is current, in order. */
  tourTargets: readonly I['target'][]
  /** Targets spotlighted when a done step is replayed (no form opens on a replay). Defaults to `tourTargets`. */
  replayTargets?: readonly I['target'][]
  /** Form the step opens with example values. Absent: nothing is pre-filled. */
  prefill?: TourPrefillKey
  /**
   * Checklist step whose `markGuideStep` completes this tour step. The same mark
   * already ticks that checklist step through the existing path. Absent: the step
   * is completed by a mark with its own id (later tickets widen `markGuideStep`).
   */
  checklistStep?: I['checklist']
  /** Title and body, from `messages.guide.tourSteps`. */
  textKey: keyof typeof guideMessages.en.tourSteps
}

export type TourCatalog<I extends TourIds = TourCatalogIds> = readonly TourStepEntry<I>[]

export const tourSteps = [
  {
    id: 'tour-site',
    page: 'sites',
    requires: ['hasCompany'],
    doneWhen: 'hasSite',
    tourTargets: ['site-create-save'],
    replayTargets: ['site-create'],
    prefill: 'site',
    checklistStep: 'create-site',
    textKey: 'site',
  },
] as const satisfies readonly TourStepEntry<{ step: string; page: GuidePageId; target: string; checklist: GuideStepId }>[]

export type TourStepId = (typeof tourSteps)[number]['id']
export type TourTarget = (typeof tourSteps)[number]['tourTargets'][number] | NonNullable<(typeof tourSteps)[number]['replayTargets']>[number]
export type TourCatalogIds = { step: TourStepId; page: GuidePageId; target: TourTarget; checklist: GuideStepId }

/** The tour step a mark completes (by `checklistStep` or by its own id), or null. */
export function tourStepForMark<I extends TourIds>(markStepId: string, steps: TourCatalog<I>): TourStepEntry<I> | null

/** Tour copy as `messages.guide` holds it: each tour step also has a `replay` text. */
export type TourTexts = {
  tourSteps: Readonly<Record<string, GuideText & { replay: string }>>
  targets: Partial<Record<string, GuideText>>
}
/** What `tourStops` reads. */
export type SpotlightTexts = { steps: Record<string, GuideText>; targets: Partial<Record<string, GuideText>> }

/**
 * Texts for a tour step's spotlight (D11). Running: `{ steps: tourSteps, targets }`.
 * Replaying: every step's body becomes its `replay` text and `targets` is `{}`,
 * so the checklist's target copy never shows on a replay.
 */
export function tourSpotlightTexts(texts: TourTexts, replaying: boolean): SpotlightTexts

/** Mistakes in a tour catalog checked against the checklist catalog; `[]` when it fits. */
export function tourCatalogProblems(tour: TourCatalog<TourIds>, checklist: GuideCatalog<GuideIds>): string[]
```

`tourCatalogProblems` reports: an id that fails `GUIDE_STEP_ID` or doesn't start with `tour-`; a duplicate id; an id that clashes with a checklist step id; an unknown `page` (not in `checklist.pages`); a `checklistStep` missing from `checklist.steps`; a target or replay target that fails `TOUR_TARGET`; two tour steps with the same `checklistStep`; and checklist ids plus tour ids over `GUIDE_MAX_STEPS` (50). Today that is 10 + 1, and 10 + 11 once #99 lands.

`#93` ships exactly one entry, `tour-site`. Later tickets append in #92 order. #95 inserts `tour-company` first, with `requires: []` and `doneWhen: 'hasCompany'`, so an existing Owner sees it done and starts at `tour-site`.

## 3. Pure tour reducer: `features/guide/tourState.ts`

```ts
import type { GuideStepStatus } from './guideApi'
import { tourSteps, type TourCatalog, type TourFact, type TourFacts, type TourIds, type TourPrefillKey, type TourStepEntry, type TourStepId } from './tourCatalog'

export type TourState<S extends string = TourStepId> = {
  /** The tour is on a step (staged or running; that split is hook state, §6.4). */
  active: boolean
  /** Step the tour is on while active; null when inactive. */
  current: S | null
  /** `current` is a done step shown again: spotlight and text only, no pre-fill, no completion. */
  replaying: boolean
  /** The current step's form was opened with its pre-fill (don't open it twice). Reset on entering a step. */
  prefillUsed: boolean
  /** The current step's action failed the last time (the form shows the error). Reset on entering a step and on success. */
  failed: boolean
  /** Steps saved COMPLETED or SKIPPED: the server's (hydrated) plus this session's. Catalog order not guaranteed. */
  done: readonly S[]
  /** The last open step was completed in this session and the end hasn't been acknowledged. */
  finished: boolean
}

export const initialTourState: TourState<never> // { active:false, current:null, replaying:false, prefillUsed:false, failed:false, done:[], finished:false }

export type TourEvent<S extends string = TourStepId> =
  | { type: 'start'; facts: TourFacts }               // panel/launcher entry (#95) — first unfinished; all done → replay the first step
  | { type: 'startAt'; stepId: S; facts: TourFacts }  // dev "Start tour" (stepId 'tour-site') — see rules
  | { type: 'continue'; facts: TourFacts }            // "Continue tour" — first unfinished; all done → inactive
  | { type: 'jump'; stepId: S; facts: TourFacts }     // timeline row click
  | { type: 'prefillUsed' }                           // the page opened the pre-filled form
  | { type: 'stepSucceeded'; stepId: S; facts: TourFacts } // mapped from markGuideStep; facts already include the new id
  | { type: 'stepFailed'; stepId: S }                 // the tour-opened form's save failed
  | { type: 'leave' }                                 // "Leave tour"
  | { type: 'hydrated'; steps: Readonly<Record<string, GuideStepStatus>> } // server progress loaded (also after a reload)
  | { type: 'reset' }                                 // dev "Start tour" only: forget this session's tour state
  | { type: 'finishSeen' }                            // end message acknowledged

export function tourReducer(state: TourState, event: TourEvent): TourState
export function tourReducer<I extends TourIds>(state: TourState<I['step']>, event: TourEvent<I['step']>, steps: TourCatalog<I>): TourState<I['step']>
```

D9 does not change this reducer: events, rules and selectors are as reviewed in #93. Whether a step is staged or running lives in `useGuidedTour` (§6.4). If the implementation finds the reducer has to change, the frontend dev reports it in the ticket and this note is updated.

`useReducer(tourReducer, initialTourState)` uses the two-argument overload with the built-in `tourSteps`. Tests pass their own catalog. Unknown step ids in any event are ignored (the same state reference comes back).

### Definitions

- **done(step)**: `state.done` includes `step.id`, **or** `step.doneWhen` is set and `factHolds(step.doneWhen, facts)`.
- **firstUnfinished**: the first catalog step, in catalog order, that is not done.
- **jumpable(step)**: not done and every `step.requires` fact holds.
- **enter(step, replaying)**: `{ active: true, current: step.id, replaying, prefillUsed: false, failed: false }`. `done` and `finished` are kept, except that `start`, `startAt` and `continue` set `finished: false`.

### Rules

| Event | Result |
|---|---|
| `start` | Enter firstUnfinished. If every step is done, enter the first step with `replaying: true`. Empty catalog: unchanged. |
| `startAt(id)` | done(id) → enter it replaying. jumpable(id) → enter it. Otherwise behave as `start`. |
| `continue` | Enter firstUnfinished (not replaying). None → `active: false, current: null` (nothing else changes). |
| `jump(id)` | done(id) → enter it replaying (replay a done step, **nothing created**). jumpable(id) → enter it. Otherwise unchanged (the timeline shows what's missing). Works whether or not the tour is active. |
| `prefillUsed` | `active && !replaying` → `prefillUsed: true`; otherwise unchanged. |
| `stepSucceeded(id)` | Ignored unless `active && !replaying && current === id`. Otherwise add `id` to `done`, then enter the new firstUnfinished. If none is left: `active: false, current: null, finished: true`. |
| `stepFailed(id)` | Ignored unless `active && !replaying && current === id`. Otherwise `failed: true`. `done` never changes. |
| `leave` | `active: false, current: null, replaying: false, prefillUsed: false, failed: false`. `done` is kept. |
| `hydrated(steps)` | `done` = this session's `done` ∪ catalog ids whose status is COMPLETED or SKIPPED in `steps`. A late load never removes a step done in this session. Nothing else changes. |
| `reset` | `initialTourState`. |
| `finishSeen` | `finished: false`. |

A reload is `initialTourState` followed by `hydrated(server.steps)`. The tour is then inactive, and "Continue tour" enters firstUnfinished. No position is persisted: with `done` and the facts, firstUnfinished *is* the position.

Two kinds of failure, kept apart:
- **The real action fails** (for example a 400 on Site create): no mark is sent, so nothing ticks, neither checklist nor tour. The tour-opened dialog reports `stepFailed` and stays open, so the user can fix the values and save again. If they close it instead, the timeline row shows "Not saved yet…" (§6.5).
- **The progress PUT fails**: the tour state does not change (the step stays done), `guideSaves` retries it the next time the panel opens, and `doneWhen` keeps the step done across a reload in the meantime. The reducer has no event for this.

### Selectors (same file)

```ts
export function isTourStepDone<I extends TourIds>(step: TourStepEntry<I>, done: readonly I['step'][], facts: TourFacts): boolean
export function currentTourStep<I extends TourIds>(state: TourState<I['step']>, steps: TourCatalog<I>): TourStepEntry<I> | null
export function firstUnfinishedTourStep<I extends TourIds>(done: readonly I['step'][], facts: TourFacts, steps: TourCatalog<I>): TourStepEntry<I> | null
/** Where success on the current step leads: firstUnfinished with the current step counted as done; null at the end or when inactive. */
export function nextTourStep<I extends TourIds>(state: TourState<I['step']>, facts: TourFacts, steps: TourCatalog<I>): TourStepEntry<I> | null
/** 'current' when active on it (also while replaying), else 'done' or 'pending'. */
export function tourStepStatus<I extends TourIds>(step: TourStepEntry<I>, state: TourState<I['step']>, facts: TourFacts): 'done' | 'current' | 'pending'
/** Pending steps a jump can reach now, in catalog order. */
export function jumpableTourSteps<I extends TourIds>(state: TourState<I['step']>, facts: TourFacts, steps: TourCatalog<I>): TourStepEntry<I>[]
/** Facts a step still needs, in its `requires` order (the timeline explains a disabled step with these). */
export function missingTourFacts(step: TourStepEntry<TourIds>, facts: TourFacts): TourFact[]
/** The form the page should open pre-filled now: active, not replaying, not yet used, and the current step has `prefill`. */
export function tourPrefill<I extends TourIds>(state: TourState<I['step']>, steps: TourCatalog<I>): TourPrefillKey | null
/** The catalog entry a mark completes *now* (active, not replaying, the mark maps to the current step), else null. */
export function tourEntryCompletedBy<I extends TourIds>(state: TourState<I['step']>, markStepId: string, steps: TourCatalog<I>): TourStepEntry<I> | null
/** Its id: delegates to `tourEntryCompletedBy`. */
export function tourStepCompletedBy<I extends TourIds>(state: TourState<I['step']>, markStepId: string, steps: TourCatalog<I>): I['step'] | null
```

## 4. Facts and browser memory: `features/guide/tourMemory.ts`

This follows `lastSite.ts`: one `localStorage` key per Company, so ids never leak into another Company's tour.

```ts
/** Ids the tour created in one Company, plus whether the tour was ever started here. Later tickets add phaseId, taskId, planId, zoneId, pinId. */
export type TourMemory = { started?: true; siteId?: string }

/** Subset of `Storage` the memory needs; tests pass a fake. */
export type TourStorage = Pick<Storage, 'getItem' | 'setItem' | 'removeItem'>

export const tourMemoryKey = (organizationId: string) => `construx.guide.tour.${organizationId}`

/** The memory, or `{}` when absent, unreadable, not JSON, or blocked. Unknown keys and non-string / empty ids are dropped. Never throws. */
export function readTourMemory(organizationId: string, storage: TourStorage | undefined = globalThis.localStorage): TourMemory

/** Merge `ids` into the stored memory and return the merged value. A write that fails keeps the merge for this visit only. Never throws. */
export function rememberTourIds(organizationId: string, ids: TourMemory, storage: TourStorage | undefined = globalThis.localStorage): TourMemory

/** Remove the Company's memory (dev "Start tour" only). Never throws. */
export function forgetTourMemory(organizationId: string, storage: TourStorage | undefined = globalThis.localStorage): void

/** Facts inside a Company: hasCompany true, siteId from memory. */
export function tourFactsFrom(memory: TourMemory): TourFacts
```

Stored value: JSON, for example `{"started":true,"siteId":"9b1c…"}`. Prerequisites are evaluated only through `factHolds` against `TourFacts`. For #93 the only real prerequisite is `hasCompany`, which is always true inside `GuideProvider`. `hasSite` is used only as `tour-site`'s `doneWhen`. #94 starts requiring it. Later tickets may confirm ids against the API before trusting them (for example a Site that was deleted). That is out of scope here.

The pre-Company tour position (#95) is a different key, outside any Company, and is not specified here.

## 5. Site pre-fill builder: `features/sites/siteTourValues.ts`

It lives in `sites`, because it produces the Site form's values. The guide only knows the key `'site'`.

```ts
import type { Locale } from '../../i18n'
import type { SiteValues } from './siteForm'

/**
 * Example values for the tour's "Create your first Site". `today` is the user's
 * local date as YYYY-MM-DD (callers pass `localToday()` from `lib/dates.ts`, which
 * already applies the browser's time zone), so the builder is pure and takes no time zone.
 */
export function siteTourValues(locale: Locale, today: string): SiteValues
```

| Field | `en` | `es` |
|---|---|---|
| `name` | `Lomas House` | `Casa Lomas` |
| `address` | `214 Hillside Ave, San Antonio, TX 78209` | `Av. de las Lomas 214, Col. Lomas del Valle, 66256 San Pedro Garza García, N.L.` |
| `startDate` | `today` | `today` |
| `expectedEndDate` | `addMonths(today, 3)` | same |
| `status` | `''` (the dialog's default option) | same |

The output must pass `makeSiteSchema(...)` (name ≤ 100, address ≤ 200, end ≥ start). The addresses are fictional examples (Q4, §10).

**Where the copy lives (D12).** `name` and `address` are messages in `features/sites/messages.ts`, in both locales, under `tourExample: { name, address }`. `siteTourValues` reads `sitesMessages[locale].tourExample`. The signature `siteTourValues(locale: Locale, today: string): SiteValues` does not change, and the function stays pure. Changing the example is a copy edit in `messages.ts` only. The table above gives the current values.

Month-end rule, in a new helper in `lib/dates.ts`:

```ts
/** `isoDate` (YYYY-MM-DD) plus `months` calendar months; a day past the target month's end clamps to its last day. Throws RangeError on a malformed date. */
export function addMonths(isoDate: string, months: number): string
```

Examples: `2026-01-31` → `2026-04-30`; `2026-11-30` → `2027-02-28`; `2027-11-30` → `2028-02-29` (leap year); `2026-12-31` → `2027-03-31`; `2026-11-22` → `2027-02-22`. The arithmetic works on the Y-M-D parts, never on a `Date` in local time, so DST and the time zone can't shift the day.

## 6. Seams

### 6.1 Completion (no new marking path)

- `guideEvents.ts`: `markGuideStep(stepId: GuideStepId, organizationId: string, createdId?: string): void`. `GuideMark` gains `createdId?: string`. The key is present **only** when the argument is given, so the existing `toEqual` expectations for other marks stay valid.
- `sites/siteSave.ts` `addSite`: `markGuideStep('create-site', organizationId, site.id)`. No other call site changes.
- `GuideProvider`'s existing `onMark` keeps `commands.complete(mark.stepId)` for the checklist and then calls the tour hook's `onMark(mark)`:
  1. If the hook is not `running` (§6.4), stop: a Site created from "Add site" while a step is only staged is not the tour's Site (D5). Otherwise `const step = tourEntryCompletedBy(tour, mark.stepId, tourSteps)`. If it is null, stop.
  2. If `mark.createdId` is set and `step.prefill === 'site'`, run `rememberTourIds(orgId, { siteId: mark.createdId })`. This is the one place where created ids map to facts, with one case per prefill key. Later steps add their own case here.
  3. End the run (`running = false`, `destroyActiveTour()`; the spotlight is over even when the form was sent with Enter), then `dispatch({ type: 'stepSucceeded', stepId: step.id, facts: tourFactsFrom(memory) })`.
  4. `saves.step(step.id, 'COMPLETED')` (the existing `createGuideSaves`, with retry on panel open), then `setOpen(true)` (§6.4).
- `guideSaves.ts`: widen `GuideServer.markStep` and `GuideSaves.step` from `GuideStepId` to `GuideStepId | TourStepId`. Tour saves skip `guideCommands` / `acceptsMark` on purpose: `acceptsMark` rejects ids outside the visible checklist.

### 6.2 Progress persistence

- The tour saves only COMPLETED, under its `tour-…` id, through `saves.step`. There is no new endpoint, and the 50-step cap holds (`tourCatalogProblems`).
- When it loads, `GuideProvider` dispatches the existing `loaded` action **and** `tour: { type: 'hydrated', steps: progress.steps }`. `guideProgressOf` already ignores ids outside the checklist, so "2/5" is unchanged.
- Note: the first saved tour step sets the server's `started: true`. Inside a Company the panel has normally been seen already. #95 must keep this in mind for the pre-Company auto-start.
- The browser memory (`started`, `siteId`) is written by `useGuidedTour`: `started` on `start`/`startAt`, and `siteId` on success.

### 6.3 Pre-fill into the Site form

- `guide-context.ts` adds a hook, exported from `guide/index.ts`:

  ```ts
  export type TourFormRequest = {
    /** The tour wants this form open with its example values now (only while the step is running). */
    requested: boolean
    /** The tour is running a step that uses this form. When it turns false, the page closes a tour-opened form ("Leave tour"). */
    running: boolean
    /** Call once the form is open, so it isn't opened again for this step. */
    opened: () => void
    /** Call when the form's save failed (the form stays open and shows the error). */
    failed: () => void
    /** Call when the tour-opened form closes without a save (Cancel, Esc, close button). */
    closed: () => void
  }
  /** Inert (false, no-op callbacks) outside a GuideProvider or when another form is in use. */
  export function useTourForm(key: TourPrefillKey): TourFormRequest
  ```

  `requested` is `running && tourPrefill(state) === key`, where `running` is the hook's flag (§6.4). `opened`, `failed` and `closed` are the hook's `prefillOpened`, `prefillFailed` and `prefillClosed`:
  - `prefillOpened` dispatches `prefillUsed`.
  - `prefillFailed` dispatches `stepFailed` for the current step. The form stays open with its error.
  - `prefillClosed` does nothing unless the step is running. Otherwise it dispatches `stepFailed` (unless the step already failed), ends the run and reopens the panel on the same row with the `failed` text.

  A close that follows a successful save is not a `closed()`: success is reported by the mark, which ends the run first.
- `features/sites/useCreateSiteDialog.ts` (new): `useCreateSiteDialog(canCreate): { mode: 'blank' | 'tour' | null, openBlank, close, onFailed }` keeps `SitesPage`'s "Add site" dialog in step with `useTourForm('site')` while rendering, so it needs no effect to open or close the dialog:
  - `requested && canCreate` switches to `'tour'` mode, replacing a blank dialog.
  - `'tour'` while `running` is false closes the dialog without reporting it ("Leave tour", a save, another step).
  - `opened()` is reported from an effect, because it updates the provider.
  - `close` calls `closed()` only in tour mode.
  - `onFailed` is set only in tour mode.

  `SitesPage` renders `CreateSiteDialog` with `initialValues={siteTourValues(locale, localToday())}` in tour mode. The blank "Add site" dialog never reports to the tour. Pressing "Start this step" again re-enters the step, which resets `prefillUsed` and opens the form again.
- `CreateSiteDialog` new props: `initialValues?: SiteValues` (default: today's blank values) and `onFailed?: () => void`, called in its existing `catch` before the rethrow. The submit button gets `data-tour="site-create-save"` through a new optional `Form` prop, `submitTour?: string`, which renders `data-tour` on the submit button (`components/form/types.ts` `FormProps`, `Form.tsx`).
- The user can edit any value, and the tour carries on with whatever was saved (the mark carries the real `site.id`).

### 6.4 Driving a step: `features/guide/useGuidedTour.ts`

```ts
export type GuidedTour = {
  /** The member can take the tour: they see the checklist's 'owner' section AND can create Sites (D10). */
  available: boolean
  /** The timeline shows: available and (active, memory.started, or any step done). */
  visible: boolean
  state: TourState
  /** The current step is running (navigated, form open, spotlight). False while staged or inactive. */
  running: boolean
  steps: TourCatalog
  facts: TourFacts
  start: () => void
  continue: () => void
  jump: (stepId: TourStepId) => void
  /** "Start this step": run the staged current step. */
  run: () => void
  leave: () => void
  acknowledgeFinish: () => void
  /** Behind `useTourForm(...).opened / failed / closed` (§6.3). */
  prefillOpened: () => void
  prefillFailed: () => void
  prefillClosed: () => void
  /** For GuideProvider: hydrate on load and react to marks. */
  hydrate: (progress: GuideProgress) => void
  onMark: (mark: GuideMark) => boolean
}

export function useGuidedTour(input: {
  organizationId: string
  sections: GuideSection[]
  /** The member holds MANAGE_PROJECT (can create Sites), from the same permission source GuideProvider already uses to select the checklist. */
  canCreateSites: boolean
  saves: Pick<GuideSaves, 'step'>
  setOpen: (open: boolean) => void
}): GuidedTour
```

When `available` is false, every command (`start`, `continue`, `jump`, `run`, the dev request in §6.6) does nothing and the timeline is hidden.

**Staged vs running (D9).** The hook holds one extra boolean, `running`, next to the reducer. The reducer does not know about it.

| Trigger | Reducer | Hook |
|---|---|---|
| `start`, `startAt`, `continue`, `jump` | the event as in §3 | `running = false`. If the result is active, `setOpen(true)`: the panel opens on the timeline with the current row expanded (§6.5). Nothing navigates, pre-fills or spotlights. |
| "Start this step" (`run`) | `jump(current)`, which re-enters the step and resets `prefillUsed` and `failed` (a done step re-enters replaying) | `running = true`, then the run sequence below. |
| Mark for the running step (`stepSucceeded`) | as in §3 | `running = false`, `setOpen(true)`: the panel reopens staged on the next unfinished step, or shows "Tour complete" when `finished`. |
| Tour form closed without a save (`prefillClosed`) | `stepFailed(current)` unless already failed | `running = false`, `setOpen(true)`: the panel reopens on the same row with "Not saved yet…". |
| `leave` | `leave` | `running = false`. A tour-opened form closes (`useTourForm(...).running` turns false, §6.3), and `destroyActiveTour()` ends any spotlight. |

**Run sequence** (when `running` turns true):
1. `setOpen(false)`. The panel (dock on desktop, bottom sheet on phones) closes before anything else opens, so only one modal is open at a time.
2. Navigate to `guidePath(step.page, facts.siteId)` (the existing `guidePaths.ts`).
3. Not replaying, with `prefill`: the page opens the pre-filled form through `useTourForm` (§6.3).
4. Desktop only (not `isPhoneWidth()`): `startTour(tourStops([shown], tourSpotlightTexts(m.guide, replaying)), m.guide.tour, onEnd?)`. On `'fallback'` (target missing) there is no spotlight. A running form step keeps its form open, and the panel is **not** opened on top of it.
5. Phone: no spotlight. The step's text was already shown on the staged row, and the form opens the same way. A replay on a phone just navigates and ends the run.
6. Replaying (a done step): navigate and spotlight `replayTargets` only. No form opens and nothing is created. `onEnd` (or a `'fallback'`) ends the replay: `running = false`, and on the next animation frame the panel reopens staged on the same row **unless `isModalOpen()`** (a click on the highlighted "Add site" also ends the spotlight and opens that dialog). Each run takes a run number, so a spotlight that ends late, after Leave or a newer run, changes nothing.
7. On unmount (Company switch), the existing `destroyActiveTour()` cleanup applies.

**Shared helpers.**
- `tour.ts`: `startTour(stops, labels, onEnd?: () => void): Promise<TourResult>`. `onEnd` runs once when a shown spotlight closes, however it closes (done, close button, a newer tour or `destroyActiveTour`). It is not called on `'fallback'`. Checklist callers pass nothing.
- `components/modal/openModal.ts`: `isModalOpen(root = document): boolean`, which is true while a `.modal-overlay` is in the DOM. It is exported from `components/modal`.

**Spotlight text (D11).** `tour.ts` `tourStops` widens its first parameter to the structural `readonly { tourTargets: readonly string[]; textKey: string }[]`, so checklist and tour entries both fit. The hook builds texts with `tourSpotlightTexts(m.guide, replaying)` (§2):
- Running: `{ steps: tourSteps, targets }`, so `site-create-save` shows "Save your site".
- Replay: the step's `replay` text on every stop, `targets: {}`, with `{ ...step, tourTargets: step.replayTargets ?? step.tourTargets }`. The checklist's target copy never shows.

`tourStops` itself is unchanged in behaviour, and the checklist does not change.

`GuideProvider` spreads `tour: GuidedTour` into the context (`GuideContextValue` gains `tour: Omit<GuidedTour, 'hydrate' | 'onMark'>`). The launcher also shows while `tour.state.active`, so "Leave tour" is always one click away.

### 6.5 Timeline in the guide panel: `features/guide/GuideTourTimeline.tsx`

- `GuidePanel` renders `<GuideTourTimeline />` above the checklist sections when `tour.visible`. This covers both the dock modal on desktop and the bottom sheet on phones (the same `Modal variant="dock"`).
- It is an `<ol>` with one `<li>` per catalog step, numbered in catalog order. Each row shows the title and a status from `tourStepStatus`:
  - **done**: a check mark (`CheckIcon`) and a "Replay" button (`jump`, which stages the replay; it does not run it).
  - **current** (expanded): `aria-current="step"`, the step's title and body (`m.guide.tourSteps[textKey]`), and the primary button `tourTimeline.run`, "Start this step" / "Iniciar este paso" (`run`). When `state.failed`: `tourTimeline.failed` ("Not saved yet. Choose Start this step to open the form again.") above the button. This covers both a failed save and a form closed without saving.
  - **pending**: a "Go to step" button (`jump`, which stages that step) when jumpable. Otherwise a disabled button plus one line per `missingTourFacts` fact (`m.guide.tourTimeline.missing[fact]`).
- When the panel opens with the tour active, focus goes to the current row's "Start this step" button, and the row scrolls into view.
- Footer: "Leave tour" (`leave`) while active. Otherwise "Continue tour" (`continue`, which stages) while some step is unfinished. When `state.finished`, a "Tour complete" status line, and closing the panel calls `acknowledgeFinish`.
- Closing the panel while a step is staged keeps it staged (the tour stays active, nothing runs). The launcher stays visible, and reopening the panel shows the same row.
- Starting the tour from the panel for non-dev users is #95's "Guided tour" entry, which uses `tour.start`. #93 can show the timeline only after a start, which in practice is the dev entry.
- Every control is a native `<button>`, reachable with the keyboard and with visible labels.

### 6.6 Dev "Start tour"

- `guideEvents.ts` adds `requestGuidedTour(at: TourStepId): void` and `subscribeGuidedTour(listener: (at: TourStepId) => void): () => void` (a `channel<TourStepId>()` like `previews`).
- `useGuidedTour` subscribes. For the **current Company only** (the provider is per Company; with no provider mounted, the request does nothing), it runs `forgetTourMemory(org)`, dispatches `reset`, then dispatches `startAt` with `stepId: at` and `facts: tourFactsFrom({})`. Like every entry, this only stages the step: the panel opens on `tour-site` with "Start this step" (D9). When `available` is false (D10), the request does nothing. Saved server progress is left alone, so a reload hydrates it back. A dev run creates a real Site and saves real progress, unlike the checklist preview.
- `profile/DevTourItem.tsx`: "Start tour" calls `requestGuidedTour('tour-site')`. A second item, "Preview checklist" / "Vista previa de la guía", calls the existing `requestGuidePreview()`. Both strings live in `devTourMessages.ts`, which only `DevTourItem` imports. `AccountMenu` already renders it behind `devTools` (`import.meta.env.DEV`), so a production build drops it. QA check: `grep -r "Start tour" dist/` finds nothing after `bun run build`.

### 6.7 Messages (`features/guide/messages.ts`, `en` and `es`)

- `tourSteps.site`: EN `{ title: 'Create your first site', body: 'We filled in an example site. Change anything you like, then save.' }`. ES `{ title: 'Crea tu primera obra', body: 'Llenamos una obra de ejemplo. Cambia lo que quieras y guarda.' }`. Every tour step also has a `replay` text, the body shown when a done step is replayed (D11, `tourSpotlightTexts`). `tourSteps.site.replay`: EN 'Choose Add site to create a site. Only the name is required; the address, dates and status can wait.' ES 'Elige Agregar obra para crear una obra. Solo el nombre es obligatorio; la dirección, las fechas y el estado pueden esperar.'
- `targets['site-create-save']`: EN `{ title: 'Save your site', body: 'Check the example values, edit them if you like, and choose Add site.' }`. ES `{ title: 'Guarda tu obra', body: 'Revisa los valores de ejemplo, edítalos si quieres y elige Agregar obra.' }`. The body names the form's real submit label ("Add site" / "Agregar obra").
- `tourTimeline`: `title` ("Guided tour" / "Recorrido guiado"), `run` ("Start this step" / "Iniciar este paso"), `continue` ("Continue tour" / "Continuar recorrido"), `leave` ("Leave tour" / "Salir del recorrido"), `replay` ("Replay" / "Repetir"), `go` ("Go to step" / "Ir al paso"), `done`, `current`, `pending`, `failed` ("Not saved yet. Choose Start this step to open the form again." / "Aún no se guarda. Elige Iniciar este paso para volver a abrir el formulario.", used for both a failed save and a form closed without saving), `finished` ("Tour complete" / "Recorrido completo"), and `missing: { hasCompany: 'Create your company first.' / 'Crea tu empresa primero.', hasSite: 'Create a site in the tour first.' / 'Crea una obra en el recorrido primero.' }`.
- `devTourMessages.ts`: `previewChecklist`.
- `features/sites/messages.ts`: `tourExample: { name, address }` in `en` and `es`, with the values from §5 (D12).

### 6.8 Checklist UX addendum

These are checklist changes the user asked for alongside the tour. There is no API or catalog change. The only state change is `lastDone` / `stepDoneShown` in the guide reducer.

- **Launcher** (`GuideLauncher.tsx`, as built in GT93-flow):
  - A filled primary pill using `--cx-primary` / `--cx-on-primary`, so the dark theme's lighter blue carries dark text (contrast AA). It is 52px tall.
  - An SVG progress ring (done/total) surrounds the count ("2/5").
  - The label is "Next: {step}" / "Siguiente: {paso}" (`launcherNext`) followed by an arrow. It falls back to "Getting started" (`launcher`) when there is no next step. A screen reader also gets the full count label.
  - When the last step is done, it shows "You're set up" with a check for a few seconds, then hides (existing behaviour).
  - Motion: the pill bobs gently, and until the guide is first opened in this tab session it adds a halo pulse (`data-attention`). The session flag is `guideSession.ts`, `sessionStorage` key `construx.guide.opened`, written on the first open by any route, with never-throwing reads and writes. Under `prefers-reduced-motion: reduce` all launcher motion is off. The motion is decoration only and never moves the hit area enough to make a click miss.
  - `visibility.ts` (when the launcher shows) is unchanged.
- **Sidebar entry** (`GuideNavButton.tsx`): while checklist steps remain, the "Guide" entry shows a blue dot plus the count (`aria-hidden` short count and a visually hidden full label). A member with no steps keeps the landing link, or no entry.
- **Step by step after a real completion** (`guideState.ts`, `GuideProvider.tsx`, `GuidePanel.tsx`):
  - The guide reducer sets `lastDone = stepId` on a `marked` COMPLETED that happens after the load, outside a preview, and is not a repeat (an already COMPLETED step returns the same state). `stepDoneShown` clears it.
  - `completionFollowUp(state, sections)` returns one of three values:
    - `'none'`: nothing was just done.
    - `'drop'`: the guide is hidden (`dismissedAt`), a preview is showing, or the step isn't in the member's checklist. The provider dispatches `stepDoneShown`, so the guide never opens by itself while hidden or previewing.
    - `'open'`: the provider polls `isModalOpen()` (about every 150 ms) and opens the panel once no other modal is open.
  - In the panel, `stepAdvance(sections, progress, lastDone)` gives `{ done, next }`. The done row's tick pops once, and focus moves to `next`'s "Show me" (scrolled into view). With no step left, focus goes to the progress meter and "You're set up" shows.
  - The tour wins: when the tour's `onMark(mark)` returns true (it completed a running tour step), the provider dispatches `stepDoneShown` right away, so the tour's own reopen (§6.4) is the single path and the checklist does not open a second time.
- **Skip.** The checklist's Skip is a polished secondary action: a secondary/ghost button that is visually quieter than the step's primary action, with the same height and focus ring, and a native `<button>`. After a skip:
  - The row shows as finished, in the same ✓-style finished treatment as a completed step (a check-style mark), labelled "Skipped" / "Omitido" (the existing `skipped` message) instead of "Done".
  - It counts as finished in the "n/m" progress. `guideProgressOf` already counts COMPLETED and SKIPPED, so the count does not change.
  - The server status stays `SKIPPED` (the existing `commands.skip` → `PUT …/guide/steps/{stepId}`). The UI never rewrites it to COMPLETED. A skipped step can still be completed later by its real action, as today.
  - Focus moves to the next unfinished visible step's "Show me", in checklist order. If none is left, it moves to the progress meter, so focus is never lost on a removed or disabled control. Skip and a real completion share the same `moveOn` in `GuidePanel`.

## 7. Tests the Tester writes (all under `construx-dashboard/src/tests/`)

**`features/guide/tourState.test.ts`** (new). Use a test catalog `TourCatalog<TourIds>`: `tour-a` (requires `[]`, `doneWhen: 'hasCompany'`), `tour-b` (requires `hasCompany`, `prefill: 'site'`, `checklistStep: 'create-site'`), `tour-c` (requires `hasSite`), `tour-d` (requires `hasSite`). Facts are fixtures `{ hasCompany, siteId }`. Cases:
- Order: `start` with no facts enters `tour-a`. With `hasCompany` it enters `tour-b` (`tour-a` done by fact). `nextTourStep` on `tour-b` is `tour-c`.
- Continue: enters firstUnfinished. With every step done, it leaves the tour inactive and does not set `finished`. After `leave`, `continue` resumes at the same first unfinished step.
- Start with all done: enters the first step with `replaying: true`.
- startAt: a jumpable id enters it. A done id replays it. A blocked id (`tour-c` without a Site) falls back to `start`. An unknown id returns the same state.
- Jump rules: jump to a pending step with its facts enters it. Jump to a pending step without them returns the same state reference, and `missingTourFacts` lists `['hasSite']`. `jumpableTourSteps` returns only pending steps whose facts hold. Jump works while inactive.
- Replay creates nothing: while replaying a done step, `tourPrefill` is null, `stepSucceeded` for it returns the same state, `tourStepCompletedBy(state, 'create-site')` is null, and `stepFailed` is ignored.
- Success: `stepSucceeded` on the current step adds it to `done`, enters the next unfinished step, and resets `prefillUsed` and `failed`. On the last step it gives `active: false, current: null, finished: true`. Success for a step that isn't current, or while inactive, changes nothing.
- Failure: `stepFailed` on the current step sets `failed` and leaves `done` and `current` unchanged. Entering any step clears `failed`.
- Prefill: `tourPrefill` is `'site'` on `tour-b` until `prefillUsed`, then null. `continue` back onto `tour-b` makes it `'site'` again.
- Leave: clears `active`, `current`, `replaying`, `prefillUsed` and `failed`, and keeps `done`.
- Reload/hydrate: `initialTourState` + `hydrated({ 'tour-b': 'COMPLETED', 'create-site': 'COMPLETED', 'other': 'SKIPPED' })` keeps only catalog ids. SKIPPED counts as done. A late `hydrated` without a step done in this session keeps it. After a reload, `continue` enters the first unfinished step.
- `doneWhen`: a step whose fact holds counts done even when absent from `done` (progress PUT failed, then a reload).
- `reset` returns `initialTourState`. `finishSeen` clears `finished`.
- `tourStepStatus`: current (also when replaying), done, pending.
- `tourStepCompletedBy`: `'create-site'` → `tour-b` only when active, not replaying and current is `tour-b`. `'tour-c'` (its own id) → `tour-c` when current.

**`features/guide/tourCatalog.test.ts`** (new):
- `tourCatalogProblems(tourSteps, guideCatalog)` is `[]`.
- It reports each problem listed in §2, using small test catalogs: a bad id, a missing `tour-` prefix, a duplicate, a clash with a checklist id, an unknown page, an unknown `checklistStep`, a bad target, a shared `checklistStep`, and more than 50 ids combined.
- Built-in `tour-site`: page `sites`, `requires: ['hasCompany']`, `doneWhen: 'hasSite'`, `prefill: 'site'`, `checklistStep: 'create-site'`.
- `tourStepForMark('create-site', tourSteps)` is `tour-site`. `tourStepForMark('site-details', tourSteps)` is null.
- `factHolds` for both facts.

**`features/guide/tourMemory.test.ts`** (new, with a fake `TourStorage`):
- Empty storage reads `{}`. `rememberTourIds` merges and returns the merged memory, and writes key `construx.guide.tour.org-1`.
- Two Companies never see each other's ids.
- Invalid JSON, a non-object, a non-string or empty `siteId`, and unknown keys all read as `{}` (or drop the bad key).
- A storage whose `getItem`, `setItem` or `removeItem` throws never throws.
- `undefined` storage reads `{}`.
- `forgetTourMemory` removes the key.
- `tourFactsFrom({ siteId: 's1' })` is `{ hasCompany: true, siteId: 's1' }`, and `tourFactsFrom({})` has `siteId: null`.

**`features/sites/siteTourValues.test.ts`** (new):
- EN gives `Lomas House` and ES gives `Casa Lomas`. Each locale has a non-empty address of 200 characters or fewer, and the two addresses differ.
- `startDate` is the given `today`. `expectedEndDate` is `addMonths(today, 3)` for `2026-11-22`, `2026-01-31` (→ `2026-04-30`) and `2027-11-30` (→ `2028-02-29`). `status` is `''`.
- The output passes `makeSiteSchema` with any messages. The result does not depend on the system clock or `TZ` (call it under two `process.env.TZ` values).

**`lib/dates.test.ts`** (extend): `addMonths` with every example in §5, `months = 0`, a year rollover, `12` months from Feb 29 (→ Feb 28), and a malformed input (`'2026-13-01'`, `'2026-1-5'`, `''`) throwing `RangeError`.

**`features/sites/siteSave.test.ts`** (update): `addSite` marks `{ stepId: 'create-site', organizationId: 'org-1', createdId: 'site-1' }`. A failed create still marks nothing. `saveSiteDetails` and `addSitePerson` marks have no `createdId` key (use `toStrictEqual` for one of them).

**`features/guide/guideEvents.test.ts`** (extend):
- `requestGuidedTour('tour-site')` reaches a subscriber with `'tour-site'`, and nothing after unsubscribe.
- `markGuideStep` with a `createdId` carries it. Without one, the mark has no `createdId` key.

**`features/guide/tour.test.ts`** (extend): `tourStops` accepts a tour entry and reads `texts.steps[textKey]` and `texts.targets['site-create-save']`. The checklist call is unchanged.

**`features/guide/tourCatalog.test.ts`** (also, D11): `tourSpotlightTexts(texts, false)` returns `{ steps: texts.tourSteps, targets: texts.targets }`. `tourSpotlightTexts(texts, true)` gives every step `{ title, body: replay }` and `targets: {}`. Fed to `tourStops` for `site-create`, the replay stop shows `tourSteps.site.title` / `.replay` and no `targets` copy. EN and ES `guideMessages.tourSteps.site.replay` are non-empty.

**`features/guide/tourState.test.ts`** (also): `tourEntryCompletedBy` returns the entry under the same rule as `tourStepCompletedBy` (null while inactive, replaying, or for a step that isn't current), and `tourStepCompletedBy` equals its `?.id`.

**`components/modal/openModal.test.ts`** (new, optional): `isModalOpen(root)` with a fake `querySelector` is true when `.modal-overlay` matches and false otherwise.

**`features/sites/siteTourValues.test.ts`** (also, D12): the EN and ES `name` and `address` equal `sitesMessages.en.tourExample` and `sitesMessages.es.tourExample`.

**Hook behaviour (D9, D10)**: `useGuidedTour` is React state and is verified by QA and the Flow Reviewer against §6.4 and §6.5, not with `bun test`, unless the Tester adds a hook harness:
- Every entry (start, Continue, Go to step, Replay, dev Start tour) opens the panel with the current row expanded, and the URL does not change until "Start this step" is pressed.
- "Start this step" closes the panel, navigates, opens the pre-filled form and (desktop) spotlights its "Add site" submit button. Panel and form are never open together.
- A successful save reopens the panel on the next step, or "Tour complete".
- Cancelling the form reopens the panel with "Not saved yet…" on the same row.
- "Leave tour" closes a tour-opened form.
- Creating a Site from "Add site" while a step is staged does not complete `tour-site`.
- A member without `MANAGE_PROJECT`, or without the `owner` section, never sees the timeline, and the dev Start tour does nothing for them.
- Checklist: the launcher bobs, and does not under reduced motion. Skip shows "Skipped" with the finished mark, the count goes up, and focus lands on the next unfinished step.

**`features/guide/guideSaves.test.ts`** (extend): `step('tour-site', 'COMPLETED')` is sent, and a failure is retried by `retryFailed` the same way as a checklist id.

The existing `selection.test.ts`, `guideState.test.ts` and `env.test.ts` (`devTools` false) must stay green unchanged.

## 8. Files for #93 (frontend dev)

**Add**
- `features/guide/tourCatalog.ts`: §2
- `features/guide/tourState.ts`: §3
- `features/guide/tourMemory.ts`: §4
- `features/guide/useGuidedTour.ts`: §6.4, §6.6
- `features/guide/GuideTourTimeline.tsx` (+ styles in `guide.css`, `--cx-*` tokens): §6.5
- `features/sites/siteTourValues.ts`: §5
- `features/sites/useCreateSiteDialog.ts`: §6.3
- `components/modal/openModal.ts` (`isModalOpen`, exported from `components/modal`): §6.4

**Change**
- `lib/dates.ts`: `addMonths`
- `features/guide/guideEvents.ts`: `createdId`, `requestGuidedTour` / `subscribeGuidedTour`
- `features/guide/guideSaves.ts`: widen step id type
- `features/guide/tour.ts`: widen `tourStops` parameter; `startTour(stops, labels, onEnd?)`
- `features/guide/tourCatalog.ts` / `tourState.ts` (already new): `tourSpotlightTexts`, `TourTexts`, `SpotlightTexts`; `tourEntryCompletedBy`
- `features/guide/guide-context.ts`: `tour` in the context, `useTourForm`, `TourFormRequest`
- `features/guide/GuideProvider.tsx`: `useGuidedTour`, `hydrate` on load, `onMark` after `commands.complete`, launcher visible while the tour is active
- `features/guide/GuidePanel.tsx`: render the timeline; Skip as a secondary action, a finished "Skipped" row, and focus moving to the next unfinished step (§6.8)
- `features/guide/guide.css` (or the launcher's stylesheet): launcher bob with a reduced-motion override (§6.8)
- `features/sites/messages.ts`: `tourExample` (D12)
- `features/guide/messages.ts`: §6.7
- `features/guide/index.ts`: export `useTourForm`, `requestGuidedTour`, type `TourPrefillKey`
- `features/guide/README.md`: a "Adding a tour step" section (catalog entry, facts, `doneWhen`, prefill key + page builder, `checklistStep` vs own-id mark, `tourCatalogProblems`)
- `features/sites/siteSave.ts`: pass `site.id`
- `features/sites/CreateSiteDialog.tsx`: `initialValues`, `onFailed`, `submitTour="site-create-save"`
- `features/sites/SitesPage.tsx`: `useCreateSiteDialog(canCreate)` drives the dialog (blank or tour mode)
- `components/form/types.ts`, `components/form/Form.tsx`: optional `submitTour`
- `features/profile/DevTourItem.tsx`, `features/profile/devTourMessages.ts` (and `AccountMenu.tsx` only if the second item needs its own row): §6.6

No change to `catalog.ts`, `selection.ts`, `guideCommands.ts` or `guidePaths.ts`. `guideState.ts` gains checklist completion follow-up state and helpers (§6.8).

## 9. Conflicts between the spec (#92/#93) and the code, with resolutions

1. **The dev "Start tour" is the checklist preview today** (`requestGuidePreview`, documented in `guide/README.md`). Resolution: D8. Repurpose it for the tour and keep the preview as "Preview checklist". Update the README's "Preview your change" line.
2. **`GuideMark` has no created id**, so the tour cannot learn "my Site". Resolution: D4. Add an optional `createdId` third argument and update the `siteSave.test.ts` expectation.
3. **`acceptsMark` / `guideReducer` reject ids outside the visible checklist, and `GuideSaves.step` is typed to checklist ids.** Resolution: tour saves go straight to `saves.step`, with the type widened. Checklist rules are unchanged.
4. **`catalogProblems` and the 50-step cap only see the checklist.** Resolution: `tourCatalogProblems` counts both.
5. **`Form` has no way to tag its submit button** for the spotlight on the submit button ("Add site"). Resolution: an optional `submitTour` prop. It is generic and does nothing when unset.
6. **`tourStops` is typed to checklist entries.** Resolution: a structural parameter type, with no behaviour change.
7. **The spec timeline shows all 11 steps, but #93 ships one.** Resolution: the timeline renders the catalog as it is, so #93 shows one row and later tickets add rows. Numbering follows the catalog, so "step 2" in the spec is row 1 until #95 inserts `tour-company` (Q3, resolved in §10).
8. **The spec says "the tour remembers ids it created" and also "an existing Owner can start from step 2".** An Owner who already has Sites still gets `tour-site` as unfinished and creates the tour's own Site. That was a product choice (Q1, resolved in §10).
9. **The first tour save sets `started: true` on the server**, which turns off the checklist's auto-open. This is harmless inside a Company. #95 must check it for the pre-Company auto-start.
10. **The old plan (`.agents/specs/guided-tour.md`) names `steps.ts`.** The real catalog is `catalog.ts`. This note follows the code.
11. **The #93 review build drove the app as soon as a step was entered** (navigate + spotlight on `start`/`jump`). Resolution: D9. Entering only stages the step, and "Start this step" runs it. The reducer is unchanged, and `running` lives in the hook.
12. **A replay showed the checklist target copy** for `site-create`. Resolution: D11. Replay stops use the tour step's own text.
13. **Follow-up outside #93: `design.md` is stale.** It describes orange as the primary colour and a dark-only theme. The code is blue (`--cx-primary`) and light by default, with a dark theme. The launcher (§6.8) follows the code tokens. Updating `design.md` needs its own ticket.

## 10. Resolved questions

Q1 to Q5 are closed and no product question remains open for #93. Later tickets (#94 to #99) follow these answers.

| # | Question | Resolution |
|---|---|---|
| Q1 | Does a Site the Owner already has (or one created outside the tour) complete `tour-site`? | No. Only a Site created while `tour-site` is **running** and not replaying completes it and becomes the tour's Site (D5, §6.1). An Owner with Sites still creates the tour's own Site, or can Leave. |
| Q2 | Who can take the tour? | Members who see the checklist's `owner` section **and** hold `MANAGE_PROJECT` (D10). Everyone else sees no timeline, and the entries do nothing. |
| Q3 | Timeline numbering against the 11-step spec | Rows are numbered in catalog order. #93 shows one row, and numbers shift when #95 inserts `tour-company` first. |
| Q4 | Example Site copy | The §5 values ("Lomas House" / "Casa Lomas" and the fictional addresses), stored as copy in `features/sites/messages.ts` (D12). Changing them later is a copy edit. |
| Q5 | After a reload the tour is not running. Should it resume automatically? | No automatic resume after a reload. "Continue tour" in the guide panel returns to the first unfinished step (§3: a reload is `initialTourState` + `hydrated`, and no position is persisted). Like every entry, it stages the step (D9). |
