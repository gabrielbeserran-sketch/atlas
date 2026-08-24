from __future__ import annotations

from pathlib import Path
import os
import shutil
import tempfile

from .event import CameraEvent


class DurableSpool:
    def __init__(self, root: Path) -> None:
        self.root = root.expanduser().resolve()
        self.pending = self.root / "pending"
        self.sent = self.root / "sent"
        self.failed = self.root / "failed"
        for folder in (self.pending, self.sent, self.failed):
            folder.mkdir(parents=True, exist_ok=True)

    def enqueue(self, event: CameraEvent) -> Path:
        image_source = Path(event.image_path)
        item_dir = self.pending / event.event_external_id
        if item_dir.exists():
            return item_dir

        temp_dir = Path(
            tempfile.mkdtemp(
                prefix=f".{event.event_external_id}-",
                dir=self.pending,
            )
        )
        try:
            image_name = f"snapshot{image_source.suffix.lower()}"
            shutil.copy2(image_source, temp_dir / image_name)

            queued = CameraEvent(
                event_external_id=event.event_external_id,
                event_type=event.event_type,
                captured_at=event.captured_at,
                image_path=image_name,
                content_type=event.content_type,
                confidence=event.confidence,
            )
            (temp_dir / "event.json").write_text(
                queued.to_json(),
                encoding="utf-8",
            )
            os.replace(temp_dir, item_dir)
        except Exception:
            shutil.rmtree(temp_dir, ignore_errors=True)
            raise

        return item_dir

    def list_pending(self) -> list[Path]:
        return sorted(
            (
                item
                for item in self.pending.iterdir()
                if item.is_dir() and (item / "event.json").is_file()
            ),
            key=lambda item: item.stat().st_mtime,
        )

    def load(self, item_dir: Path) -> CameraEvent:
        event = CameraEvent.from_json(
            (item_dir / "event.json").read_text(encoding="utf-8")
        )
        return CameraEvent(
            event_external_id=event.event_external_id,
            event_type=event.event_type,
            captured_at=event.captured_at,
            image_path=str(item_dir / event.image_path),
            content_type=event.content_type,
            confidence=event.confidence,
        )

    def mark_sent(self, item_dir: Path) -> None:
        destination = self.sent / item_dir.name
        if destination.exists():
            shutil.rmtree(destination)
        os.replace(item_dir, destination)

    def mark_failed(self, item_dir: Path, message: str) -> None:
        (item_dir / "last_error.txt").write_text(
            message[:4000],
            encoding="utf-8",
        )
