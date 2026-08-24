from __future__ import annotations

from dataclasses import dataclass
import os
from pathlib import Path
from urllib.parse import urlparse


@dataclass(frozen=True)
class GatewayConfig:
    atlas_base_url: str
    device_external_id: str
    iot_ingest_key: str
    spool_dir: Path
    connect_timeout_seconds: float = 15.0
    request_timeout_seconds: float = 90.0
    max_image_bytes: int = 12 * 1024 * 1024
    retry_base_seconds: int = 10
    retry_max_seconds: int = 300

    @classmethod
    def from_env(cls) -> "GatewayConfig":
        base_url = os.getenv(
            "ATLAS_CAMERA_GATEWAY_BASE_URL",
            "https://atlas-api-29y2.onrender.com/api/v1",
        ).strip().rstrip("/")
        device_external_id = os.getenv(
            "ATLAS_CAMERA_DEVICE_EXTERNAL_ID",
            "",
        ).strip()
        ingest_key = os.getenv(
            "ATLAS_IOT_INGEST_KEY",
            "",
        ).strip()
        spool_dir = Path(
            os.getenv(
                "ATLAS_CAMERA_GATEWAY_SPOOL_DIR",
                "./spool",
            )
        ).expanduser()

        parsed = urlparse(base_url)
        if parsed.scheme not in {"http", "https"} or not parsed.netloc:
            raise ValueError(
                "ATLAS_CAMERA_GATEWAY_BASE_URL deve ser uma URL HTTP/HTTPS absoluta."
            )
        if len(device_external_id) < 3:
            raise ValueError(
                "ATLAS_CAMERA_DEVICE_EXTERNAL_ID deve identificar a câmera "
                "cadastrada no Atlas."
            )
        if len(ingest_key) < 32:
            raise ValueError(
                "ATLAS_IOT_INGEST_KEY não foi configurada no gateway."
            )

        return cls(
            atlas_base_url=base_url,
            device_external_id=device_external_id,
            iot_ingest_key=ingest_key,
            spool_dir=spool_dir,
        )
