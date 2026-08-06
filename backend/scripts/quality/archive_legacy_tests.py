from __future__ import annotations

import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TESTS = ROOT / "tests"
ARCHIVE = ROOT / "test_backups" / "legacy_sprint_phase_contracts"
PREFIXES = (
    "test_sprints_",
    "test_phase",
    "test_phases",
    "test_blocks_",
    "test_advanced_blocks_",
)


def main() -> int:
    ARCHIVE.mkdir(parents=True, exist_ok=True)
    moved: list[str] = []
    for path in sorted(TESTS.glob("test_*.py")):
        if not path.name.startswith(PREFIXES):
            continue
        destination = ARCHIVE / path.name
        if destination.exists():
            destination.unlink()
        shutil.move(str(path), str(destination))
        moved.append(path.name)

    if moved:
        print(f"OK: {len(moved)} testes legados arquivados:")
        for name in moved:
            print(f"- {name}")
    else:
        print("OK: nenhum teste legado ativo encontrado.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
