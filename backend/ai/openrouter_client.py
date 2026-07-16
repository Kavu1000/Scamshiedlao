# pyrefly: ignore [missing-import]
# pyrefly: ignore [missing-import]
# pyrefly: ignore [missing-import]
import httpx
import json

# pyrefly: ignore [missing-import]
from tenacity import retry, stop_after_attempt, wait_exponential
from backend.config import get_settings

settings = get_settings()

SYSTEM_PROMPT = """You are ScamShield AI, an expert scam detection system specializing in Lao and Southeast Asian online scams.

Your job is to analyze text content from web pages and determine if it contains scam, fraud, or human trafficking indicators.

You MUST respond with ONLY valid JSON, no additional text, no markdown, no code blocks.

Scam types to detect:
- job_scam: Fake overseas jobs, unrealistic salaries, no experience required
- trafficking: Human trafficking recruitment (free housing, flights, no visa needed)
- phishing: Account theft, fake login pages, credential harvesting
- crypto_fraud: Fake investment schemes, crypto doubling, pyramid schemes
- romance_scam: Love/dating scams, fake relationships to extract money
- gambling: Illegal casino promotions, fake lottery wins

Response format (JSON only):
{
  "risk_score": <integer 0-100>,
  "risk_level": <"LOW"|"MEDIUM"|"HIGH"|"CRITICAL">,
  "scam_type": <"job_scam"|"trafficking"|"phishing"|"crypto_fraud"|"romance_scam"|"gambling"|"none">,
  "reasons": [<list of specific reasons why this is suspicious, max 3>],
  "flagged_phrases": [<list of exact phrases from the text that are suspicious, max 5>],
  "is_scam": <true|false>,
  "confidence": <float 0.0-1.0>
}   

Risk score guide:
- 0-25: LOW — likely safe
- 26-50: MEDIUM — some suspicious elements
- 51-75: HIGH — strong scam indicators
- 76-100: CRITICAL — very likely scam/trafficking
"""


@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=2, max=10))
async def analyze_with_deepseek(text: str, url: str = "", page_title: str = "") -> dict:
    """Send text to DeepSeek-R1 via OpenRouter for AI scam analysis."""
    if not settings.openrouter_api_key or settings.openrouter_api_key == "your_openrouter_api_key_here":
        return _fallback_response()

    user_message = f"""Analyze this web page content for scam indicators:

URL: {url or 'unknown'}
Page Title: {page_title or 'unknown'}
Content:
{text[:3000]}

Respond with JSON only."""

    headers = {
        "Authorization": f"Bearer {settings.openrouter_api_key}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://scamshield-lao.app",
        "X-Title": "ScamShield Lao",
    }

    payload = {
        "model": settings.deepseek_model,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_message},
        ],
        "response_format": {"type": "json_object"},
        "temperature": 0.1,
        "max_tokens": 512,
    }

    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(
            f"{settings.openrouter_base_url}/chat/completions",
            headers=headers,
            json=payload,
        )
        response.raise_for_status()
        data = response.json()
        content = data["choices"][0]["message"]["content"]
        return json.loads(content)


def _fallback_response() -> dict:
    """Return a neutral response when API key is not configured."""
    return {
        "risk_score": 0,
        "risk_level": "LOW",
        "scam_type": "none",
        "reasons": ["AI analysis unavailable — configure OPENROUTER_API_KEY"],
        "flagged_phrases": [],
        "is_scam": False,
        "confidence": 0.0,
    }
