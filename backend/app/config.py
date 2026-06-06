from pathlib import Path
from dotenv import load_dotenv
import os

load_dotenv()

DATABASE_URL: str = os.getenv("DATABASE_URL", "postgresql+asyncpg://postgres:postgres@localhost:5432/mistakebook")
UPLOAD_DIR: Path = Path(os.getenv("UPLOAD_DIR", "./uploads"))
SECRET_KEY: str = os.getenv("SECRET_KEY", "dev-secret-key")
LLM_API_KEY: str = os.getenv("LLM_API_KEY", "")
LLM_BASE_URL: str = os.getenv("LLM_BASE_URL", "https://api.deepseek.com")
LLM_MODEL: str = os.getenv("LLM_MODEL", "deepseek-chat")
BAIDU_OCR_API_KEY: str = os.getenv("BAIDU_OCR_API_KEY", "")
BAIDU_OCR_SECRET_KEY: str = os.getenv("BAIDU_OCR_SECRET_KEY", "")

UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
