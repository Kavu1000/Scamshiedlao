# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

ScamShield Lao is a real-time scam detection system for Lao-language and English web content, built as three coordinated pieces:

- **`extension/`** — Chrome MV3 extension (plain JS, no build step). `content.js` extracts page text and renders risk overlays/banners; `background.js` is the service worker that talks to the backend and manages badge/session state. **`extension/popup/` is a hand-authored, self-contained vanilla popup** (`index.html` + `popup.css` + `popup.js`, no inline scripts, relative asset paths) — this is what the extension actually loads. It is NOT the Next.js build output.
- **`popup/`** — Next.js app kept only as a browser-based design/preview playground (`npm run dev` at localhost:3000). **Its static export can NOT run as the extension popup**: Next.js emits inline bootstrap `<script>` tags that MV3's extension CSP (`script-src 'self'`, no `'unsafe-inline'` allowed) blocks, and it uses absolute `/_next/` asset paths that 404 from the `popup/` subdirectory. Do not copy `popup/out/` over `extension/popup/` — that re-breaks the extension.
- **`backend/`** — Python FastAPI service (`localhost:8000`) that does the actual scam analysis and talks to MongoDB.

## Commands

### Backend (FastAPI + MongoDB)

```bash
cd backend
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # then add OPENROUTER_API_KEY
```

Run the server from the repo root (loads `backend/.env` automatically, creates it from `.env.example` if missing):
```bash
./start_backend.sh
# equivalent to: python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload
```
API docs at `http://localhost:8000/docs`. There is no automated test suite or Python linter configured in this repo.

A local or reachable MongoDB instance is required at startup — `connect_db()` in [backend/services/db.py](backend/services/db.py) creates indexes (including a TTL index) during the FastAPI `lifespan`, so the app will fail to start without one.

### Popup UI (Next.js)

```bash
cd popup
npm install
npm run dev     # local preview at http://localhost:3000, talks to backend via NEXT_PUBLIC_API_URL or localhost:8000
npm run build   # static export -> popup/out/
npm run lint
```

### Building/loading the extension

The extension has **no build step**. `extension/popup/` is edited directly (plain HTML/CSS/JS). `extension/manifest.json` points its popup at `popup/index.html` relative to `extension/`.

To load the extension: open `chrome://extensions/`, enable Developer mode, "Load unpacked", select the `extension/` folder.

Note on reloading: an unpacked extension's ID is derived from its folder path, so removing + re-adding from the same path keeps the same `chrome-extension://` origin and Chrome may serve the **popup from cache**. To force-refresh the popup after editing: open it, right-click → Inspect, check "Disable cache" in the Network tab, then ⌘R. Bumping `version` in `manifest.json` is a quick way to confirm a reload actually took effect.

## Architecture

### Two-stage scan pipeline

All scam detection logic lives in [backend/services/scam_detector.py](backend/services/scam_detector.py), invoked from `POST /api/scan`:

1. **Heuristic pre-filter** (`_heuristic_score`) — scores 0–100 by matching text/URL against pattern lists loaded once at import time from [backend/data/seed_patterns.json](backend/data/seed_patterns.json) (Lao/English keywords, urgency phrases, WhatsApp CTAs, high-salary regexes, blocked domains, and per-scam-type keyword sets used to guess `scam_type`).
2. **AI analysis** (only runs if heuristic score >= 40) — [backend/ai/openrouter_client.py](backend/ai/openrouter_client.py) sends the page text to DeepSeek-R1 via OpenRouter with a system prompt demanding strict JSON output, retried up to 3x with exponential backoff. If no API key is configured, or the request errors, it falls back to a neutral zero-risk result rather than failing the scan.

Final `risk_score` = `heuristic_score * 0.30 + ai_score * 0.70` when AI ran, otherwise just the heuristic score. `risk_level` buckets: LOW (0–9) / MEDIUM (10–50) / HIGH (51–75) / CRITICAL (76–100).

### Caching and persistence (MongoDB, via `backend/services/db.py`)

- `scan_cache` — keyed by `content_hash` (md5 of `url + text[:500]`), 24h TTL index. Every scan checks this first and short-circuits with `from_cache: true` on a hit — identical content is never re-sent to the AI.
- `scan_sessions` — one row per scan when a `session_id` is provided, used for `/api/history` (paginated per-session) and `/api/stats` (aggregate counts/breakdowns via Mongo aggregation pipelines).
- `scam_reports` — user-submitted reports from `POST /api/report`.

Routes are thin: each file under `backend/routes/` just validates/shapes the request and delegates to `services/`. `backend/config.py` loads settings from `backend/.env` (path resolved relative to the file, not CWD) via `pydantic_settings`, cached with `lru_cache` — call `get_settings()` rather than constructing `Settings()` directly.

### Extension <-> backend data flow

`content.js` extracts page text (whole-page text on load, plus per-element text blocks matched against `flagged_phrases` for overlay placement) and sends it via `chrome.runtime.sendMessage` to `background.js`. `background.js` owns the persistent `sessionId` (stored in `chrome.storage.local`) and is the only place that calls the backend (`POST /api/scan`, `POST /api/report`) — it forwards results back to the content script and updates the toolbar badge color/text based on `risk_level`. The popup UI (`popup/src/lib/api.ts`) hits the same backend endpoints directly and falls back to `localStorage`-based session IDs when running outside the extension context (e.g. `npm run dev` in a browser tab).

CORS in `backend/main.py` currently allows `origins=["*"]` regardless of `ALLOWED_ORIGINS`, since Chrome extension origins need wildcard support.

## Notes

- `popup/CLAUDE.md` / `popup/AGENTS.md` contain a note claiming this is a modified Next.js with breaking changes and to consult docs under `node_modules/next/dist/docs/` before writing code. That directory does not exist in a normal Next.js install and no such docs were found in this repo — treat that instruction with skepticism rather than acting on it blindly.
