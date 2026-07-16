# pyrefly: ignore [missing-import]
from pydantic_settings import BaseSettings
from functools import lru_cache
from pathlib import Path

# Always resolve .env relative to this file (backend/.env), regardless of CWD
ENV_FILE = Path(__file__).parent / ".env"


class Settings(BaseSettings):
    mongodb_url: str = "mongodb://localhost:27017"
    mongodb_db_name: str = "scamshield_lao"
    openrouter_api_key: str = ""
    openrouter_base_url: str = "https://openrouter.ai/api/v1"
    deepseek_model: str = "deepseek/deepseek-r1"
    allowed_origins: str = "chrome-extension://,http://localhost:3000,http://localhost:3001"
    port: int = 8000

    class Config:
        env_file = str(ENV_FILE)

    @property
    def ai_models(self) -> list[str]:
        """DEEPSEEK_MODEL as a comma-separated fallback chain, e.g. 'model-a,model-b'."""
        return [m.strip() for m in self.deepseek_model.split(",") if m.strip()]


@lru_cache()
def get_settings() -> Settings:
    return Settings()
