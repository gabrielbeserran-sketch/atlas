from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import json

import httpx

from .config import GatewayConfig
from .event import CameraEvent


@dataclass(frozen=True)
class DeliveryResult:
    accepted: bool
    event_id: str
    alert_status: str
    raw: dict


class AtlasCameraTransport:
    def __init__(self, config: GatewayConfig) -> None:
        self.config = config

    def deliver(self, event: CameraEvent) -> DeliveryResult:
        image = Path(event.image_path)
        size = image.stat().st_size
        if size <= 0:
            raise ValueError("A captura está vazia.")
        if size > self.config.max_image_bytes:
            raise ValueError(
                f"Captura excede {self.config.max_image_bytes} bytes."
            )

        data = {
            "device_external_id": self.config.device_external_id,
            "event_external_id": event.event_external_id,
            "event_type": event.event_type,
            "captured_at": event.captured_at,
        }
        if event.confidence is not None:
            data["confidence"] = str(event.confidence)

        headers = {
            "X-Atlas-Iot-Key": self.config.iot_ingest_key,
            "Accept": "application/json",
        }

        timeout = httpx.Timeout(
            self.config.request_timeout_seconds,
            connect=self.config.connect_timeout_seconds,
        )

        with image.open("rb") as handle:
            with httpx.Client(timeout=timeout) as client:
                response = client.post(
                    f"{self.config.atlas_base_url}/security-camera/events/ingest",
                    headers=headers,
                    data=data,
                    files={
                        "image": (
                            image.name,
                            handle,
                            event.content_type,
                        )
                    },
                )

        if response.status_code not in {200, 201}:
            detail = response.text[:1000]
            raise RuntimeError(
                f"Atlas recusou evento (HTTP {response.status_code}): {detail}"
            )

        try:
            payload = response.json()
        except json.JSONDecodeError as exc:
            raise RuntimeError("Atlas retornou JSON inválido.") from exc

        event_id = str(payload.get("id") or "").strip()
        alert_status = str(payload.get("alert_status") or "").strip()
        if not event_id:
            raise RuntimeError("Atlas não confirmou o ID do evento.")

        return DeliveryResult(
            accepted=True,
            event_id=event_id,
            alert_status=alert_status,
            raw=payload,
        )
