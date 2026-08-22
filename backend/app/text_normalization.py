from __future__ import annotations

import re
from collections.abc import Mapping, Sequence
from typing import Any

_MOJIBAKE_MARKERS = re.compile(r"(Ã.|Â.|â.|ð.|�)")
_COMMON_REPLACEMENTS = {
    "â€“": "–",
    "â€”": "—",
    "â€™": "’",
    "â€œ": "“",
    "â€": "”",
    "Â·": "·",
    "Âº": "º",
    "Âª": "ª",
    "Â ": " ",
}


def repair_mojibake_text(value: str) -> str:
    """Repara mojibake UTF-8↔Latin-1 sem tocar em texto normal.

    A função só tenta conversão quando encontra marcadores típicos de bytes
    UTF-8 interpretados como Latin-1/Windows-1252. São permitidas duas passagens
    para cobrir valores que foram codificados incorretamente mais de uma vez.
    """
    if not value or _MOJIBAKE_MARKERS.search(value) is None:
        return value

    current = value
    for broken, correct in _COMMON_REPLACEMENTS.items():
        current = current.replace(broken, correct)

    for _ in range(2):
        if _MOJIBAKE_MARKERS.search(current) is None:
            break
        candidate = None
        for source_encoding in ("latin-1", "cp1252"):
            try:
                candidate = current.encode(source_encoding).decode("utf-8")
                break
            except (UnicodeEncodeError, UnicodeDecodeError):
                continue
        if candidate is None:
            break
        if len(_MOJIBAKE_MARKERS.findall(candidate)) >= len(
            _MOJIBAKE_MARKERS.findall(current)
        ):
            break
        current = candidate
    return current


def normalize_text_payload(value: Any) -> Any:
    """Normaliza strings recursivamente, inclusive estruturas JSON."""
    if isinstance(value, str):
        return repair_mojibake_text(value)
    if isinstance(value, Mapping):
        return {key: normalize_text_payload(item) for key, item in value.items()}
    if isinstance(value, list):
        return [normalize_text_payload(item) for item in value]
    if isinstance(value, tuple):
        return tuple(normalize_text_payload(item) for item in value)
    return value
