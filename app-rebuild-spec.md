---
description: Specification for rebuilding the Workout App from scratch, focusing purely on features and functionality rather than current code structure.
---

# Workout App - Rebuild Specification

## 1. Core Philosophy & Data Model
- **Local-First & Offline**: All data resides locally using SQLite for session history and JSON files for workout templates.
- **Web Support**: Utilizes SQLite WASM (via `drift`) to maintain persistence and seamless operation when running as a web app.
- **Portability**: Workouts are defined as human-readable JSON files, allowing easy sharing, importing, and exporting.
- **Migration**: This is a clean-slate rebuild. No automated migration from the previous app's database is required. Users can re-import their `.workout-plan.json` files; session history from the old app will not carry over.
- **Hierarchy**: `Workout Plan` -> `Workout(s)` -> `Set(s)` -> `Move(s)` -> `Exercise`.
  - An **Exercise** is a canonical definition (name, image URL, description). It is a reusable reference entity.
  - A **Move** is an *instance* of an Exercise within a specific Set, carrying execution parameters: `repCount`, `duration`, `prepTime`, `finishTime`, `targetWeight`, `targetWeightUnit`, `metronomeSpeed`.
  - A Plan can have multiple Workouts.
  - Sets can loop (e.g., 3 rounds) with specified `restBetweenLoops`.
  - Moves can be rep-based or time-based.
  - **Duration Estimates**: Plans/Workouts dynamically estimate duration based on historical completion times of specific exercises. **Fallback**: When no history exists, the estimate is calculated by summing all `prepTime` + `duration` + `finishTime` for each Move, plus `restBetweenLoops x (loopCount - 1)` for each Set.

### 1.1 Identity & Versioning Rules
- Every persisted entity must have a stable string ID: `planId`, `workoutId`, `setId`, `moveId`, `exerciseId`, `sessionId`.
- IDs are generated as UUIDs at creation/import time and are immutable.
- `sessionId` values are always new per run; sessions never overwrite prior history rows.
- Duplicating a plan creates a new `planId` and new child IDs (`workoutId`, `setId`, `moveId`) while preserving referenced `exerciseId` values when definitions are equivalent.
- Import collision handling:
  - If incoming `planId` already exists, assign a new `planId` and keep original as `sourcePlanId` metadata.
  - If incoming `exerciseId` exists with materially different content (name, description, media URL), assign a new `exerciseId` and record a conflict warning.
- `.workout-plan.json` requires `schemaVersion` (integer). Import must fail with a user-facing error when unsupported.

### 1.2 Source of Truth Boundaries
- JSON files are the source of truth for plan structure/content (`WorkoutPlan`, `Workout`, `Set`, `Move`, `Exercise`).
- SQLite is the source of truth for runtime/history/metadata (`WorkoutSessions`, `SetSessions`, `MoveSessions`, favorites, use counts, import timestamps).
- Editing a plan updates JSON content and refreshes derived SQLite metadata; it must not mutate historical session records.
- Deleting a plan removes plan metadata and detaches references, but does not hard-delete historical sessions. History is retained and marked with a deleted-plan flag.

## 2. Main Features / Screens

### A. Dashboard / Home
- **Dynamic Greetings**: Displays time-based greetings (Good Morning / Afternoon / Evening) alongside a rotating daily motivational message.
- **Stat Highlights**: "Workouts This Week" count and "Total Time" aggregated across the current week.
- **Quick Start Section**: Displays up to 3 plans. Prioritizes plans marked as `isFavorite`; falls back to recently used/imported plans. Selecting a plan opens its Workout Detail screen.
- **Recent Activity Timeline**: A chronological list of recent `workout_sessions`, displaying the plan name, workout title, date grouping (Today, Yesterday, MM/DD), duration, and status (Completed vs. Abandoned).

### B. Workout Library
- **Browsing**: Displays list of imported/created workout plans. Organized into two distinct sections: "Favorites" and "All Plans".
- **Actions**:
  - **Import Plan**: Load `.workout-plan.json` from a local file picker OR download directly from a provided URL.
    - URL import accepts only `https://` by default (`http://` optional behind explicit user confirmation).
    - Enforce max import size (5 MB default), timeout (15 seconds), and strict schema validation before persistence.
    - Validation errors must be surfaced as actionable messages (field path + reason) and must not partially write data.
  - **Export Plan**: Save plan as `.workout-plan.json`.
  - **Duplicate/Edit Plan**: Full JSON-based copy modification.

### C. Create & Edit Plan / Workout
- **Create Plan Details**: User supplies Name, Description, Author, Image URL, and dynamically adds/removes Tags.
- **Edit Workout UI**:
  - Add, adjust order, or remove Sets.
  - Specify `loopCount` and `restBetweenLoops` for each set.
  - **Move Management**: Add new custom moves or launch the **Existing Move Picker** (which scans all loaded plans to offer a list of previously defined exercises, reducing duplicate data entry).

### D. Workout Detail
- Preview list of all sets and moves, displaying exercise images where available.
- Total estimated duration calculation (using history-based or fallback formula from Section 1).
- Start Workout button.

### E. Active Workout Execution
- **State Machine Engine**: Guided progression through Prep -> Go (Move) -> Rest -> Next Move.
- **Guarded State**: Will prompt with "Abandon Workout?" warning dialog if user tries to close the screen while active to prevent accidental data loss.
- **Timers**: Countdown ring for time-based moves/rests; count-up generic tracking for rep-based moves.
- **Smart Defaults (Granular History)**: Dynamically fetches the logged `repCount` or `duration` from the user's *most recent historic completion* of that specific Exercise (matched by Exercise ID, tracked down to the loop iteration). Defaults to this historic value, and the user can +/- actual reps before clicking "Complete".
- **Audio/Metronome**: Optional metronome with adjustable BPM (`just_audio`).
- **Controls**: Pause, Resume, Skip Move, Skip Rest, Start Prep Now, Finish early.
- **Visuals**: Displays exercise imagery (GIF/image) and caches them locally for offline use. **Fallback**: When an image URL is missing, broken, or not yet cached, display a styled placeholder (exercise name initials over a themed gradient).
- **Background Handling**: If the user backgrounds the app mid-workout, timers continue running. On mobile, a local notification is fired when a phase transition occurs (e.g., "Rest is over - next move is ready") so the user can return to the app.

#### State Machine Contract (Required Transitions)
- `idle -> prep -> move -> rest -> move ... -> completed`
- `prep|move|rest -> paused -> (resume returns to prior phase)`
- `prep|move|rest -> skipped -> next logical phase`
- `prep|move|rest -> abandoned` (only via explicit confirmation)
- `prep|move|rest -> completed_early` (stores completion with `endedEarly=true`)
- Loop handling: at end of each set loop, transition to `rest_between_loops` or advance to the next set/workout when final loop is done.
- Every transition must emit a timestamped event persisted in session history for audit/debug analytics.

#### Platform Behavior Guarantees
- Android/iOS: phase transitions trigger local notifications when app is backgrounded and notifications are permitted.
- Web: when tab is backgrounded, timers use wall-clock reconciliation on resume; notifications are best-effort via browser APIs.
- If background execution is constrained by OS/browser, app must reconcile elapsed time on foreground and show a "time adjusted" banner.

### F. Analytics & History
- **Workout Heatmap**: A calendar-style chart visually representing the density/frequency of workouts completed on specific dates (like a GitHub commit graph). Scope: trailing 12 months.
- **Session Grouping**: Completed logs grouped under relative headers ("Today", "Yesterday", "Monday", or strict dates).
- **Exercise Analysis**: Drill down into a specific Exercise to see performance over time.
  - **Metrics**: Total reps per session, estimated volume (`reps x weight`), and personal best tracking.
  - **Visualization**: A simple line chart showing the selected metric over the last 30/60/90 days (user-toggleable).
- **Empty States**: Clear messaging and calls to action when history or plans are empty.

#### Analytics Semantics (Required)
- All date grouping uses the user's local timezone at render time.
- "This Week" is ISO week by default (Monday start); start-of-week must be configurable in Settings.
- "Completed" means final state `completed` or `completed_early`; "Abandoned" means final state `abandoned`.
- Volume formula applies only when both reps and weight are present and valid; otherwise volume is `null` and excluded from aggregates.
- DST/timezone changes must not duplicate or drop sessions; history uses UTC timestamps with local conversion at display time.

### G. Settings
- Dark / Light Theme toggle.
- System preferences (e.g., metric vs imperial unit selection).
- Audio Cues toggle (metronome and transitions).
- Data management (Export Data or Clear All Data completely).
- About / Version Info (app version, build number).

## 3. Background / Utility Capabilities
- **Image Caching Engine**: Proactively downloads and caches exercise images/GIFs for guaranteed offline playback. On web, falls back to browser cache / service worker caching.
- **Audio Hooks**: Audio cues for phase transitions (start of move, end of rest) and metronome ticking.
- **Database Persistence Middleware**: Utilizing `drift` (SQLite/WASM) for saving robust historical performance data linked to the JSON IDs (`WorkoutSessions`, `SetSessions`, `MoveSessions`, and specific `ExerciseRepHistory` metadata). Also tracks `WorkoutPlansMetadata` for favorite status, use counts, and web fallback content.
- **JSON Parsing Service**: Validation, error handling, and object hydration of shared JSON files into usable plan hierarchies. The canonical `.workout-plan.json` schema should be documented separately (or embedded in this spec as an appendix) and versioned with a `schemaVersion` field to support future format evolution.
- **Reliability Constraints**:
  - Persistence writes must be atomic per logical unit (import transaction, session transition, session finalize).
  - Corrupted JSON and SQLite quota/write failures must be recoverable with explicit user-facing remediation steps.
  - Critical parsing and persistence failures must include structured log fields (`errorCode`, `entityId`, `schemaVersion`, `platform`).

---
**Development Goal**: Redesign the internal architecture (state management, component boundaries, UI hierarchy) across these features while retaining or strictly enhancing exact user-facing behavior. No regressions in offline capability, data portability, and local analytics are permitted.

## 4. Technical Constraints & Architecture

To eliminate technical debt and ensure a highly scalable, "no-fluff" codebase, this rebuild enforces the following stack and design patterns:

### Tech Stack
- **Framework**: Flutter (targeting Mobile + Web).
- **State Management**: Riverpod (current stable major) utilizing Code Generation (`@riverpod`). Prefer `Notifier` and `AsyncNotifier` patterns; use `StateNotifier` only when a clear documented justification exists.
- **Database**: `drift` (with Web WASM support via `sqlite3` for cross-platform local persistence).
- **Routing**: `go_router` for deeply nested navigation and type-safe routes. Utilize `StatefulShellRoute` for the bottom-navigation pattern.
- **Domain Models**: `freezed` for immutable data classes with `copyWith`, value equality, and sealed unions. `json_serializable` for JSON (de)serialization of plan files.
- **Media**: `just_audio` for audio hooks and metronome. **Note**: Web/WASM audio latency should be validated early; fall back to Web Audio API via JS interop if `just_audio` web performance is inadequate. `cached_network_image` for offline-first image rendering on mobile; verify web/WASM compatibility or implement a simple HTTP + local-storage caching wrapper for web.

### Architecture Rules
- **Feature-First (Screaming Architecture)**: Folders must be organized by feature (e.g., `lib/features/library`, `lib/features/active_workout`) rather than type (e.g., `lib/screens`, `lib/providers`). UI, providers, and local services for a feature live together.
- **Unidirectional Data Flow**: UI strictly listens to Riverpod providers; providers interact with domain logic and repositories.
- **Repository Pattern**: Database interactions (Drift) MUST be hidden behind abstract Repository interfaces (e.g., `WorkoutRepository`, `HistoryRepository`). Feature logic should never import Drift generated code directly.
- **Pure Domain Models**: Core business logic (`WorkoutPlan`, `Set`, `Move`) must be pure Dart classes entirely independent of Flutter framework imports.
- **Global Error Handling**: No isolated print statements or unhandled exceptions. Implement a core logging service and utilize Riverpod's built-in hooks (`AsyncValue.error` and `ProviderObserver`) to elegantly catch and surface errors (e.g., WASM quota issues, corrupted JSON).
- **Testing Strategy**: Writing pure Domain Models and Repositories ensures high testability. Unit tests are required for all parsing logic and state machine transitions in the `active_workout`.
- **Design System Isolation**: Hardcoded colors and padding are prohibited. The app must implement an `AppTheme` utilizing strict design tokens (e.g., `AppSpacing.md`, `AppColors.primary`) to ensure visual consistency and trivial theme expansions.
- **Strict Linting & CI/CD**: To permanently prevent technical debt, the project must enforce strict static analysis (e.g., using `very_good_analysis` or customized `flutter_lints`). An automated pipeline (e.g., GitHub Actions) should be configured to verify formatting, run unit tests, and compile the Web WASM build on every commit.

## 5. Acceptance Criteria & Non-Functional Requirements

### Feature Acceptance Criteria (Minimum)
- Dashboard:
  - Shows greeting + message, weekly workout count, weekly total time, quick-start plans, and recent activity without runtime errors on empty data.
- Library:
  - Import/export/duplicate/edit all function offline (except remote URL fetch) and maintain schema-valid JSON.
- Plan Editor:
  - Reorder, add, remove sets/moves with stable IDs and no orphan references.
- Workout Detail:
  - Displays deterministic estimated duration with explicit fallback when no history exists.
- Active Workout:
  - Executes required state transitions; confirmation required before abandonment; session outcome persisted exactly once.
- Analytics:
  - Heatmap and charts render correctly for trailing 12 months; empty states present where data is missing.
- Settings:
  - Theme, units, audio preferences, and data-management actions persist across app restarts.

### Non-Functional Budgets
- Cold start target (release mode):
  - Mobile: < 2.5 seconds on mid-tier device.
  - Web: first interactive paint < 4.0 seconds on broadband desktop baseline.
- Import performance:
  - 5 MB plan file parse + validate + persist in < 2 seconds on baseline mobile hardware.
- Storage/cache limits:
  - Image cache default cap: 250 MB mobile, browser-managed quota on web with graceful eviction.
  - When quota is exceeded, app must evict least-recently-used images first and show a non-blocking warning.
- Reliability:
  - No data loss for finalized sessions during app restart/crash scenarios after transition event is persisted.
  - Automated tests must cover parsing, ID collision handling, and all state-machine transitions.
