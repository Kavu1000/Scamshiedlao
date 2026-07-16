# ScamShield Lao

> Real-time scam detection browser extension for Lao users, powered by **DeepSeek-R1 AI** via OpenRouter.

---

## 🏗 Architecture

```
Browser Extension (Chrome Manifest V3)
  ├── content.js        → Scans page text, injects risk overlays
  ├── background.js     → Routes messages to backend API
  └── popup/ (Next.js)  → React UI with status, history, settings

Python FastAPI Backend (localhost:8000)
  ├── /api/scan         → Two-stage: heuristics → DeepSeek-R1 AI
  ├── /api/report       → User scam reports
  ├── /api/history      → Scan history
  └── /api/stats        → Aggregate stats

MongoDB
  ├── scan_cache        → 24h result cache
  ├── scan_sessions     → Per-session history
  └── scam_reports      → User reports
```

## 🚀 Getting Started

### 1. Backend

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

cp .env.example .env
# Edit .env and add your OPENROUTER_API_KEY

# Run server
./start_backend.sh
# → http://localhost:8000
# → Swagger docs: http://localhost:8000/docs
```

### 2. Popup UI

```bash
cd popup
npm install
npm run dev       # Development preview
npm run build     # Build for extension
```

### 3. Load Extension in Chrome

1. Open `chrome://extensions/`
2. Enable **Developer mode** (top right)
3. Click **Load unpacked**
4. Select the `extension/` folder

---

## 🔑 Environment Variables

| Variable | Description |
|---|---|
| `MONGODB_URL` | MongoDB connection string |
| `MONGODB_DB_NAME` | Database name (default: `scamshield_lao`) |
| `OPENROUTER_API_KEY` | Your OpenRouter API key |
| `DEEPSEEK_MODEL` | Model ID (default: `deepseek/deepseek-r1`) |

---

## 🛡 Features

- **Real-time page scanning** — content script extracts text on page load
- **Two-stage AI pipeline** — fast heuristics + DeepSeek-R1 reasoning model
- **Lao + English** scam detection
- **Risk overlays** — red borders + score badges on flagged content
- **5 scam categories**: job scam, trafficking, phishing, crypto fraud, romance scam, gambling
- **MongoDB caching** — 24h TTL prevents repeat API calls
- **Scan history** with filter by risk level
- **User reporting** for manual scam submissions

---

Built for the Lao Hackathon 2026 🇱🇦
# Scamshiedlao
