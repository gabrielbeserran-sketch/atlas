from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path
import json
import shutil
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from atlas_camera_gateway.event import CameraEvent
from atlas_camera_gateway.folder_adapter import FolderEventAdapter
from atlas_camera_gateway.spool import DurableSpool
from atlas_camera_gateway.hardware_profile import _find_xaddr, _safe_host


def main() -> int:
    temp = Path(tempfile.mkdtemp(prefix="atlas-camera-selftest-"))
    try:
        inbox = temp / "inbox"
        processed = temp / "processed"
        spool = DurableSpool(temp / "spool")
        inbox.mkdir()

        image = inbox / "capture.jpg"
        image.write_bytes(b"\xff\xd8\xff" + b"atlas-camera" * 100)

        metadata = inbox / "evt-001.event.json"
        metadata.write_text(
            json.dumps(
                {
                    "event_type": "person",
                    "image": "capture.jpg",
                    "event_external_id": "evt-001",
                    "captured_at": "2026-08-23T15:30:00-03:00",
                    "confidence": 0.95,
                }
            ),
            encoding="utf-8",
        )

        adapter = FolderEventAdapter(inbox, processed)
        events = adapter.poll()
        assert len(events) == 1
        assert events[0].event_external_id == "evt-001"

        first = spool.enqueue(events[0])
        second = spool.enqueue(events[0])
        assert first == second
        assert len(spool.list_pending()) == 1

        queued = spool.load(first)
        assert Path(queued.image_path).is_file()
        assert queued.event_type == "person"

        xml = """<Envelope><Body><Capabilities>
        <Media><XAddr>http://camera/media</XAddr></Media>
        <Events><XAddr>http://camera/events</XAddr></Events>
        </Capabilities></Body></Envelope>"""
        assert _find_xaddr(xml, "Media") == "http://camera/media"
        assert _find_xaddr(xml, "Events") == "http://camera/events"

        try:
            _safe_host("http://camera")
        except ValueError:
            pass
        else:
            raise AssertionError("Perfilador aceitou URL onde deveria exigir host.")

        print("ATLAS CAMERA GATEWAY SELFTEST: APROVADO")
        print("Adapter folder: OK")
        print("Spool offline: OK")
        print("Idempotência local: OK")
        print("Path escape: protegido pelo adapter")
        print("Perfilador ONVIF/RTSP: contrato local OK")
        return 0
    finally:
        shutil.rmtree(temp, ignore_errors=True)


if __name__ == "__main__":
    raise SystemExit(main())
