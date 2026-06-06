import uuid
from fastapi import APIRouter, UploadFile, File, HTTPException
from app.config import UPLOAD_DIR
from app.ai.ocr import recognize

router = APIRouter(prefix="/ocr", tags=["ocr"])


@router.post("/recognize")
async def ocr_recognize(file: UploadFile = File(...)):
    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Empty file")

    ext = file.filename.rsplit(".", 1)[-1] if file.filename else "jpg"
    filename = f"{uuid.uuid4().hex}.{ext}"
    save_path = UPLOAD_DIR / filename
    save_path.write_bytes(image_bytes)

    text = await recognize(image_bytes)
    return {"text": text, "image_url": f"/uploads/{filename}"}
