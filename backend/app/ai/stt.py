from openai import AsyncOpenAI
from app.config import UPLOAD_DIR, LLM_BASE_URL, LLM_API_KEY


async def transcribe(file_path: str) -> str:
    client = AsyncOpenAI(api_key=LLM_API_KEY, base_url=LLM_BASE_URL)
    with open(file_path, "rb") as f:
        r = await client.audio.transcriptions.create(
            model="whisper-1",
            file=f,
            language="zh",
        )
    return r.text
