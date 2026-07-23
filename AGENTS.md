# Repository Guidelines

## Project Structure & Module Organization

ScamShield Lao has four coordinated parts. `backend/` contains the FastAPI API: keep endpoint validation in `routes/`, Pydantic contracts in `models/`, detection and persistence logic in `services/`, and AI-provider code in `ai/`. `extension/` is the Chrome Manifest V3 extension; its production popup is the hand-authored `extension/popup/` HTML/CSS/JS. `popup/` is only a Next.js browser preview and must not be copied over the extension popup. `scamshield_lao_mobile/` contains the Flutter client, organized into `screens/`, `providers/`, `services/`, `models/`, and shared widgets. Detection patterns live in `backend/data/seed_patterns.json`.

## Build, Test, and Development Commands

- `python3 -m venv backend/venv && source backend/venv/bin/activate && pip install -r backend/requirements.txt` — install backend dependencies.
- `./start_backend.sh` — run the API with reload on `localhost:8000`; MongoDB must be reachable.
- `cd popup && npm install && npm run dev` — run the Next.js preview on port 3000.
- `cd popup && npm run lint && npm run build` — lint and produce the preview export in `popup/out/`.
- `cd scamshield_lao_mobile && flutter pub get && flutter run` — install packages and launch the mobile app.
- `cd scamshield_lao_mobile && flutter analyze && flutter test` — run Dart analysis and tests.

The extension has no build step. Load `extension/` as an unpacked extension in Chrome and reload it after edits.

## Coding Style & Naming Conventions

Use four spaces and `snake_case` for Python functions/modules; keep routes thin and add type annotations. TypeScript/JavaScript uses two spaces, semicolons, `camelCase` variables, and `PascalCase` React components. Format Dart with `dart format .`; follow `flutter_lints`, use `snake_case.dart` filenames, and `PascalCase` types. Preserve Lao text as UTF-8.

## Testing Guidelines

Only Flutter currently has an automated suite. Add tests under `scamshield_lao_mobile/test/` with `*_test.dart` names. For backend or extension changes, document manual verification (API endpoint, scanned page, risk level, and browser behavior) until dedicated suites are added.

## Commit & Pull Request Guidelines

Prefer concise, imperative Conventional Commit subjects such as `feat: add report validation` or `fix: clear stale badge`. Keep commits scoped to one component. Pull requests should summarize behavior, identify affected components, link issues, list commands/manual checks run, and include screenshots or recordings for popup, overlay, or mobile UI changes.

## Security & Configuration

Copy `backend/.env.example` to `backend/.env`. Never commit API keys, database credentials, session data, or generated build directories. Keep environment-specific API URLs and secrets out of source files.
