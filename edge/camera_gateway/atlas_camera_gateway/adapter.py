from __future__ import annotations

from pathlib import Path
from typing import Protocol

from .event import CameraEvent


class CameraEventAdapter(Protocol):
    """Contrato mínimo para qualquer câmera/NVR ligado ao Atlas."""

    def poll(self) -> list[CameraEvent]:
        """Retorna somente eventos reais produzidos pelo equipamento."""
        ...


class AdapterError(RuntimeError):
    pass


def safe_event_file(path: Path, root: Path) -> Path:
    resolved_root = root.expanduser().resolve()
    resolved = path.expanduser()
    if not resolved.is_absolute():
        resolved = resolved_root / resolved
    resolved = resolved.resolve()

    try:
        resolved.relative_to(resolved_root)
    except ValueError as exc:
        raise AdapterError(
            "O arquivo indicado pelo adaptador está fora da pasta autorizada."
        ) from exc

    return resolved
