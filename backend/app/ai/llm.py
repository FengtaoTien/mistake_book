from openai import AsyncOpenAI
from app.config import LLM_API_KEY, LLM_BASE_URL, LLM_MODEL

_client: AsyncOpenAI | None = None


def get_client() -> AsyncOpenAI:
    global _client
    if _client is None:
        _client = AsyncOpenAI(api_key=LLM_API_KEY, base_url=LLM_BASE_URL)
    return _client


async def chat(messages: list[dict], **kwargs) -> str:
    client = get_client()
    r = await client.chat.completions.create(
        model=kwargs.get("model", LLM_MODEL),
        messages=messages,
        temperature=kwargs.get("temperature", 0.3),
        max_tokens=kwargs.get("max_tokens", 2000),
    )
    return r.choices[0].message.content or ""


async def chat_json(messages: list[dict], **kwargs) -> dict:
    client = get_client()
    r = await client.chat.completions.create(
        model=kwargs.get("model", LLM_MODEL),
        messages=messages,
        response_format={"type": "json_object"},
        temperature=kwargs.get("temperature", 0.3),
        max_tokens=kwargs.get("max_tokens", 2000),
    )
    content = r.choices[0].message.content or "{}"
    import json
    return json.loads(content)
