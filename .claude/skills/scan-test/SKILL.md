---
name: scan-test
description: >-
  Exercise the backend scan API and manage the scan cache. Use when verifying a
  detection/pipeline change, reproducing a score, checking why a page was rated
  LOW/MEDIUM/HIGH/CRITICAL, or when a change "isn't showing up" (usually a stale
  cache hit). Covers /api/scan, /api/health, and clearing scan_cache / test sessions.
---

# Test the scan API & manage the cache

Backend must be running (`run-stack`). Risk buckets: **LOW 0–9 / MEDIUM 10–50 / HIGH 51–75 / CRITICAL 76–100**.

## The cache gotcha (read first)
Every scan is keyed by `content_hash = md5(url + text[:500])` and cached for 24h. A hit short-circuits with `"from_cache": true` — so **a logic change won't show until you clear the cache or vary the input**. If a test result looks unchanged after you edited detection, this is almost always why.

## Scan a sample
```bash
curl -s -X POST http://localhost:8000/api/scan \
  -H 'Content-Type: application/json' \
  -d '{
    "text": "URGENT! Work from home, earn $5000/month, no experience. Add our WhatsApp now to start!",
    "url": "http://example.com/job",
    "page_title": "Dream Job",
    "session_id": "test-session"
  }' | python3 -m json.tool
```
Check `risk_score`, `risk_level`, `scam_type`, `reasons` (risk reasons for MEDIUM+, "safe because…" only for LOW), `flagged_phrases`, `is_scam`, `ai_analyzed`, `from_cache`.

Suggested spread when validating detection: a benign control (expect LOW), a mild-signal page (MEDIUM), and a strong job/trafficking/crypto sample (HIGH/CRITICAL). Vary `text` or `url` between runs so you don't hit the cache. Include a Lao-language sample — Lao keywords match raw (case-sensitive) text.

## Clear the cache / test data
Clearing `scan_cache` forces fresh analysis. Do this between edits, and delete any `test-session` rows you created afterward. Use a small Python snippet with the same driver/URL the app uses (motor + `settings.mongodb_url` from `backend/.env`) — e.g. `db.scan_cache.delete_many({})` and `db.scan_sessions.delete_many({"session_id": "test-session"})`. Never print the connection string.

## Other endpoints
```bash
curl -s http://localhost:8000/api/health
curl -s "http://localhost:8000/api/history?session_id=test-session&page=1&limit=20" | python3 -m json.tool
curl -s http://localhost:8000/api/stats | python3 -m json.tool
```
Full interactive docs: http://localhost:8000/docs
