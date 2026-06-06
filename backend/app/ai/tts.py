import edge_tts
from app.config import UPLOAD_DIR

VOICE = "zh-CN-XiaoxiaoNeural"


async def synthesize(text: str, filename: str = "tts.mp3") -> str:
    save_path = UPLOAD_DIR / filename
    communicate = edge_tts.Communicate(text, VOICE)
    await communicate.save(str(save_path))
    return f"/uploads/{filename}"
