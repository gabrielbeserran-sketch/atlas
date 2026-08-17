from __future__ import annotations

import argparse
import importlib
import sys

MIN_VERSION = (3, 11)

CRITICAL_IMPORTS = (
    "alembic",
    "fastapi",
    "httpx",
    "jose",
    "psycopg",
    "pytest",
    "sqlalchemy",
    "uvicorn",
)


def validate_version() -> None:
    if sys.version_info < MIN_VERSION:
        raise SystemExit(
            "Python não suportado: "
            f"{sys.version_info.major}.{sys.version_info.minor}. "
            "O Atlas exige Python 3.11 ou superior."
        )


def validate_imports() -> None:
    failures: list[str] = []
    for module_name in CRITICAL_IMPORTS:
        try:
            importlib.import_module(module_name)
        except Exception as exc:
            failures.append(f"{module_name}: {type(exc).__name__}: {exc}")

    if failures:
        print("ATLAS PYTHON DEPENDENCIES: FAIL")
        for failure in failures:
            print(f" - {failure}")
        raise SystemExit(1)

    print("ATLAS PYTHON DEPENDENCIES: OK")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--version-only",
        action="store_true",
        help="Valida apenas a versão do Python.",
    )
    args = parser.parse_args()

    validate_version()
    print(
        "ATLAS PYTHON VERSION: OK "
        f"{sys.version_info.major}.{sys.version_info.minor}."
        f"{sys.version_info.micro}"
    )

    if not args.version_only:
        validate_imports()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
