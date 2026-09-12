"""Sugestões OCR financeiras, sempre sujeitas a revisão humana."""
from __future__ import annotations

import base64
import json

import httpx

from app.config import get_settings


class OcrUnavailable(RuntimeError):
    pass


class OcrFailed(RuntimeError):
    pass


async def suggest(content: bytes, content_type: str) -> dict:
    settings = get_settings()
    if not settings.atlas_financial_ocr_enabled or not settings.openai_api_key:
        raise OcrUnavailable("OCR financeiro não está configurado no servidor.")
    if not content_type.startswith("image/"):
        raise OcrFailed("Envie uma imagem da nota.")
    prompt = (
        "Leia a nota fiscal e responda SOMENTE um objeto JSON com as chaves "
        "supplier, document_number, document_date, total_amount, type, category, "
        "confidence e warnings. type deve ser Receita ou Despesa quando isso estiver "
        "claro. Não invente dados: use string vazia ou null quando não estiver legível. "
        "Isto é somente uma sugestão para revisão humana."
    )
    image_data = base64.b64encode(content).decode("ascii")
    body = {
        "model": settings.atlas_financial_ocr_model,
        "store": False,
        "input": [
            {
                "role": "user",
                "content": [
                    {"type": "input_text", "text": prompt},
                    {
                        "type": "input_image",
                        "image_url": f"data:{content_type};base64,{image_data}",
                        "detail": "high",
                    },
                ],
            },
        ],
    }
    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                "https://api.openai.com/v1/responses",
                headers={"Authorization": f"Bearer {settings.openai_api_key}"},
                json=body,
            )
        response.raise_for_status()
        text = next(
            (
                str(part.get("text", ""))
                for item in response.json().get("output", [])
                for part in item.get("content", [])
                if part.get("type") == "output_text"
            ),
            "",
        )
        result = json.loads(text)
        if not isinstance(result, dict):
            raise ValueError("Resposta OCR inválida")
        return result
    except (httpx.HTTPError, ValueError, json.JSONDecodeError) as exc:
        raise OcrFailed("Não foi possível ler a nota agora.") from exc
