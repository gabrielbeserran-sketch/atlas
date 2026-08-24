from __future__ import annotations

from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
import hashlib
import json
import mimetypes
import uuid


ALLOWED_EVENT_TYPES = {"person", "vehicle"}
ALLOWED_CONTENT_TYPES = {
    "image/jpeg",
    "image/png",
    "image/webp",
}


@dataclass(frozen=True)
class CameraEvent:
    event_external_id: str
    event_type: str
    captured_at: str
    image_path: str
    content_type: str
    confidence: float | None = None

    @classmethod
    def create(
        cls,
        *,
        event_type: str,
        image_path: Path,
        confidence: float | None = None,
        captured_at: datetime | None = None,
        event_external_id: str | None = None,
    ) -> "CameraEvent":
        normalized_type = event_type.strip().lower()
        if normalized_type not in ALLOWED_EVENT_TYPES:
            raise ValueError("event_type deve ser person ou vehicle.")

        image = image_path.expanduser().resolve()
        if not image.is_file():
            raise FileNotFoundError(f"Imagem não encontrada: {image}")

        content_type = mimetypes.guess_type(image.name)[0] or ""
        if content_type not in ALLOWED_CONTENT_TYPES:
            raise ValueError("A imagem deve ser JPEG, PNG ou WebP.")

        if confidence is not None and not 0 <= confidence <= 1:
            raise ValueError("confidence deve estar entre 0 e 1.")

        instant = captured_at or datetime.now(timezone.utc)
        if instant.tzinfo is None:
            instant = instant.replace(tzinfo=timezone.utc)
        instant = instant.astimezone(timezone.utc)

        external_id = (event_external_id or "").strip()
        if not external_id:
            digest = hashlib.sha256()
            digest.update(normalized_type.encode("utf-8"))
            digest.update(instant.isoformat().encode("utf-8"))
            digest.update(image.read_bytes())
            external_id = (
                f"edge-{instant.strftime('%Y%m%dT%H%M%S')}-"
                f"{digest.hexdigest()[:20]}"
            )

        return cls(
            event_external_id=external_id[:180],
            event_type=normalized_type,
            captured_at=instant.isoformat(),
            image_path=str(image),
            content_type=content_type,
            confidence=confidence,
        )

    def to_json(self) -> str:
        return json.dumps(asdict(self), ensure_ascii=False, indent=2)

    @classmethod
    def from_json(cls, value: str) -> "CameraEvent":
        payload = json.loads(value)
        return cls(**payload)
