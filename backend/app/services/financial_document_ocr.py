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


_SCHEMA = {
    "type": "object",
    "additionalProperties": False,
    "required": [
        "supplier",
        "document_number",
        "document_date",
        "total_amount",
        "type",
        "category",
        "confidence",
        "warnings",
    ],
    "properties": {
        "supplier": {"type": "string"},
        "document_number": {"type": "string"},
        "document_date": {"type": "string"},
        "total_amount": {"type": "string"},
        "type": {"type": "string", "enum": ["", "Receita", "Despesa"]},
        "category": {"type": "string"},
        "confidence": {"type": "integer", "minimum": 0, "maximum": 100},
        "warnings": {"type": "array", "items": {"type": "string"}, "maxItems": 8},
    },
}


def _normalize(result: dict) -> dict:
    """Preserva somente dados previstos pelo contrato de sugestão."""
    warnings = result.get("warnings", [])
    if not isinstance(warnings, list):
        warnings = [warnings]
    confidence = result.get("confidence", 0)
    try:
        confidence = max(0, min(100, int(confidence)))
    except (TypeError, ValueError):
        confidence = 0
    return {
        "supplier": str(result.get("supplier") or "").strip()[:255],
        "document_number": str(result.get("document_number") or "").strip()[:120],
        "document_date": str(result.get("document_date") or "").strip()[:32],
        "total_amount": str(result.get("total_amount") or "").strip()[:64],
        "type": result.get("type") if result.get("type") in {"Receita", "Despesa"} else "",
        "category": str(result.get("category") or "").strip()[:120],
        "confidence": confidence,
        "warnings": [str(item).strip()[:300] for item in warnings if str(item).strip()][:8],
    }


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
        "text": {
            "format": {
                "type": "json_schema",
                "name": "financial_document_preview",
                "strict": True,
                "schema": _SCHEMA,
            },
        },
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
        # OCR é uma conveniência: se o provedor estiver lento, o lançamento
        # manual continua disponível em vez de prender a operação financeira.
        async with httpx.AsyncClient(timeout=25.0) as client:
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
        return _normalize(result)
    except (httpx.HTTPError, ValueError, json.JSONDecodeError) as exc:
        raise OcrFailed("Não foi possível ler a nota agora.") from exc
