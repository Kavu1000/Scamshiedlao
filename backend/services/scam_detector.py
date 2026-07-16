import re
import json
import hashlib
from pathlib import Path
from typing import Optional
from backend.services.db import get_db
from backend.ai.openrouter_client import analyze_with_deepseek

# Load seed patterns once at startup
_PATTERNS_PATH = Path(__file__).parent.parent / "data" / "seed_patterns.json"
with open(_PATTERNS_PATH) as f:
    PATTERNS = json.load(f)

LAO_KEYWORDS: list[str] = PATTERNS["lao_keywords"]
ENGLISH_KEYWORDS: list[str] = PATTERNS["english_keywords"]
URGENCY_PHRASES: list[str] = PATTERNS["urgency_phrases"]
WHATSAPP_PATTERNS: list[str] = PATTERNS["whatsapp_patterns"]
HIGH_SALARY_PATTERNS: list[str] = PATTERNS["high_salary_patterns"]
BLOCKED_DOMAINS: list[str] = PATTERNS["blocked_domains"]
SCAM_TYPES: dict = PATTERNS["scam_types"]

HEURISTIC_WEIGHT = 0.30
AI_WEIGHT = 0.70


def _content_hash(text: str, url: str) -> str:
    return hashlib.md5(f"{url}:{text[:500]}".encode()).hexdigest()


def _heuristic_score(text: str, url: str) -> dict:
    """Fast keyword + regex based pre-filter. Returns score 0-100 and matched signals."""
    text_lower = text.lower()
    score = 0
    matched = []
    detected_type = "none"
    # Track which signal categories fired, so a clean scan can explain *why* it's safe.
    categories = {
        "keywords": False,
        "urgency": False,
        "whatsapp": False,
        "high_salary": False,
        "blocked_domain": False,
    }

    # Keyword matching
    for kw in LAO_KEYWORDS:
        if kw in text:
            score += 4
            matched.append(kw)
            categories["keywords"] = True

    for kw in ENGLISH_KEYWORDS:
        if kw.lower() in text_lower:
            score += 3
            matched.append(kw)
            categories["keywords"] = True

    # Urgency phrases
    for phrase in URGENCY_PHRASES:
        if phrase.lower() in text_lower:
            score += 5
            matched.append(phrase)
            categories["urgency"] = True

    # WhatsApp CTA (strong scam signal)
    for pat in WHATSAPP_PATTERNS:
        if pat.lower() in text_lower:
            score += 8
            matched.append(pat)
            categories["whatsapp"] = True

    # High salary promises
    for pattern in HIGH_SALARY_PATTERNS:
        if re.search(pattern, text, re.IGNORECASE):
            score += 10
            matched.append("High salary promise")
            categories["high_salary"] = True

    # Blocked domain check
    for domain in BLOCKED_DOMAINS:
        if domain in url:
            score += 40
            matched.append(f"Blocked domain: {domain}")
            categories["blocked_domain"] = True

    # Detect scam type from keywords
    for stype, keywords in SCAM_TYPES.items():
        hits = sum(1 for kw in keywords if kw.lower() in text_lower)
        if hits >= 2:
            detected_type = stype
            score += hits * 3

    score = min(score, 100)
    return {
        "heuristic_score": score,
        "matched_signals": matched[:10],
        "detected_type": detected_type,
        "categories": categories,
    }


def _safe_reasons(categories: dict, ai_analyzed: bool) -> list[str]:
    """Build positive 'safe because...' explanations from the checks that came back clean."""
    reasons = []
    if ai_analyzed:
        reasons.append("AI analysis reviewed the page and found no scam patterns")
    if not categories.get("high_salary"):
        reasons.append("No unrealistic salary figures promised (e.g. '$5,000/month')")
    if not categories.get("urgency"):
        reasons.append("No urgency or pressure tactics (e.g. 'act now', 'limited time')")
    if not categories.get("whatsapp"):
        reasons.append("No attempt to move you to WhatsApp or a private chat")
    if not categories.get("keywords"):
        reasons.append("No known scam or fraud keywords found in the page text")
    if not categories.get("blocked_domain"):
        reasons.append("This site's domain is not on any known-scam blocklist")
    return reasons[:4] or ["No strong scam indicators were detected on this page"]


def _risk_level(score: int) -> str:
    if score >= 76:
        return "CRITICAL"
    elif score >= 51:
        return "HIGH"
    elif score >= 10:
        return "MEDIUM"
    return "LOW"


async def analyze_content(
    text: str,
    url: str = "",
    page_title: str = "",
    session_id: Optional[str] = None,
) -> dict:
    """
    Two-stage scam detection pipeline:
    Stage 1: Fast heuristic pre-filter
    Stage 2: DeepSeek-R1 AI analysis (only if heuristic score >= 40)
    Final score: heuristic * 30% + AI * 70%
    """
    db = get_db()
    content_hash = _content_hash(text, url)

    # Check MongoDB cache first
    cached = await db.scan_cache.find_one({"content_hash": content_hash})
    if cached:
        result = cached["result"]
        result["from_cache"] = True
        return result

    # Stage 1: Heuristic
    heuristic = _heuristic_score(text, url)
    h_score = heuristic["heuristic_score"]

    # Stage 2: AI (only if heuristic score warrants it)
    ai_result = None
    if h_score >= 40:
        try:
            ai_result = await analyze_with_deepseek(text, url, page_title)
        except Exception as e:
            print(f"⚠️  AI analysis failed: {e}")
            ai_result = None

    # Compute final blended score
    if ai_result:
        ai_score = ai_result.get("risk_score", 0)
        final_score = int(h_score * HEURISTIC_WEIGHT + ai_score * AI_WEIGHT)
        reasons = ai_result.get("reasons", [])
        flagged_phrases = ai_result.get("flagged_phrases", heuristic["matched_signals"][:5])
        scam_type = ai_result.get("scam_type", heuristic["detected_type"])
        is_scam = ai_result.get("is_scam", final_score >= 50)
        confidence = ai_result.get("confidence", final_score / 100)
    else:
        final_score = h_score
        reasons = [f"Matched suspicious pattern: {s}" for s in heuristic["matched_signals"][:3]]
        flagged_phrases = heuristic["matched_signals"][:5]
        scam_type = heuristic["detected_type"]
        is_scam = final_score >= 50
        confidence = final_score / 100

    # Explanation list:
    #  - LOW risk (score <= 9)    -> positive "safe because..." reasons
    #  - MEDIUM / HIGH / CRITICAL -> keep the risk reasons (why it's suspicious)
    if final_score <= 9 and not is_scam:
        reasons = _safe_reasons(heuristic["categories"], ai_result is not None)
    elif not reasons:
        reasons = [f"Matched suspicious pattern: {s}" for s in heuristic["matched_signals"][:3]] \
            or ["Some suspicious elements were detected on this page"]

    result = {
        "risk_score": final_score,
        "risk_level": _risk_level(final_score),
        "scam_type": scam_type,
        "reasons": reasons,
        "flagged_phrases": flagged_phrases,
        "is_scam": is_scam,
        "confidence": round(confidence, 2),
        "heuristic_score": h_score,
        "ai_analyzed": ai_result is not None,
        "url": url,
        "page_title": page_title,
        "from_cache": False,
    }

    # Cache result in MongoDB (24h TTL set via index)
    from datetime import datetime, timezone
    await db.scan_cache.replace_one(
        {"content_hash": content_hash},
        {"content_hash": content_hash, "result": result, "created_at": datetime.now(timezone.utc)},
        upsert=True,
    )

    # Store in scan history if session provided
    if session_id:
        await db.scan_sessions.insert_one({
            "session_id": session_id,
            "url": url,
            "page_title": page_title,
            "risk_score": final_score,
            "risk_level": _risk_level(final_score),
            "scam_type": scam_type,
            "is_scam": is_scam,
            "created_at": datetime.now(timezone.utc),
        })

    return result
