# pyrefly: ignore [missing-import]
from fastapi import APIRouter
from backend.models.scan_result import ScanRequest, ScanResult
from backend.services.scam_detector import analyze_content

router = APIRouter()


@router.post("/scan", response_model=ScanResult)
async def scan_content(request: ScanRequest):
    """Analyze page content for scam indicators using heuristics + DeepSeek-R1 AI."""
    result = await analyze_content(
        text=request.text,
        url=request.url,
        page_title=request.page_title,
        session_id=request.session_id,
    )
    return result
