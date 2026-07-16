from fastapi import APIRouter, Query
from backend.services.db import get_db

router = APIRouter()


@router.get("/history")
async def get_history(
    session_id: str = Query(..., description="Browser session ID"),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
):
    """Get paginated scan history for a session."""
    db = get_db()
    skip = (page - 1) * limit
    cursor = db.scan_sessions.find(
        {"session_id": session_id},
        {"_id": 0},
    ).sort("created_at", -1).skip(skip).limit(limit)

    items = await cursor.to_list(length=limit)
    total = await db.scan_sessions.count_documents({"session_id": session_id})

    # Serialize datetime
    for item in items:
        if "created_at" in item:
            item["created_at"] = item["created_at"].isoformat()

    return {"items": items, "total": total, "page": page, "limit": limit}
