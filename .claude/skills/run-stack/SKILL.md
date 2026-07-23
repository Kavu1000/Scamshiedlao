---
name: run-stack
description: >-
  Start, stop, or health-check the ScamShield Lao stack — the FastAPI backend
  (localhost:8000) and the Next.js popup preview (localhost:3000). Use when the user
  says "run the project", "start/stop backend and frontend", "restart the backend",
  or needs to confirm the servers are up before testing the extension or mobile app.
---

# Run the ScamShield Lao stack

Two long-running servers. Run them **in the background** so the session stays responsive, and always report the actual health-check result — never assume a server came up.

## Start the backend (FastAPI, port 8000)
Runs with `--reload`, so code edits hot-reload. Requires a reachable MongoDB Atlas and `backend/.env` (secrets — never print them).

```bash
cd /Users/ljthao/Documents/lj-project/Scamshiedlao && ./start_backend.sh
```
Run it in the background. Then confirm it's actually up:
```bash
curl -s http://localhost:8000/api/health
# expect: {"status":"ok","service":"ScamShield Lao API","version":"1.0.0"}
```
If health fails, read the server log. Common causes: Atlas IP allowlist stale, or the venv Python linked to old LibreSSL (use the Homebrew 3.12 venv with OpenSSL 3.x) — these are environment issues, not code bugs.

## Start the popup preview (Next.js, port 3000) — optional
This is a **design preview only**, not the extension. Use **pnpm**, not npm.
```bash
cd /Users/ljthao/Documents/lj-project/Scamshiedlao/popup && pnpm dev
```
Preview at http://localhost:3000. It talks to the backend via `NEXT_PUBLIC_API_URL` or defaults to localhost:8000.

## Stop everything
Kill only the listeners on each port:
```bash
lsof -ti :8000 -sTCP:LISTEN | xargs kill 2>/dev/null && echo "backend stopped"
lsof -ti :3000 -sTCP:LISTEN | xargs kill 2>/dev/null && echo "frontend stopped"
```

## Notes
- The extension and the Flutter app both hit the **same** backend — starting the backend is enough to test either; the Next preview is separate and usually unnecessary.
- After changing backend scan logic, a reload happens automatically (`--reload`), but you should still clear `scan_cache` before re-testing — see the `scan-test` skill.
