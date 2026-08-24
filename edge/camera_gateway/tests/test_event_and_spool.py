from datetime import datetime, timezone
from pathlib import Path

from atlas_camera_gateway.event import CameraEvent
from atlas_camera_gateway.spool import DurableSpool


def test_event_is_deterministic_with_explicit_id(tmp_path: Path) -> None:
    image = tmp_path / "entrada.jpg"
    image.write_bytes(b"\xff\xd8\xff" + b"atlas" * 20)

    event = CameraEvent.create(
        event_type="person",
        image_path=image,
        event_external_id="camera-event-001",
        captured_at=datetime(2026, 8, 23, 12, 0, tzinfo=timezone.utc),
    )

    assert event.event_external_id == "camera-event-001"
    assert event.event_type == "person"
    assert event.content_type == "image/jpeg"


def test_spool_is_idempotent(tmp_path: Path) -> None:
    image = tmp_path / "entrada.png"
    image.write_bytes(b"\x89PNG\r\n\x1a\n" + b"atlas" * 20)
    spool = DurableSpool(tmp_path / "spool")

    event = CameraEvent.create(
        event_type="vehicle",
        image_path=image,
        event_external_id="same-event",
    )

    first = spool.enqueue(event)
    second = spool.enqueue(event)

    assert first == second
    assert len(spool.list_pending()) == 1


def test_spool_copies_image_before_delivery(tmp_path: Path) -> None:
    image = tmp_path / "entrada.webp"
    image.write_bytes(b"RIFFxxxxWEBP" + b"atlas" * 20)
    spool = DurableSpool(tmp_path / "spool")

    event = CameraEvent.create(
        event_type="person",
        image_path=image,
        event_external_id="offline-event",
    )
    item = spool.enqueue(event)
    image.unlink()

    queued = spool.load(item)
    assert Path(queued.image_path).is_file()
