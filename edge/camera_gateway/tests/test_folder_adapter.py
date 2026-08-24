from pathlib import Path
import json

from atlas_camera_gateway.folder_adapter import FolderEventAdapter


def test_folder_adapter_translates_real_equipment_event(tmp_path: Path) -> None:
    inbox = tmp_path / "inbox"
    processed = tmp_path / "processed"
    inbox.mkdir()

    image = inbox / "snapshot.jpg"
    image.write_bytes(b"\xff\xd8\xff" + b"atlas" * 20)

    metadata = inbox / "evt-001.event.json"
    metadata.write_text(
        json.dumps(
            {
                "event_type": "person",
                "image": "snapshot.jpg",
                "event_external_id": "evt-001",
                "captured_at": "2026-08-23T15:30:00-03:00",
                "confidence": 0.91,
            }
        ),
        encoding="utf-8",
    )

    adapter = FolderEventAdapter(inbox, processed)
    events = adapter.poll()

    assert len(events) == 1
    assert events[0].event_type == "person"
    assert events[0].event_external_id == "evt-001"
    assert not metadata.exists()
    assert (processed / metadata.name).exists()


def test_folder_adapter_blocks_path_escape(tmp_path: Path) -> None:
    inbox = tmp_path / "inbox"
    processed = tmp_path / "processed"
    inbox.mkdir()

    outside = tmp_path / "outside.jpg"
    outside.write_bytes(b"\xff\xd8\xff" + b"atlas" * 20)

    metadata = inbox / "evt-escape.event.json"
    metadata.write_text(
        json.dumps(
            {
                "event_type": "vehicle",
                "image": "../outside.jpg",
                "event_external_id": "evt-escape",
            }
        ),
        encoding="utf-8",
    )

    adapter = FolderEventAdapter(inbox, processed)
    assert adapter.poll() == []
    assert metadata.with_suffix(
        metadata.suffix + ".error.txt"
    ).exists()
