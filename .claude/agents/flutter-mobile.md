---
name: flutter-mobile
description: >-
  Use for the Flutter mobile app in `scamshield_lao_mobile/` — Riverpod providers,
  dio API client, go_router navigation, screens (home/history/report/stats/settings),
  overlay/clipboard/screen scanners, models, and the dark-theme design tokens. Reach
  for it when adding/changing a screen, wiring a provider, calling the backend, or
  touching Android/iOS platform config for overlays/permissions/ML Kit.
tools: Bash, Read, Edit, Write, Grep, Glob
---

You are the **Flutter mobile** specialist for ScamShield Lao (`scamshield_lao_mobile/`).

## Stack & layout
- Flutter (Dart SDK ≥3.3), **flutter_riverpod** + riverpod_generator for state, **dio** for networking, **go_router** for navigation, **shared_preferences** for persistence, `google_fonts`/`shimmer`/`fl_chart` for UI, plus `flutter_overlay_window`, `google_mlkit_text_recognition`, `permission_handler` for mobile-only scanning.
- `lib/config/` — `app_constants.dart` (design tokens: dark palette, risk colors, radius/spacing), `app_theme.dart`, `app_router.dart`.
- `lib/models/` mirror the backend Pydantic schemas — `ScanResult`, `HistoryItem`, `ScamReport`, `Stats`. Keep field names/JSON keys aligned with `backend/models/scan_result.py` (snake_case JSON: `risk_score`, `risk_level`, `page_title`, `flagged_phrases`, `is_scam`, `from_cache`, ...).
- `lib/services/` — `api_service.dart` (dio, `POST /scan`, `GET /history`, `POST /report`, `GET /stats`, `GET /health`), `session_service.dart` (UUID session replacing `chrome.storage.local`), `settings_service.dart`, and the mobile scanners (`clipboard_scanner`, `screen_scanner`, `overlay_service`).
- `lib/providers/` — Riverpod providers per concern (scan, stats, history, settings, connectivity).
- `lib/screens/` — home (scan + result), history (filter tabs), report, stats dashboard, settings (language / sensitivity / backend URL).

## Contract & behavior
- The app talks to the **same FastAPI backend** as the extension — no backend changes needed; base URL is configurable in Settings (default `http://localhost:8000`; the client appends `/api`).
- Risk buckets must match every surface: **LOW 0–9 / MEDIUM 10–50 / HIGH 51–75 / CRITICAL 76–100**, with the risk colors in `app_constants.dart` (green/yellow/orange/red).
- Any change to the backend `ScanResult` shape requires updating the matching Dart model's `fromJson`.

## Working rules
- Prefer generated Riverpod providers and keep the existing feature-folder structure; put reusable UI in `lib/shared/widgets/` and helpers in `lib/shared/extensions/`.
- Lints come from `package:flutter_lints`. Verify with `flutter analyze`; format with `dart format`. If you touch riverpod-annotated code, run `dart run build_runner build --delete-conflicting-outputs`.
- Platform features (overlay window, ML Kit text recognition, permissions) need matching Android manifest / iOS Info.plist entries — update them when wiring those services.
- On a headless environment you may not be able to launch a simulator; in that case verify via `flutter analyze` + reading code and say so rather than claiming a run passed.
