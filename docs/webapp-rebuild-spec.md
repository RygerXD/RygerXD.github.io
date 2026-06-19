# Workout App Web Rebuild Specification

Last updated: 2026-06-10

## 1. Purpose

Rebuild the current Flutter workout app as a web application that is easier to test, deploy, and share while preserving the product behavior and data model closely enough that the app can later return to Flutter without another product rewrite.

The web app should be local-first, installable, and deployable as static assets. Sharing the app should be as simple as sending a URL. Sharing user data should be handled through import/export files until a real sync/account layer is intentionally added.

## 2. Product Summary

The application is a local-first workout planner and tracker. Users can:

- Import workout plans from JSON.
- Create and edit workout plans.
- Create and edit workouts inside plans.
- Define reusable moves with optional image/GIF URLs.
- Build workouts from sets, laps, timed moves, rep moves, stopwatch moves, prep time, cooldown time, per-side duration, target weights, and metronome cadence.
- Start guided workouts with timers, rest handling, audio cues, adjustable actual reps, adjustable actual weight, and move-level performance capture.
- View weekly dashboard stats.
- Browse plans and workouts.
- Review workout summaries before starting.
- Track completed and abandoned sessions in history.
- View analysis summaries, frequency heatmaps, session history, and move-level progress charts.
- Configure theme, unit preference, streak goal, and workout audio cue settings.

## 3. Recommended Web Stack

Use a static client-side TypeScript web app:

- Runtime and UI: React + TypeScript.
- Build tool: Vite.
- Routing: TanStack Router.
- Local database: IndexedDB through Dexie.
- Runtime validation: Zod for app-facing schemas, plus JSON Schema compatibility for workout plan import/export.
- Styling: CSS modules or vanilla-extract with design tokens, not a heavy component framework.
- State management: React context/hooks for transient state, Dexie live queries for persisted state, and a small domain-service layer for state-machine logic.
- Testing: Vitest for unit/domain tests, React Testing Library for component tests, Playwright for browser workflows.
- Deployment: GitHub Pages first, with compatibility for any static file host later.

### 3.1 Stack Rationale

This should not be a Next.js/server app yet. The current product is local-first, requires no backend, and stores data on-device. A static SPA keeps setup and sharing simple, avoids server/account decisions, and keeps the eventual Flutter return cleaner because the domain model stays app-owned rather than backend-owned.

Vite is a good fit because it targets modern web projects, has React TypeScript templates, fast dev server behavior, and static production output. TanStack Router is a good fit because the current Flutter app already has a route-heavy shell, detail pages, and query parameters; typed route params and search params reduce route drift. Dexie is a good fit because the Flutter app already behaves as an offline local database and needs reactive local queries. Zod is a good fit for keeping TypeScript types and runtime validation together while still preserving JSON Schema import/export compatibility.

### 3.2 Target Browser Support

Target current evergreen Chrome, Edge, Safari, and Firefox. The app should work well on desktop and mobile browsers. Chrome/Edge should be the primary browser target during development because Web Audio and IndexedDB behavior are easiest to debug there.

### 3.3 GitHub Pages Hosting Target

The first hosted testing target should be GitHub Pages on GitHub Free.

GitHub Pages is a static host for HTML, CSS, and JavaScript files. This app must therefore build to static assets and must not require:

- a Node.js server at runtime,
- server-side rendering,
- API routes,
- a database server,
- server-side file uploads,
- server-managed user accounts,
- environment-specific secrets.

Recommended deployment shape:

- Use Vite production build output from `npm run build`.
- Publish the generated `dist/` directory through a GitHub Actions Pages workflow.
- Configure Vite `base` to the project path when using a project site:

```ts
// vite.config.ts
export default defineConfig({
  base: "/<repository-name>/",
});
```

- Include an empty `.nojekyll` in the deployed artifact if publishing prebuilt static assets through a branch/folder flow.
- Keep the production bundle small enough that the published site is comfortably below GitHub Pages limits.
- Do not commit user/tester workout data into the repository. User data belongs only in each tester's browser storage.

Routing on GitHub Pages:

- For easiest testing, use TanStack Router hash history in the GitHub Pages build.
- URLs will look like `https://<user>.github.io/<repo>/#/dashboard` and `https://<user>.github.io/<repo>/#/library/detail/<planId>`.
- The logical route map in this spec still applies; the `#` is a hosting adapter detail.
- This avoids static-host 404 problems when testers refresh or open a deep link directly.
- If clean browser-history URLs are required later, add a GitHub Pages-compatible `404.html` fallback or move to a static host with first-class SPA fallback rewrites.

GitHub Pages fit:

- A handful of testers is well within the intended shape for a small static app.
- GitHub Pages is not the place for commercial SaaS, sensitive transactions, or server-side workflows.
- The app should not ask testers for passwords, payment information, private health information beyond their voluntary local workout entries, or anything that needs server-side compliance controls.

### 3.4 Local-Only Data Guarantee

The application data model must be local-only by default.

Data stored locally:

- workout plans,
- imported plan JSON,
- created/edited plans and workouts,
- workout sessions,
- move performances,
- rep/weight/duration history,
- settings,
- local media blobs if enabled,
- active workout recovery snapshots if enabled.

Storage mechanism:

- Use IndexedDB for durable app data through Dexie.
- Use small browser storage only for non-critical convenience flags if needed.
- Do not use cookies for app data.
- Do not send app data to GitHub, a backend, analytics, logging services, error reporting services, or third-party APIs.

Per-device behavior:

- Data is stored on the machine, browser profile, and site origin that opened the app.
- A tester using Chrome on a laptop and Safari on a phone will have two separate local datasets.
- A tester using normal browsing and private/incognito browsing will have separate datasets, and private browsing data may be removed when the session ends.
- Changing the hosting origin can strand data. For example, `https://<user>.github.io/<repo>/` and a later custom domain are different origins, so browser storage will not automatically transfer.
- Clearing site data, clearing browser storage, or uninstalling a PWA can delete local data.
- Add explicit backup/export before asking testers to rely on the app for real history.

Persistence hardening:

- On first launch after meaningful data exists, the app may call `navigator.storage.persist()` where supported and explain that browser storage can still be cleared by the user/browser.
- Provide manual full-backup export and import before beta testing with real users.
- Add a Settings or Data screen that shows local storage status and export/import actions.
- Treat backup/export as the user's way to move data between machines.

Privacy note:

- GitHub Pages will still receive ordinary web request metadata for serving the site, such as visitor IP address, under GitHub's own service operation. The workout app itself must not upload user workout data anywhere.

## 4. Architecture Principles

1. Keep domain logic framework-independent.
   - Workout plan parsing, validation, estimates, state-machine transitions, streak calculations, and history aggregation should live outside React components.
   - These modules should be portable enough to translate back into Dart later.

2. Preserve the schemaVersion 1 workout plan JSON contract.
   - Do not casually rename plan/workout/set/move/move fields.
   - Imported files produced for the Flutter app should import into the web app.
   - Web-exported plan files should import into the Flutter app.

3. Local-first is the default.
   - No login.
   - No backend dependency.
   - No hidden network writes.
   - User data persists in IndexedDB.
   - No telemetry, analytics, crash reporting, or remote logging until explicitly added and disclosed.
   - Network use is limited to loading the static app bundle, user-entered remote image/GIF URLs, and any user-triggered remote import URL.

4. Separate durable data from transient workout-player state.
   - Persist plans, sessions, move performances, settings, and recent performance values.
   - Keep the currently active workout state in memory by default.
   - Optionally snapshot active workout state to IndexedDB as a resilience enhancement, but do not let stale snapshots silently resume without user confirmation.

5. Preserve current behavior before adding new features.
   - Favorites and export currently appear as placeholders; the web rebuild should either preserve them as placeholders or implement them deliberately and label the implementation as new scope.

## 5. Current Route Map and Web Equivalent

Current Flutter routes:

- `/dashboard`
- `/library`
- `/library/create`
- `/library/detail/:planId`
- `/library/detail/:planId/workout/:workoutId`
- `/library/detail/:planId/edit`
- `/library/detail/:planId/edit-workout`
- `/library/detail/:planId/edit-workout?workoutId=:workoutId`
- `/analysis`
- `/analysis/session/:sessionId`
- `/settings`
- `/active`

Web routes should preserve these paths where possible:

| Route | Screen | Notes |
| --- | --- | --- |
| `/dashboard` | Dashboard | Initial route. |
| `/library` | Library | Plan import, favorites placeholder, all plans, create action. |
| `/library/create` | Create Plan | Creates metadata-only plan with empty workouts/moves. |
| `/library/detail/$planId` | Plan Detail | Plan image, description, workouts, edit/delete/add workout. |
| `/library/detail/$planId/workout/$workoutId` | Workout Summary | Preview and start workout. |
| `/library/detail/$planId/edit` | Edit Plan | Edit plan metadata. |
| `/library/detail/$planId/edit-workout` | Create Workout | Creates workout under plan. |
| `/library/detail/$planId/edit-workout?workoutId=$workoutId` | Edit Workout | Edits existing workout. |
| `/analysis` | Analysis | Summary cards, heatmap, grouped sessions. |
| `/analysis/session/$sessionId` | Workout Progress | Move-level progress charts for comparable sessions. |
| `/settings` | Settings | Theme, units, streak, backup/restore, and link to Sounds. |
| `/settings/sounds` | Sounds | Master volume, per-cue toggles, built-ins, custom files, and previews. |
| `/active` | Active Workout | Full-screen workout player. |

Web navigation shell:

- Bottom navigation on narrow viewports.
- Left sidebar or compact rail on desktop.
- Four top-level destinations: Home, Library, Analysis, Settings.
- `/active` should hide the normal shell and use a focused player layout.

## 6. Data Model

### 6.1 Workout Plan JSON

The canonical import/export unit is one workout plan.

```ts
type MoveType = "reps" | "duration" | "stopwatch";
type WeightUnit = "kg" | "lb";

interface Move {
  moveId: string;
  name: string;
  imageUrl?: string;
  description?: string;
}

interface WorkoutMove {
  workoutMoveId: string;
  moveId: string;
  type: MoveType;
  repCount?: number;
  durationSeconds?: number;
  prepTimeSeconds?: number;
  finishTimeSeconds?: number;
  repeatEachSide?: boolean;
  targetWeight?: number;
  targetWeightUnit?: WeightUnit;
  metronomeSpeed?: number;
}

interface WorkoutSet {
  setId: string;
  name?: string;
  lapCount?: number;
  restBetweenLapsSeconds?: number;
  moves: WorkoutMove[];
}

interface Workout {
  workoutId: string;
  title: string;
  imageUrl?: string;
  sets: WorkoutSet[];
}

interface WorkoutPlan {
  schemaVersion: 1;
  planId: string;
  name: string;
  description?: string;
  author?: string;
  imageUrl?: string;
  tags?: string[];
  workouts: Workout[];
  moves: Move[];
}
```

### 6.2 Plan Validation Rules

The web parser must reject invalid imports with user-visible validation messages:

- Root JSON must be an object.
- `schemaVersion` is required and must be `1`.
- `planId` and `name` are required non-empty strings.
- `workouts` is required and must be a non-empty array.
- `moves` is required and must be a non-empty array.
- Every workout must have a non-empty `workoutId`, non-empty `title`, and at least one set.
- Every set must have a non-empty `setId` and at least one move.
- If present, `lapCount` must be `>= 1`; it defaults to `1`.
- If present, `restBetweenLapsSeconds` must be `>= 0`; it defaults to `0`.
- Set `name`, if present, must not be empty after trimming.
- Every workout move must have a non-empty `workoutMoveId`, non-empty `moveId`, and valid `type`.
- Every workout move `moveId` must reference a move in the plan.
- `reps` moves require `repCount >= 1`.
- `duration` moves require `durationSeconds >= 1`.
- `stopwatch` moves must not set `durationSeconds`.
- `prepTimeSeconds` and `finishTimeSeconds` default to `0` and must be `>= 0` when present.
- `repeatEachSide` is valid on `reps`, `duration`, and `stopwatch` moves.
- `metronomeSpeed` is only valid on `duration` moves and must be between `20` and `300`.
- `targetWeight`, if present, must be greater than `0`.
- `targetWeightUnit`, if present, must be `kg` or `lb`; if target weight tracking is enabled in UI, both weight and unit must be saved.
- `tags`, if present, should contain unique non-empty strings.
- Image URL fields should accept valid `http`, `https`, blob/object URLs created by the app, or locally persisted media references.

### 6.3 Persisted Tables

Use IndexedDB database name `workout_app_v1`.

Stores:

#### `plans`

Primary key: `planId`

Fields:

- `planId`
- `jsonPayload`
- `updatedAt`

Store the complete workout plan JSON payload as the source of truth to preserve exact schema compatibility. Derived indexes may be added for list rendering.

#### `sessions`

Primary key: `sessionId`

Fields:

- `sessionId`
- `planId`
- `workoutId`
- `startedAt`
- `endedAt`
- `durationSeconds`
- `status`

Allowed statuses:

- `completed`
- `abandoned`
- `inProgress` only if active workout persistence is implemented.

The Flutter state machine also has `completedEarly`, but current session saving stores early finish as completed. The web app should either preserve that simplification or add an explicit `completedEarly` status only after deciding how migration back to Flutter should handle it.

#### `movePerformances`

Primary key: `performanceId`

Use the same key pattern as the Flutter app:

```text
$sessionId|$setId|$lapIndex|$workoutMoveId
```

Fields:

- `performanceId`
- `sessionId`
- `workoutId`
- `setId`
- `lapIndex`
- `workoutMoveId`
- `moveId`
- `repCount`
- `actualWeight`
- `actualWeightUnit`
- `elapsedSeconds`
- `completedAt`

#### `repHistory`

Primary key:

```text
$workoutId|$setId|$lapIndex|$moveId
```

Fields:

- `key`
- `workoutId`
- `setId`
- `lapIndex`
- `moveId`
- `reps`
- `updatedAt`

#### `weightHistory`

Primary key:

```text
$workoutId|$setId|$lapIndex|$moveId|$weightUnit
```

Fields:

- `key`
- `workoutId`
- `setId`
- `lapIndex`
- `moveId`
- `weightUnit`
- `weight`
- `updatedAt`

#### `durationHistory`

Primary key:

```text
$workoutId|$setId|$lapIndex|$moveId
```

Fields:

- `key`
- `workoutId`
- `setId`
- `lapIndex`
- `moveId`
- `seconds`
- `updatedAt`

#### `settings`

Primary key: `key`

Persist settings as key/value records so future Flutter migration can map them back to SharedPreferences keys.

## 7. Settings Model

Defaults:

- Theme preference: `system`
- Unit system: `metric`
- Streak goal: `3` workouts per week
- Audio cues enabled: `true`
- Shared audio volume: `0.8`
- Get ready countdown sound: `click`
- Move start sound: `classic`
- Move finished ding sound: `classic`
- Metronome sound: `classic`
- Workout complete sound: built-in
- Workout ended early sound: built-in
- Every cue enabled: `true`
- Every cue custom override: none

Enums:

```ts
type ThemePreference = "system" | "light" | "dark";
type UnitSystem = "metric" | "imperial";
type MetronomeClickSound = "classic" | "sharp" | "low" | "bell";
type GetReadyDingSound = "classic" | "bright" | "soft" | "bell";
type CountdownSound = "click" | "pulse" | "wood" | "low";
type MoveFinishedDingSound = "classic" | "bright" | "soft" | "bell";
```

Streak goal must clamp to `1...14`.

Volume values must clamp to `0...1`.

## 8. Design System

Preserve the current utilitarian app feel. Avoid promotional greeting copy on the dashboard.

Base tokens:

- Brand: `#4F46E5`
- Brand dark: `#6366F1`
- Accent: `#06B6D4`
- Accent dark: `#22D3EE`
- Danger: `#EF4444`
- Light surface: `#F8FAFC`
- Dark surface: `#0F172A`

Spacing:

- `xs = 4px`
- `sm = 8px`
- `md = 12px`
- `lg = 16px`
- `xl = 24px`
- `xxl = 32px`

Radii:

- `sm = 8px`
- `md = 12px`
- `lg = 16px`
- `pill = 999px`

The web app should use:

- Cards for individual repeated list items.
- Full-screen player for active workouts.
- Icon buttons for edit, delete, close, add, remove, reorder, test audio, and navigation.
- Segmented controls for mode switches and enums with small option counts.
- Sliders for volume.
- Steppers/buttons for streak goal, reps, and weight adjustments.
- Dropdowns for audio sound choices.

## 9. Feature Specifications

### 9.1 App Shell

Requirements:

- Initial route is `/dashboard`.
- Shell destinations: Home, Library, Analysis, Settings.
- The active route should be visibly selected.
- Nested routes under Library and Analysis should preserve the parent shell unless route is `/active`.
- `/active` uses a focused player layout without bottom nav/sidebar.
- Back behavior should follow browser history where possible.
- When a detail screen cannot pop, it should navigate to its logical parent.

### 9.2 Dashboard

Purpose: quick weekly status and access to workouts/plans.

Data:

- Load all sessions.
- Load all plans.
- Compute the current week starting Monday.
- Count completed sessions whose `startedAt` is on or after the current week start.
- Sum completed session duration in the current week.
- Round weekly active minutes from total seconds divided by 60.

UI:

- First visible content is the stats row.
- Stat card 1: `Workouts`, value = weekly completed sessions, subtitle = `This Week`.
- Stat card 2: `Active Time`, value = weekly active minutes, subtitle = `Minutes`.
- Segmented control with:
  - `My Workouts`
  - `My Plans`
- In `My Workouts` mode:
  - Flatten all workouts from all plans.
  - Sort workouts by most recent completed session for that workout, descending.
  - Workouts without completed sessions sort after completed workouts.
  - Tie-break by workout title ascending.
  - Each card shows workout thumbnail, title, estimated duration, parent plan name, and play icon.
  - Selecting a workout goes to `/library/detail/$planId/workout/$workoutId`.
  - Empty state text: `Create or import a plan to see workouts here.`
- In `My Plans` mode:
  - List all plans.
  - Each card shows plan thumbnail, plan name, description if present, otherwise workout count.
  - Selecting a plan goes to `/library/detail/$planId`.
  - Empty state text: `Import or create your first plan.`

### 9.3 Library

Purpose: plan management.

UI:

- Primary create action routes to `/library/create`.
- Import button appears at the top of the library content in both empty and non-empty states.
- Import button label: `Import Workout JSON`.
- Section: `Favorites`
  - Current behavior is placeholder only.
  - Show empty state: `No favorite plans yet.`
  - Do not invent favorite persistence unless deliberately expanding scope.
- Section: `All Plans`
  - Empty state: `Import or create your first plan.`
  - Plan list cards show thumbnail, name, description or `No description provided`, and chevron.
  - Selecting a plan routes to plan detail.

Import behavior:

- Use browser file picker restricted to `.json`.
- Read UTF-8 text.
- Reject files over `5 * 1024 * 1024` bytes.
- Parse and validate using schemaVersion 1 rules.
- Save valid plan by `planId`, replacing any existing plan with same id.
- Show success toast: `Successfully imported {plan.name}`.
- Show error toast with validation/import error.

Remote import:

- Current service has HTTPS URI validation but no UI.
- Web rebuild may expose remote import later.
- If exposed, allow `https://` by default and reject `http://` unless an explicit dev setting is enabled.

### 9.4 Create/Edit Plan

Routes:

- Create: `/library/create`
- Edit: `/library/detail/$planId/edit`

Fields:

- Plan Name, required.
- Image or GIF URL.
- Description.
- Author.
- Tags.

Create behavior:

- Generate UUID `planId`.
- Set `schemaVersion: 1`.
- Save plan with empty `workouts` and empty `moves`.
- Navigate to `/library/detail/$planId`.

Edit behavior:

- Load existing plan by id.
- Populate fields from current plan.
- Save only metadata fields:
  - `name`
  - `imageUrl`
  - `description`
  - `author`
  - `tags`
- Preserve workouts and moves unchanged.
- Navigate to `/library/detail/$planId`.

Tags:

- Adding a tag trims whitespace.
- Empty tags are ignored.
- Duplicate tags are ignored.
- Tags can be removed individually.

### 9.5 Plan Detail

Route: `/library/detail/$planId`

Requirements:

- Load plan by id.
- Show loading, error, and `Plan not found` states.
- App bar title is plan name.
- Back action returns to browser history or `/library`.
- Actions:
  - Edit plan.
  - Delete plan.
- Delete flow:
  - Confirmation dialog title currently says `Delete Workout?`; web rebuild should correct wording to `Delete Plan?` while preserving destructive confirmation behavior.
  - Confirmation content includes the plan name.
  - Cancel does nothing.
  - Delete removes plan and returns to `/library`.
- Main content:
  - Plan hero image if present.
  - Description if present.
  - Section title: `Workouts in this Plan`.
  - Workout cards for every workout.
- Add Workout action routes to `/library/detail/$planId/edit-workout`.
- Workout card:
  - Thumbnail from workout `imageUrl`.
  - Title.
  - Estimated duration.
  - Set count.
  - Edit workout icon.
  - Card tap routes to workout summary.
  - Edit icon routes to `/library/detail/$planId/edit-workout?workoutId=$workoutId`.

### 9.6 Create/Edit Workout

Routes:

- Create: `/library/detail/$planId/edit-workout`
- Edit: `/library/detail/$planId/edit-workout?workoutId=$workoutId`

Fields:

- Workout Title, required.
- Image or GIF URL.
- Sets.

Create behavior:

- Start with one empty set:
  - Generated UUID `setId`.
  - Name: `Set 1`.
  - `lapCount: 1`.
  - `restBetweenLapsSeconds: 0`.
  - Empty moves.

Edit behavior:

- Load existing workout.
- Populate title, image URL, and sets.
- Cache plan moves by id for display and editing.

Save behavior:

- Validate non-empty title.
- Generate UUID `workoutId` on create.
- Upsert workout in plan.
- Merge cached move changes into plan moves.
- Save updated plan.
- Return to previous screen or plan detail.

Set editing:

- Add set.
- Remove set.
- Rename set; blank name saves as omitted.
- Edit lap count; invalid or `< 1` values are ignored.
- Edit rest-between-laps seconds; invalid values are ignored and values below `0` are clamped to `0`. The initial value is `0` seconds for new sets.
- Show empty set text: `No moves in this set yet.`

Move list:

- Show moves in set order.
- Each row shows move thumbnail, move name, move summary, remove button, and drag handle.
- Moves can be reordered within a set.
- Moves can be removed.
- Tapping a move opens edit dialog.
- Buttons:
  - `New Move`
  - `Existing`

### 9.7 Add/Edit Move Dialog

Purpose: create or edit a move and its associated reusable move.

Fields:

- Move Name, required to submit.
- Image or GIF URL.
- Move type segmented control:
  - `Reps`
  - `Time`
  - `Max Time`
- Prep Time seconds.
- Cooldown Time seconds.
- Rep Count for reps moves.
- Duration seconds for duration moves.
- Left and right sides switch for every move type.
- Metronome switch for duration moves.
- BPM field when metronome is enabled.
- Track weight switch.
- Target Weight field when tracking weight.
- Weight unit segmented control: `lb`, `kg`.

Defaults for a new move:

- Move name blank.
- Media URL blank.
- Move type: `reps`.
- Prep time: `5`.
- Cooldown time: `0`.
- Reps: `10`.
- Duration: `30`.
- Metronome BPM: `60`.
- Metronome disabled.
- Repeat each side disabled.
- Track weight disabled.
- Weight unit: `lb`.

Validation:

- Move name cannot be blank.
- Non-negative prep/cooldown seconds; fallback to default if invalid.
- Duration metronome BPM must be `20...300`.
- If track weight is enabled, weight must be `> 0`.
- Reps fallback to 10 if invalid.
- Duration fallback to 30 if invalid.

Save behavior:

- New reusable move gets UUID `moveId` unless editing/reusing an existing move.
- New workout move gets UUID `workoutMoveId` unless editing.
- Move `description` is preserved when editing an existing move.
- For `reps`, save `repCount` and optional `repeatEachSide`; do not save duration/metronome.
- For `duration`, save `durationSeconds`, optional `repeatEachSide`, optional `metronomeSpeed`.
- For `stopwatch`, save optional `repeatEachSide`; do not save `durationSeconds` or metronome.
- If tracking weight, save `targetWeight` and `targetWeightUnit`.

Move summaries:

- Reps: `{repCount} reps`
- Stopwatch: `Max time`
- Duration: `{durationSeconds} seconds`
- Duration per side: `{durationSeconds} seconds / side`
- Duration with metronome: append ` - {bpm} BPM`

### 9.8 Existing Move Picker

Purpose: reuse moves from any existing plan.

Behavior:

- Collect moves only if they are referenced by at least one workout move in existing plans.
- Deduplicate by lowercased trimmed move name.
- Sort by move name ascending.
- Search filters using:
  - direct substring match, ranked by index; or
  - fuzzy subsequence match with a simple score.
- Empty states:
  - No moves at all: `No existing moves found.`
  - No matches: `No matching moves.`
- Selecting a move opens Add Move dialog prefilled with that move.

### 9.9 Workout Summary

Route: `/library/detail/$planId/workout/$workoutId`

Purpose: preview a workout before starting.

Requirements:

- Load plan and workout.
- Show loading, error, and `Workout not found` states.
- Back action returns to browser history or `/dashboard`.
- Edit action routes to edit-workout route with workout query parameter.
- Sticky bottom primary button: `START`.
- Starting:
  - Initialize active workout controller with selected workout and plan id.
  - Generate session id.
  - Capture started timestamp.
  - Navigate to `/active`.

Content:

- Hero thumbnail from workout `imageUrl`, fallback fitness icon.
- Workout title.
- Stats:
  - Calories: always `0`.
  - Duration: `HH:MM:SS` estimate.
  - Moves: count of moves across laps.
- Description block:
  - Use plan description if present.
  - Fallback: `Review the moves, timing, and set laps before you start.`
- Moves section:
  - Render sets in order.
  - Show set name if present.
  - Show lap badge `x{lapCount} Laps` if lap count > 1.
  - Render each move with move thumbnail, move name, and target badge.

Workout estimates:

- Set estimate is repeated for each lap.
- Add restBetweenLapsSeconds between laps only, not after final lap.
- Reps and stopwatch active durations count as 0 for estimates.
- Duration active time is `durationSeconds` per side when `repeatEachSide` is true.
- Move estimate includes prep + active + cooldown for each runtime execution.
- `repeatEachSide` creates two runtime executions: left and right.

### 9.10 Active Workout Player

Route: `/active`

Purpose: guide the user through a workout.

Phases:

- `idle`
- `prep`
- `move`
- `rest`
- `restBetweenLaps`
- `paused`
- `completed`
- `completedEarly`
- `abandoned`

Current UI exposes:

- Start from summary into `prep`.
- Start Now from prep.
- Pause/resume.
- Skip move.
- Complete move.
- Skip cooldown/rest.
- Abandon via close/back confirmation.

Current controller supports but UI does not expose:

- Finish early.

The web rebuild should include finish-early only if a clear UI is designed; otherwise keep the state-machine method internally tested but not reachable.

State cursor:

- `setIndex`
- `lapIndex`
- `moveIndex`
- `pausedFrom`
- `transitionCount`

Transition rules:

- `idle -> prep` on start.
- `prep -> move` on Start Now or prep timer completion.
- `move -> rest` after completing a move with `finishTimeSeconds > 0`.
- `move -> prep` after completing/skipping a move when more moves remain in the current lap.
- `move -> restBetweenLaps` after final move in a lap when more laps remain and `restBetweenLapsSeconds > 0`.
- `move -> prep` after final move in a lap when more laps remain and rest between laps is 0.
- `move -> prep` after final move in final lap when another set remains.
- `move -> completed` after final move in final set.
- `rest -> prep/restBetweenLaps/completed` according to the same after-move advancement rules.
- `restBetweenLaps -> prep`.
- `prep`, `move`, `rest`, `restBetweenLaps -> paused`.
- `paused -> pausedFrom`.
- Active phases -> `abandoned`.
- Active phases -> `completedEarly` if finish-early UI is added.

Timer behavior:

- A one-second ticker drives timers.
- Paused state freezes timers and metronome.
- Prep counts down from move `prepTimeSeconds`.
- Duration move counts down from the per-execution duration.
- `repeatEachSide` moves are expanded before playback into left and right runtime moves.
- Stopwatch moves count up from 0.
- Rest counts down from move `finishTimeSeconds`.
- Rest-between-laps counts down from set `restBetweenLapsSeconds`.
- When a countdown hits 0:
  - Prep auto-starts move and plays get-ready ding.
  - Duration move auto-completes and plays move-finished ding.
  - Rest-between-laps auto-continues.
  - Rest auto-continues.

Display:

- Header:
  - Close button.
  - Workout title.
  - Set label: set name or `Set {setIndex + 1}`.
  - Move/lap indicator: `{moveIndex + 1} / {moves.length} - Lap {lapIndex + 1}/{lapCount}`.
  - Pause/resume button.
- Phase chip:
  - Prep: `GET READY`, orange.
  - Move: `GO!`, blue.
  - Rest: `COOLDOWN`, green.
  - Rest between laps: `REST`, green.
- Prep/rest displays:
  - Current or next move image if available.
  - Large timer.
  - `Next: {moveName}`.
- Move display:
  - Move image if available.
  - Move name.
  - Reps move: adjustable actual reps.
  - Duration move: countdown timer and optional metronome summary.
  - Stopwatch move: count-up timer and previous duration if known.
  - Weight controls if move has target weight/unit.

Reps controls:

- Initial current reps = last saved reps for this workout/set/lap/move, otherwise target rep count, otherwise 0.
- Show label `ACTUAL REPS`.
- Show recommended target.
- Show last value if available.
- Buttons: `-10`, `-1`, `+1`, `+10`.
- Reps cannot go below 0.

Weight controls:

- Show only when move has `targetWeight` and `targetWeightUnit`.
- Initial current weight = last saved weight for workout/set/lap/move/unit, otherwise target weight.
- Show label `ACTUAL WEIGHT`.
- Show recommended target.
- Show last value if available.
- Buttons: `-5`, `-1`, `+1`, `+5`.
- Weight cannot go below 0.

Move completion persistence:

- For reps moves, save actual reps to `repHistory`.
- For duration moves with metronome, estimate reps as `round(elapsedSeconds * bpm / 60)` and save to `repHistory`.
- For stopwatch moves, save elapsed seconds to `durationHistory`.
- For weighted moves, save actual weight to `weightHistory`.
- For every completed move, save `movePerformance`:
  - `repCount` is actual reps, metronome-estimated reps, or 0.
  - `actualWeight` and unit are saved when tracked.
  - `elapsedSeconds` is actual active elapsed seconds.
  - `completedAt` is now.
- After saving move performance, run state-machine `completeMove`.

Session persistence:

- On workout completion, save session with status `completed`.
- On abandon, save session with status `abandoned`.
- `durationSeconds` is `endedAt - startedAt`.
- If the player exits because no active workout exists, route to plan detail when plan id is known, otherwise library.

Exit behavior:

- Browser back and close button should show confirmation:
  - Title: `Abandon Workout?`
  - Body: `Progress for this workout session will be lost.`
  - Cancel remains in workout.
  - Abandon saves abandoned session and exits.

### 9.11 Audio Cues and Metronome

Use Web Audio API.

Browser constraints:

- AudioContext may not play until the user has interacted with the page.
- Starting a workout and pressing audio test buttons count as user gestures.
- If audio fails, the app should continue silently without blocking workout progression.

Audio settings:

- Respect global audio-cues-enabled switch.
- Respect the shared audio volume.
- Respect the enabled switch for each individual cue.
- Prefer a cue's custom MP3/WAV override when configured, otherwise use its selected built-in sound.
- Workout-level terminal sounds override plan sounds, which override global Sounds settings.
- Volume 0 means do not play.

Events:

- Get ready countdown:
  - Plays in prep phase at remaining seconds 3, 2, 1.
- Move start:
  - Plays when prep reaches 0 and move starts.
- Move finished ding:
  - Plays when duration move reaches 0.
- Metronome:
  - Plays during duration move only.
  - Requires `metronomeSpeed`.
  - Stops while paused.
  - Stops outside move phase.
  - Interval is `60000 / bpm` ms.

Sound profiles should preserve the current named options:

- Metronome:
  - `classic`
  - `sharp`
  - `low`
  - `bell`
- Move start:
  - `classic`
  - `bright`
  - `soft`
  - `bell`
- Countdown:
  - `click`
  - `pulse`
  - `wood`
  - `low`
- Move finished ding:
  - `classic`
  - `bright`
  - `soft`
  - `bell`

### 9.12 Analysis

Route: `/analysis`

Purpose: show workout history and weekly progress.

Empty state:

- Title: `No Analysis Yet`
- Body: `Complete your first workout to unlock heatmaps and session history.`
- Button: `Go to Library`, routes to `/library`.

Error state:

- Show error icon.
- Title: `Error loading history`.
- Show error text.

Summary calculations:

- Weekly completed sessions:
  - Count completed sessions from current week start Monday through now.
- Weekly active time:
  - Sum completed session `durationSeconds` for current week.
  - Format with no seconds, `0m` for zero.
- Streak:
  - Count consecutive weeks meeting the configured workouts-per-week goal.
  - Required workouts clamps to `1...14`.
  - If current week has not yet met the goal, streak starts from previous week.
  - Only completed sessions count.

Summary cards:

- Workouts: weekly completed count, detail `This Week`.
- Active Time: weekly duration, detail `This Week`.
- Streak: `{weeks}w`, detail `{goal} workout(s)/wk`.

Heatmap:

- Title: `Workout Frequency`.
- Default days shown in analysis: 365.
- Days with at least one completed workout are primary color.
- Empty days are muted surface color.
- Week columns run Sunday through Saturday.
- Show weekday labels for Monday, Wednesday, Friday.
- Horizontal scroll starts from most recent dates.
- Previous/next controls move pivot date by 30 days.
- Next is disabled when pivot is today.

Session list:

- Build session items by joining sessions to current plan/workout metadata.
- Unknown plan fallback: `Unknown Plan`.
- Unknown workout fallback: `Unknown Workout`.
- Sort by `startedAt` descending.
- Group by date label:
  - Today
  - Yesterday
  - Weekday name for dates less than 7 days old
  - `Mon D, YYYY` for older dates
- Session card shows:
  - Status icon and badge.
  - Workout name.
  - Plan name.
  - Start time.
  - Duration.
- Status labels:
  - `Completed`
  - `Abandoned`
  - `In Progress`
- Tapping a session routes to `/analysis/session/$sessionId`.

Current placeholder:

- App bar export button currently shows `Export is not available yet.`
- Web rebuild should preserve this placeholder unless implementing export as deliberate new scope.

### 9.13 Workout Progress

Route: `/analysis/session/$sessionId`

Purpose: compare selected session move performance against earlier completed sessions of the same workout.

Data selection:

- Find selected session by id.
- Comparable sessions:
  - Same `workoutId`.
  - `startedAt <= selected.startedAt`.
  - Status is `completed`, or the session is the selected session.
  - Sort ascending by started date.
- Include move performances where:
  - `performance.workoutId === selected.workoutId`.
  - `performance.sessionId` is in comparable session ids.

Workout context:

- Resolve plan by `planId`.
- Resolve workout by `workoutId`.
- Fallback workout name: `Unknown Workout`.

Series construction:

- Key by `setId|lapIndex|workoutMoveId|moveId`.
- Sort points by session started time.
- If workout structure is available:
  - Iterate current workout set order, laps, and move order.
  - Include only move keys with data.
  - Label: `{moveName} - {setName}, Lap {lapIndex + 1}`.
  - Set name fallback: `Set {setIndex + 1}`.
- If workout structure is missing:
  - Use key as label.
  - Sort labels ascending.

Point fields:

- Reps.
- Elapsed seconds.
- Actual weight.
- Actual weight unit.
- Session started date.
- Whether point belongs to selected session.

Card behavior:

- If selected point exists, show metric pills for:
  - Reps if move tracks reps or any point has reps > 0.
  - Time.
  - Weight if selected point has weight.
- Each metric pill shows current value and delta from previous point.
- If no previous point, detail is `No earlier entry`.
- Chart includes lines for:
  - Time.
  - Reps when applicable.
  - Weight when any point has weight.
- Selected session point is visually marked.
- Empty state:
  - Title: `No move-level history yet`.
  - Body: `Complete {workoutName} again to compare reps and completion time for each move.`

### 9.14 Settings

Route: `/settings`

Controls:

- Theme:
  - Segmented options: System, Light, Dark.
  - Applies immediately.
  - Persists.
- Units:
  - Segmented options: Metric, Imperial.
  - Persists.
  - Current app does not automatically convert existing weights; web rebuild should not convert by default.
- Streak goal:
  - Display `{n} workout(s) per week`.
  - Decrement and increment icon buttons.
  - Clamp `1...14`.
- Sounds:
  - Opens `/settings/sounds`.
  - Settings retains only the navigation row; detailed audio controls live on the Sounds page.

### 9.14.1 Sounds

Route: `/settings/sounds`

- Master Audio cues switch and one shared volume slider.
- Separate enabled switch for get-ready countdown, move start, move halfway, move finished, metronome, workout complete, and workout ended early.
- Existing built-in dropdowns remain available where multiple built-ins exist.
- Every cue accepts an MP3/WAV custom override, supports preview and removal, and retains its built-in choice as fallback.
- Custom clips are limited to 512 KB and must be included in settings backup/restore.

Labels:

- Theme:
  - `System`
  - `Light`
  - `Dark`
- Units:
  - `Metric (kg)`
  - `Imperial (lb)`
- Metronome:
  - `Classic`
  - `Sharp`
  - `Low`
  - `Bell`
- Move start:
  - `Classic ding`
  - `Bright chime`
  - `Soft ding`
  - `Bell`
- Countdown:
  - `Click`
  - `Pulse`
  - `Wood`
  - `Low`
- Move finished ding:
  - `Classic finish`
  - `Bright finish`
  - `Soft finish`
  - `Bell`

### 9.15 Media Handling

Current fields accept image/GIF URLs for:

- Plan image.
- Workout image.
- Move image.

Web behavior:

- Remote `http` and `https` images should render through normal `<img>` behavior.
- Broken images show fallback icon.
- Loading images show placeholders where appropriate.
- Browser local file paths cannot be reused like Flutter desktop/mobile paths.
- For pasted/dropped/uploaded local media, store a Blob in IndexedDB and save an app-owned media reference in the plan field.
- Recommended app media reference format:

```text
app-media://$mediaId
```

Additional store:

#### `media`

Primary key: `mediaId`

Fields:

- `mediaId`
- `blob`
- `mimeType`
- `createdAt`
- `sourceName`

Media input field:

- Accept URL text.
- Accept paste/drop/upload image content when feasible.
- Store image/GIF blobs locally.
- Show toast:
  - Success: `Image added.`
  - Failure: `Could not add that image.`

Import/export media constraint:

- Existing schema only stores URLs.
- `app-media://` references are web-app-local and will not work in Flutter unless Flutter adds support.
- To preserve Flutter compatibility, plan JSON export should either:
  - exclude app-local media references,
  - convert them to data URLs with clear size warnings, or
  - export a bundle format separate from canonical plan JSON.

For the first web version, prefer URL-only canonical JSON export and keep local media as a web-only enhancement.

## 10. Import, Export, and Shareability

### 10.1 Canonical Plan Import

Accept one `.json` file containing a single `WorkoutPlan`.

### 10.2 Canonical Plan Export

Even though current analysis export is not implemented, plan export is useful for sharing and Flutter return.

If implemented in the web rebuild:

- Export one selected plan as schemaVersion 1 JSON.
- Emit sparse canonical JSON: omit unknown optional fields, nulls, and default values.
- Do not include IndexedDB-only session/history data.
- Warn if local `app-media://` references exist.

### 10.3 Full Backup Export

Full backup export/import is required before testers rely on the app for real workout history. Local browser storage is the source of truth, so users need a deliberate way to move or protect that data.

Backup shape:

```ts
interface WorkoutAppBackupV1 {
  schemaVersion: 1;
  exportedAt: string;
  plans: WorkoutPlan[];
  sessions: WorkoutSession[];
  movePerformances: MovePerformance[];
  repHistory: RepHistoryRecord[];
  weightHistory: WeightHistoryRecord[];
  durationHistory: DurationHistoryRecord[];
  settings: AppSettings;
}
```

Backup behavior:

- Export downloads a JSON file to the user's machine.
- Import reads a user-selected backup JSON file.
- Import should offer merge/replace choices before writing.
- Backup import must validate shape and schema version before modifying local storage.
- Backup export/import must not contact a server.
- Backup files are user-controlled and can be shared manually.

### 10.4 Sharing With Testers

For early testing:

- Deploy static app to GitHub Pages.
- Provide testers the GitHub Pages URL.
- Provide sample JSON plans from `docs/schemas/examples`.
- Add a visible import path in Library.
- Tell testers their data stays in that browser on that machine unless they export a backup.
- Add a test data reset/dev tool only in development builds, not production.

## 11. Non-Goals for First Web Version

- User accounts.
- Cloud sync.
- Social sharing.
- AI workout generation inside the app.
- Calorie estimation beyond current hardcoded `0`.
- Favorite plan implementation unless explicitly chosen.
- Analysis export unless explicitly chosen.
- Automatic unit conversion.
- A backend API.
- Server-side persistence.
- Cross-device sync.
- Analytics or telemetry.
- Replacing schemaVersion 1.

## 12. Known Current Gaps to Preserve or Decide

These are present in the Flutter app and should be handled intentionally:

- Favorites section exists but is always empty.
- Analysis export icon exists but export is unavailable.
- `finishEarly` exists in controller/state machine but is not exposed in active workout UI.
- Plan detail delete dialog currently says `Delete Workout?` even though it deletes a plan; web rebuild should correct this copy.
- New set defaults `restBetweenLapsSeconds` to 0, and the workout editor exposes a rest-between-laps seconds editor.
- Plan creation can create a plan with zero workouts and zero moves, even though imported plans require at least one workout and move.
- Web media paste/save is unsupported in the current Flutter web path; the rebuild should implement browser-native Blob storage if local media is needed.

## 13. Testing Requirements

### 13.1 Unit Tests

Cover:

- Plan parser accepts valid schemaVersion 1 JSON.
- Parser rejects invalid root, missing schemaVersion, unsupported schemaVersion, empty required strings, bad move references, invalid move type data, invalid metronome speed, and invalid stopwatch duration.
- Workout estimate calculations:
  - prep + duration + cooldown.
  - repeatEachSide creates left/right runtime moves and doubles total active duration for duration moves.
  - lap rest is counted between laps only.
  - reps and stopwatch active time are 0.
- Move count across laps.
- State machine transitions.
- Invalid state-machine transitions do nothing or throw controlled domain errors.
- Streak calculation.
- Relative date labels.
- Rep/weight/duration history key generation.
- Metronome rep estimate.
- Settings clamping and defaults.

### 13.2 Component Tests

Cover:

- Dashboard weekly stats and My Workouts/My Plans toggle.
- Library import success/error.
- Create/edit plan.
- Create/edit workout.
- Add/edit move dialog for all move types.
- Existing move picker search and selection.
- Workout summary start button.
- Active player display for prep, move, rest, paused.
- Settings controls persist and re-render.
- Analysis empty state and populated state.
- Workout progress chart data preparation.

### 13.3 Browser Workflow Tests

Use Playwright:

- Import valid JSON plan.
- Navigate Library -> Plan Detail -> Workout Summary -> Active.
- Complete a workout containing:
  - reps move,
  - duration move,
  - stopwatch move,
  - weighted move,
  - lapped set with rest.
- Verify session appears in Analysis.
- Verify weekly dashboard stats update.
- Verify move-level progress appears after repeated sessions.
- Verify settings theme and audio toggles persist across reload.
- Verify IndexedDB data persists after page reload.
- Verify data remains available after browser restart where Playwright/browser automation can support that check.
- Verify full backup export downloads a valid backup file.
- Verify full backup import restores data into a fresh browser profile.
- Verify no app-data network requests are made during normal create/edit/workout/history flows.
- Verify a GitHub Pages-style base path and hash route work in production build preview.
- Verify app works on mobile viewport.

### 13.4 Accessibility Checks

Minimum:

- Keyboard navigation through shell, forms, dialogs, and player controls.
- Focus trap in dialogs.
- Visible focus indicators.
- ARIA labels for icon-only buttons.
- Reduced-motion handling for charts/transitions if animations are added.
- Timer values readable by screen readers without excessive announcements.

## 14. Suggested File Structure

```text
src/
  app/
    router.tsx
    AppShell.tsx
    providers.tsx
  domain/
    workoutPlan.ts
    workoutPlan.schema.ts
    workoutPlanParser.ts
    workoutMetrics.ts
    workoutStateMachine.ts
    historyAnalytics.ts
    settings.ts
  db/
    db.ts
    planRepository.ts
    historyRepository.ts
    settingsRepository.ts
    mediaRepository.ts
  features/
    dashboard/
    library/
    planEditor/
    workoutEditor/
    workoutSummary/
    activeWorkout/
    analysis/
    settings/
  components/
    media/
    controls/
    layout/
  styles/
    tokens.css
    theme.css
```

## 15. Implementation Plan

### Phase 1: Foundation

- Scaffold Vite React TypeScript app.
- Add router and shell.
- Add design tokens and light/dark theme.
- Add domain model types.
- Port workout parser and metrics.
- Add Dexie database and repositories.
- Add settings persistence.
- Add GitHub Pages-compatible routing/build configuration.

### Phase 2: Plan Library

- Implement Library.
- Implement JSON import.
- Implement Create/Edit Plan.
- Implement Plan Detail.
- Implement Create/Edit Workout.
- Implement Add/Edit Move and Existing Move picker.
- Verify canonical JSON compatibility.

### Phase 3: Workout Execution

- Port state machine.
- Implement Workout Summary.
- Implement Active Workout Player.
- Implement timers, pause/resume, skip/complete, abandon.
- Implement reps/weight/duration history.
- Implement move performance persistence.
- Implement Web Audio cues and metronome.

### Phase 4: History and Analysis

- Implement Dashboard weekly stats.
- Implement Analysis summary cards.
- Implement heatmap.
- Implement grouped session history.
- Implement workout progress page and charts.

### Phase 5: Hardening

- Add import/export edge cases.
- Add full local backup export/import.
- Add responsive desktop layout.
- Add Playwright workflows.
- Add accessibility pass.
- Add production deployment config for GitHub Pages.
- Add migration notes for Flutter return.

## 16. Flutter Return Strategy

To make the eventual Flutter return practical:

- Keep the schemaVersion 1 workout plan JSON as the canonical interchange format.
- Keep names and behavior of move types, settings enums, session statuses, and history keys aligned with Flutter.
- Keep workout state-machine tests written in behavior terms so they can be ported back.
- Avoid storing important data only in web-only shapes unless a migration/export path exists.
- Keep app-local media references clearly separated from canonical plan JSON.
- Prefer deterministic pure functions for estimates, date grouping, streaks, and validation.
- Document any intentional web-only deviations in a migration notes file.

## 17. Acceptance Criteria for Web Parity

The web rebuild is at feature parity when:

- A valid current `.plan.json` imports successfully.
- Imported plans appear in Library and Dashboard.
- Users can create, edit, and delete plans.
- Users can create and edit workouts, sets, moves, images, weights, timers, metronome, per-side duration, and move ordering.
- Users can start a workout and complete all current move types.
- Active workout timers, rests, laps, pause/resume, skip, complete, abandon, and audio cues behave like the current app.
- Completed and abandoned sessions persist.
- Move-level reps, weights, durations, and performance records persist.
- Dashboard weekly stats update after workout completion.
- Analysis summary, heatmap, grouped history, and workout progress pages populate from persisted history.
- Settings persist across reload.
- Data survives page reload and browser restart.
- Data is stored locally per browser profile and origin, with no backend writes.
- Full backup export/import works for moving data between machines or browser profiles.
- Normal app usage does not send workout plans, history, settings, or performance data over the network.
- The app deploys to GitHub Pages as static assets and works through a shared URL.
- GitHub Pages deep links work through hash routing or an equivalent static-host SPA fallback.
- The canonical plan JSON remains compatible with the Flutter app.

## 18. Reference Sources

- Current Flutter source in this repository.
- `docs/schemas/workout-plan.schema.json`.
- `docs/ai-workout-json-guide.md`.
- Vite official guide: https://vite.dev/guide/
- TanStack Router docs: https://tanstack.com/router/latest/docs/overview
- Dexie React tutorial: https://dexie.org/docs/Tutorial/React
- Zod docs: https://zod.dev/
- GitHub Pages docs: https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages
- GitHub Pages limits: https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits
- MDN IndexedDB API: https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API
- MDN storage quotas and eviction: https://developer.mozilla.org/en-US/docs/Web/API/Storage_API/Storage_quotas_and_eviction_criteria
