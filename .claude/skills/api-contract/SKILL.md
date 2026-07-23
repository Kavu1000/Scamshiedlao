---
name: api-contract
description: >-
  Keep the shared scan API contract consistent across all four surfaces when a
  backend request/response shape or the risk thresholds change. Use whenever editing
  ScanResult/ScanRequest/ScamReport in the backend, renaming a JSON field, or changing
  the LOW/MEDIUM/HIGH/CRITICAL buckets — so the extension, Next popup, and Flutter app
  don't silently drift out of sync.
---

# Keep the API contract in sync across surfaces

One FastAPI backend serves three clients. A field rename or threshold change in one place must be mirrored in the others, or a client breaks silently (missing field → undefined/null, misbucketed risk → wrong color/message).

## Source of truth
`backend/models/scan_result.py` — `ScanRequest`, `ScanResult`, `ScamReport`, `ScamReportResponse`. JSON keys are **snake_case**: `risk_score`, `risk_level`, `scam_type`, `reasons`, `flagged_phrases`, `is_scam`, `confidence`, `heuristic_score`, `ai_analyzed`, `url`, `page_title`, `from_cache`.

## The four surfaces to update together
1. **Backend** — `backend/models/scan_result.py` (Pydantic) + wherever `analyze_content` builds the result dict in `backend/services/scam_detector.py`.
2. **Extension** — `extension/background.js` (only backend caller) and `extension/content.js` (`showPageBanner`/`highlightFlaggedElements` read `risk_level`, `risk_score`, `reasons`, `scam_type`, `is_scam`, `flagged_phrases`). Popup rendering in `extension/popup/popup.js`.
3. **Next popup preview** — `popup/src/lib/api.ts` and its TypeScript types.
4. **Flutter app** — `scamshield_lao_mobile/lib/models/*.dart` `fromJson` (`scan_result.dart`, `history_item.dart`, `scam_report.dart`, `stats.dart`) and `lib/services/api_service.dart`.

## Risk thresholds — must be identical everywhere
**LOW 0–9 / MEDIUM 10–50 / HIGH 51–75 / CRITICAL 76–100.** Defined in:
- `backend/services/scam_detector.py` → `_risk_level`
- `backend/ai/openrouter_client.py` → `SYSTEM_PROMPT` risk-score guide (keep in lockstep with `_risk_level`)
- extension banner/badge coloring (`content.js`, `background.js`, `popup.js`)
- Flutter risk colors in `scamshield_lao_mobile/lib/config/app_constants.dart` (`kRiskLow/Medium/High/Critical`)

## Checklist when the contract changes
- [ ] Update the Pydantic model + result builder.
- [ ] Grep each surface for the affected field name and update readers/types.
- [ ] If risk buckets changed, update all four bucket definitions above.
- [ ] Re-verify with the `scan-test` skill (clear `scan_cache` first).
- [ ] For Flutter, run `flutter analyze`; for the Next preview, `pnpm lint`.
- [ ] Note in your summary that a contract change happened and which clients you touched.
