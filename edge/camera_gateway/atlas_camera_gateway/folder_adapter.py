from __future__ import annotations

from datetime import datetime
import json
from pathlib import Path
import shutil

from .adapter import AdapterError, safe_event_file
from .event import CameraEvent


class FolderEventAdapter:
    """Adapter vendor-neutral para NVR/câmera que consegue gravar eventos.

    Cada evento é um JSON `<id>.event.json` dentro da inbox:

    {
      "event_type": "person",
      "image": "snapshot-001.jpg",
      "event_external_id": "camera-evt-001",
      "captured_at": "2026-08-23T15:30:00-03:00",
      "confidence": 0.92
    }

    A imagem deve estar dentro da mesma árvore da inbox. O adapter não executa
    visão computacional; apenas traduz um evento já detectado pelo equipamento.
    """

    def __init__(self, inbox: Path, processed: Path) -> None:
        self.inbox = inbox.expanduser().resolve()
        self.processed = processed.expanduser().resolve()
        self.inbox.mkdir(parents=True, exist_ok=True)
        self.processed.mkdir(parents=True, exist_ok=True)

    def poll(self) -> list[CameraEvent]:
        events: list[CameraEvent] = []

        for metadata_path in sorted(self.inbox.glob("*.event.json")):
            try:
                payload = json.loads(
                    metadata_path.read_text(encoding="utf-8")
                )
                image_value = str(payload.get("image") or "").strip()
                if not image_value:
                    raise AdapterError("Evento não informou a imagem.")

                image = safe_event_file(
                    Path(image_value),
                    self.inbox,
                )
                captured_raw = str(
                    payload.get("captured_at") or ""
                ).strip()
                captured_at = (
                    datetime.fromisoformat(captured_raw)
                    if captured_raw
                    else None
                )
                confidence_raw = payload.get("confidence")
                confidence = (
                    float(confidence_raw)
                    if confidence_raw is not None
                    else None
                )

                event = CameraEvent.create(
                    event_type=str(payload.get("event_type") or ""),
                    image_path=image,
                    confidence=confidence,
                    captured_at=captured_at,
                    event_external_id=str(
                        payload.get("event_external_id") or ""
                    ),
                )
            except (
                AdapterError,
                ValueError,
                TypeError,
                FileNotFoundError,
                json.JSONDecodeError,
            ) as exc:
                error_path = metadata_path.with_suffix(
                    metadata_path.suffix + ".error.txt"
                )
                error_path.write_text(str(exc), encoding="utf-8")
                continue

            events.append(event)
            destination = self.processed / metadata_path.name
            if destination.exists():
                destination.unlink()
            shutil.move(str(metadata_path), str(destination))

        return events
