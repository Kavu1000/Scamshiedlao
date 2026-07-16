from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class ScanRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=10000)
    url: str = Field(default="")
    page_title: str = Field(default="")
    session_id: Optional[str] = None


class ScanResult(BaseModel):
    risk_score: int
    risk_level: str  # LOW | MEDIUM | HIGH | CRITICAL
    scam_type: str
    reasons: list[str]
    flagged_phrases: list[str]
    is_scam: bool
    confidence: float
    heuristic_score: int
    ai_analyzed: bool
    url: str
    page_title: str
    from_cache: bool


class ScamReport(BaseModel):
    url: str
    page_title: str = ""
    description: str = Field(..., min_length=5, max_length=2000)
    scam_type: str = "unknown"
    reporter_session: Optional[str] = None


class ScamReportResponse(BaseModel):
    id: str
    message: str
    created_at: datetime
