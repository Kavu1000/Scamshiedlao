# pyrefly: ignore [missing-import]
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from backend.config import get_settings

settings = get_settings()

_client: AsyncIOMotorClient = None
_db: AsyncIOMotorDatabase = None


async def connect_db():
    global _client, _db
    _client = AsyncIOMotorClient(
        settings.mongodb_url,
        tlsAllowInvalidCertificates=True,
    )
    _db = _client[settings.mongodb_db_name]
    # Create indexes
    await _db.scam_reports.create_index("created_at")
    await _db.scam_reports.create_index("url")
    await _db.scan_sessions.create_index("session_id")
    await _db.scan_sessions.create_index("created_at")
    await _db.scan_cache.create_index("content_hash", unique=True)
    await _db.scan_cache.create_index("created_at", expireAfterSeconds=86400)  # 24h TTL
    print("✅ Connected to MongoDB:", settings.mongodb_db_name)





async def close_db():
    global _client
    if _client:
        _client.close()
        print("🔌 MongoDB connection closed")


def get_db() -> AsyncIOMotorDatabase:
    return _db
