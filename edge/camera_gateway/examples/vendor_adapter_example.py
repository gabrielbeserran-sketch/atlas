"""Exemplo de integração de um driver/NVR com o gateway Atlas.

O adaptador real deve detectar o evento no equipamento e chamar `emit_event`.
Este arquivo NÃO detecta pessoas/veículos por conta própria.
"""
from pathlib import Path
import subprocess


def emit_event(
    *,
    event_type: str,
    snapshot_path: str,
    event_id: str,
) -> None:
    subprocess.run(
        [
            "atlas-camera-gateway",
            "emit",
            "--type",
            event_type,
            "--image",
            str(Path(snapshot_path)),
            "--event-id",
            event_id,
        ],
        check=True,
    )
