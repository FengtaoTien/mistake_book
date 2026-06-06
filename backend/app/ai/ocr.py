import base64
import httpx
from app.config import BAIDU_OCR_API_KEY, BAIDU_OCR_SECRET_KEY

TOKEN_URL = "https://aip.baidubce.com/oauth/2.0/token"
OCR_URL = "https://aip.baidubce.com/rest/2.0/ocr/v1/accurate_basic"

_token: str | None = None


async def _get_token() -> str:
    global _token
    if _token:
        return _token
    async with httpx.AsyncClient() as cli:
        r = await cli.post(TOKEN_URL, params={
            "grant_type": "client_credentials",
            "client_id": BAIDU_OCR_API_KEY,
            "client_secret": BAIDU_OCR_SECRET_KEY,
        })
        data = r.json()
        _token = data["access_token"]
        return _token


async def recognize(image_bytes: bytes) -> str:
    token = await _get_token()
    b64 = base64.b64encode(image_bytes).decode()
    async with httpx.AsyncClient() as cli:
        r = await cli.post(OCR_URL, params={"access_token": token}, data={"image": b64})
        result = r.json()
    words = []
    for item in result.get("words_result", []):
        words.append(item.get("words", ""))
    return "\n".join(words)
