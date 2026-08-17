from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LOCK = ROOT / "ATLAS_MARCO6_DEPENDENCY_LOCK.json"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def promote() -> int:
    pubspec = ROOT / "pubspec.yaml"
    lock = ROOT / "pubspec.lock"
    config = ROOT / ".dart_tool/package_config.json"
    missing = [
        str(path.relative_to(ROOT))
        for path in (pubspec, lock, config)
        if not path.is_file()
    ]
    if missing:
        print("ATLAS MARCO 6 DEPENDENCY LOCK: FAIL")
        return 1

    LOCK.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "pubspec_sha256": sha256(pubspec),
                "pubspec_lock_sha256": sha256(lock),
                "promoted_after_flutter_pub_get": True,
            },
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )
    print("ATLAS MARCO 6 DEPENDENCY LOCK: PROMOTED")
    return 0


def verify() -> int:
    if not LOCK.is_file():
        print("ATLAS MARCO 6 DEPENDENCY LOCK: FAIL")
        return 1

    data = json.loads(LOCK.read_text(encoding="utf-8"))
    errors = []
    for relative, field in (
        ("pubspec.yaml", "pubspec_sha256"),
        ("pubspec.lock", "pubspec_lock_sha256"),
    ):
        path = ROOT / relative
        if not path.is_file():
            errors.append(f"ausente: {relative}")
        elif sha256(path) != data.get(field):
            errors.append(f"alterado: {relative}")

    print(json.dumps({"status":"FAIL" if errors else "OK","errors":errors}, indent=2))
    print("ATLAS MARCO 6 DEPENDENCY LOCK:", "FAIL" if errors else "OK")
    return 1 if errors else 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--promote", action="store_true")
    args = parser.parse_args()
    return promote() if args.promote else verify()


if __name__ == "__main__":
    raise SystemExit(main())
