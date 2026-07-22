# ScamShield Lao — Mobile App

Flutter mobile app clone of the ScamShield Lao Chrome extension.

## Architecture

```
lib/
├── config/          # Theme, constants, router
├── models/          # Data models (mirrors backend Pydantic schemas)
├── services/        # API client, session, settings, clipboard
├── providers/       # Riverpod state management
├── screens/
│   ├── home/        # Scan + result display
│   ├── history/     # Scan history with filter tabs
│   ├── report/      # Submit scam reports
│   ├── stats/       # Aggregate statistics dashboard
│   └── settings/    # Language, sensitivity, backend URL
└── shared/          # Reusable widgets + extensions
```

## Getting Started

```bash
# 1. Install Flutter (if not installed)
# https://docs.flutter.dev/get-started/install

# 2. Install dependencies
flutter pub get

# 3. Make sure the backend is running
cd ../
./start_backend.sh   # starts FastAPI on http://localhost:8000

# 4. Run on a device/simulator
flutter run

# 5. Build release APK (Android)
flutter build apk --release
```

## Backend

This app connects to the **same FastAPI backend** as the Chrome extension.
No backend changes are needed — just point the app at your server URL in Settings.

Default: `http://localhost:8000` (for development with a local backend)

For production, deploy the backend and update the URL in the Settings screen.

## API Endpoints Used

| Method | Endpoint | Feature |
|--------|----------|---------|
| `POST` | `/api/scan` | Scan text/URL for scams |
| `GET` | `/api/history` | Fetch scan history |
| `POST` | `/api/report` | Submit a scam report |
| `GET` | `/api/stats` | Aggregate detection statistics |
| `GET` | `/api/health` | Backend connectivity check |

## Screens

| Screen | Maps From |
|--------|-----------|
| **Home** | `popup/src/app/page.tsx` — scan + risk card |
| **History** | `popup/src/app/history/page.tsx` — filter tabs |
| **Report** | Extension `/api/report` — now a first-class screen |
| **Stats** | Extension `/api/stats` — new dedicated dashboard |
| **Settings** | `popup/src/app/settings/page.tsx` — language, sensitivity |

## Mobile-Specific Features

- **Clipboard scanner** — paste a URL or suspicious text from any app
- **Session management** — UUID-based session (replaces `chrome.storage.local`)
- **Persistent settings** — stored via SharedPreferences
- **Full dark theme** — matching the extension popup's design tokens

Built for the Lao Hackathon 2026 🇱🇦
