# pyrefly: ignore [missing-import]
from fastapi import APIRouter
from datetime import datetime, timezone
from bson import ObjectId
from backend.models.scan_result import ScamReport, ScamReportResponse
from backend.services.db import get_db

router = APIRouter()


@router.post("/report", response_model=ScamReportResponse)
async def submit_report(report: ScamReport):
    """Submit a user-reported scam URL/post."""
    db = get_db()
    doc = {
        **report.model_dump(),
        "created_at": datetime.now(timezone.utc),
        "status": "pending_review",
        "votes": 1,
    }
    result = await db.scam_reports.insert_one(doc)
    return ScamReportResponse(
        id=str(result.inserted_id),
        message="Report submitted successfully. Thank you for helping keep Lao users safe!",
        created_at=doc["created_at"],
    )
