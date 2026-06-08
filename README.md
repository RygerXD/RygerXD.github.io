# Workout App Rewrite

## Current status

- GoRouter shell navigation (`Home`, `Library`, `Settings`).
- Design tokenized theme setup.
- Core workout plan domain models and parser/validator with `schemaVersion` enforcement.
- Active workout state machine with explicit transitions (`prep`, `move`, `rest`, `restBetweenLoops`, `paused`, terminal states).
- Repository interface and in-memory implementation.
- JSON schema and example plans:
  - `docs/schemas/workout-plan.schema.json`
  - `docs/schemas/examples/valid.plan.json`
  - `docs/schemas/examples/invalid.plan.json`
- AI workout conversion guide:
  - `docs/ai-workout-json-guide.md`
- Unit tests for parser and state machine transitions.

## Run locally

1. Install Flutter stable SDK.
2. Run:
   - `flutter pub get`
   - `flutter analyze`
   - `flutter test`
   - `flutter run -d chrome --web-port 7357`
