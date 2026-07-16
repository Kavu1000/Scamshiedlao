from fastapi import APIRouter
from backend.services.db import get_db

router = APIRouter()


@router.get("/stats")
async def get_stats():
    """Return aggregate scam detection statistics."""
    db = get_db()

    total_scans = await db.scan_sessions.count_documents({})
    total_scams = await db.scan_sessions.count_documents({"is_scam": True})
    total_reports = await db.scam_reports.count_documents({})

    # Breakdown by risk level
    pipeline = [
        {"$group": {"_id": "$risk_level", "count": {"$sum": 1}}},
    ]
    risk_breakdown_raw = await db.scan_sessions.aggregate(pipeline).to_list(10)
    risk_breakdown = {item["_id"]: item["count"] for item in risk_breakdown_raw}

    # Breakdown by scam type
    type_pipeline = [
        {"$match": {"is_scam": True}},
        {"$group": {"_id": "$scam_type", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}},
        {"$limit": 6},
    ]
    type_breakdown_raw = await db.scan_sessions.aggregate(type_pipeline).to_list(6)
    type_breakdown = {item["_id"]: item["count"] for item in type_breakdown_raw}

    return {
        "total_scans": total_scans,
        "total_scams_detected": total_scams,
        "total_user_reports": total_reports,
        "scam_rate": round((total_scams / total_scans * 100) if total_scans > 0 else 0, 1),
        "risk_breakdown": risk_breakdown,
        "scam_type_breakdown": type_breakdown,
    }
