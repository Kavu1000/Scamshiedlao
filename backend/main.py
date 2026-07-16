from contextlib import asynccontextmanager
# pyrefly: ignore [missing-import]
from fastapi import FastAPI
# pyrefly: ignore [missing-import]
from fastapi.middleware.cors import CORSMiddleware
from backend.config import get_settings
from backend.services.db import connect_db, close_db
from backend.routes import scan, report, history, stats

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_db()
    yield
    await close_db()


app = FastAPI(
    title="ScamShield Lao API",
    description="Real-time scam detection API for Lao users — powered by DeepSeek-R1 via OpenRouter",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS — allow Chrome extension + local dev
origins = [o.strip() for o in settings.allowed_origins.split(",")]
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Chrome extensions need wildcard
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routes
app.include_router(scan.router, prefix="/api", tags=["Scan"])
app.include_router(report.router, prefix="/api", tags=["Report"])
app.include_router(history.router, prefix="/api", tags=["History"])
app.include_router(stats.router, prefix="/api", tags=["Stats"])


@app.get("/api/health")
async def health():
    return {"status": "ok", "service": "ScamShield Lao API", "version": "1.0.0"}
