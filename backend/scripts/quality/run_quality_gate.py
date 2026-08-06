from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def run(label: str, command: list[str]) -> None:
    print(f"\n=== {label} ===")
    result = subprocess.run(command, cwd=ROOT, env=os.environ.copy(), check=False)
    if result.returncode:
        raise SystemExit(result.returncode)


def main() -> int:
    os.environ.setdefault("ATLAS_ENV", "test")
    os.environ.setdefault("ATLAS_DATABASE_URL", "sqlite:///./atlas_quality.db")
    os.environ.setdefault("ATLAS_JWT_SECRET", "quality-gate-secret-with-at-least-32-characters")
    run("Compilação Python", [sys.executable, "-m", "compileall", "-q", "app", "tests", "scripts"])
    run("Arquitetura", [sys.executable, "scripts/quality/check_architecture.py"])
    run("Migrations", [sys.executable, "scripts/quality/check_migrations.py"])
    run("Rotas", [sys.executable, "scripts/quality/check_route_declarations.py"])
    run("OpenAPI", [sys.executable, "scripts/quality/check_openapi.py"])
    run("Pytest", [sys.executable, "-m", "pytest", "-q"])
    print("\nGate de qualidade aprovado.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
