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

## Deploy to GitHub Pages

This repo includes a GitHub Actions workflow that builds the Flutter web app and
publishes it to GitHub Pages on every push to `main`.

1. Push the repo to GitHub.
2. In GitHub, open `Settings` > `Pages`.
3. Set `Build and deployment` > `Source` to `GitHub Actions`.
4. Push to `main`, or run the `deploy-pages` workflow manually.

The workflow automatically sets Flutter's web base path for the GitHub Pages
domain:

- Project site repos deploy at `https://<username>.github.io/<repo-name>/`.
- User or organization site repos named `<username>.github.io` deploy at
  `https://<username>.github.io/`.
