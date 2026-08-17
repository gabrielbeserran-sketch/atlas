from __future__ import annotations

import ast
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
LIB = ROOT / "lib"
TEST = ROOT / "test"
BACKEND = ROOT / "backend"


def parse_pubspec_packages(text: str) -> set[str]:
    packages: set[str] = {"flutter"}

    for section_name in ("dependencies", "dev_dependencies"):
        match = re.search(
            rf"(?ms)^{section_name}:\s*\n(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
            text,
        )
        if not match:
            continue
        for package in re.findall(
            r"(?m)^  ([A-Za-z0-9_]+):",
            match.group(1),
        ):
            packages.add(package)

    return packages


def dart_package_imports() -> dict[str, list[str]]:
    result: dict[str, list[str]] = {}
    for base in (LIB, TEST):
        if not base.exists():
            continue
        for path in base.rglob("*.dart"):
            source = path.read_text(encoding="utf-8", errors="ignore")
            for package in re.findall(
                r"""package:([A-Za-z0-9_]+)/""",
                source,
            ):
                if package == "projeto_atlas":
                    continue
                result.setdefault(package, []).append(
                    str(path.relative_to(ROOT))
                )
    return result


def python_syntax_errors() -> list[str]:
    errors: list[str] = []
    roots = (
        BACKEND / "app",
        BACKEND / "scripts",
        ROOT / "scripts" / "quality",
    )
    for base in roots:
        if not base.exists():
            continue
        for path in base.rglob("*.py"):
            try:
                ast.parse(
                    path.read_text(
                        encoding="utf-8",
                        errors="ignore",
                    ),
                    filename=str(path),
                )
            except SyntaxError as exc:
                errors.append(
                    f"{path.relative_to(ROOT)}:{exc.lineno}: {exc.msg}"
                )
    return errors


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []

    required_files = (
        "pubspec.yaml",
        "pubspec.lock",
        "backend/requirements.txt",
        "backend/requirements-dev.txt",
        "backend/scripts/check_python_environment.py",
        "backend/scripts/check_local_database_connection.py",
        "backend/scripts/reconcile_local_alembic.py",
        "scripts/dev/ensure_backend_venv.ps1",
        "scripts/dev/bootstrap_project.ps1",
        "scripts/dev/start_backend.ps1",
        "scripts/dev/start_local_infrastructure.ps1",
        "scripts/quality/run_full_quality_gate.ps1",
        "scripts/quality/atlas_full_project_audit.py",
        "scripts/quality/atlas_powershell_static_audit.py",
    )
    for relative in required_files:
        if not (ROOT / relative).is_file():
            errors.append(f"arquivo obrigatório ausente: {relative}")

    pubspec_path = ROOT / "pubspec.yaml"
    pubspec_text = pubspec_path.read_text(encoding="utf-8")
    declared_packages = parse_pubspec_packages(pubspec_text)
    imported_packages = dart_package_imports()

    missing_packages = sorted(
        package
        for package in imported_packages
        if package not in declared_packages
    )
    for package in missing_packages:
        sample = ", ".join(imported_packages[package][:3])
        errors.append(
            f"pacote Dart importado e não declarado: {package} ({sample})"
        )

    for asset in re.findall(
        r"(?m)^\s+- asset:\s*(\S+)\s*$",
        pubspec_text,
    ):
        if not (ROOT / asset).is_file():
            errors.append(f"asset declarado e ausente: {asset}")

    for asset_dir in re.findall(
        r"(?m)^\s+- (assets/[^\s]+/)\s*$",
        pubspec_text,
    ):
        if not (ROOT / asset_dir).is_dir():
            errors.append(
                f"diretório de assets declarado e ausente: {asset_dir}"
            )

    requirements = (
        (BACKEND / "requirements.txt")
        .read_text(encoding="utf-8", errors="ignore")
        .lower()
    )
    for distribution in (
        "fastapi",
        "uvicorn",
        "sqlalchemy",
        "psycopg",
        "python-jose",
        "pytest",
        "alembic",
    ):
        if distribution not in requirements:
            errors.append(
                f"dependência Python crítica ausente de requirements.txt: "
                f"{distribution}"
            )

    requirements_dev = (
        (BACKEND / "requirements-dev.txt")
        .read_text(encoding="utf-8", errors="ignore")
    )
    if "-r requirements.txt" not in requirements_dev:
        errors.append(
            "requirements-dev.txt não inclui requirements.txt"
        )

    errors.extend(python_syntax_errors())

    # Regressão já observada: método iniciado em uma nova linha sem continuação.
    for path in (ROOT / "scripts").rglob("*.ps1"):
        source = path.read_text(encoding="utf-8", errors="ignore")
        for line_number, line in enumerate(source.splitlines(), start=1):
            if re.match(r"^\s*\.[A-Za-z_][A-Za-z0-9_]*\s*\(", line):
                errors.append(
                    "método PowerShell iniciado em nova linha sem continuação: "
                    f"{path.relative_to(ROOT)}:{line_number}"
                )

    # Python multilinha embutido em PowerShell foi a causa da regressão
    # da baseline anterior. Bloqueamos explicitamente esse padrão.
    for path in (ROOT / "scripts").rglob("*.ps1"):
        source = path.read_text(encoding="utf-8", errors="ignore")
        if re.search(r"-c\s+@['\"]", source):
            errors.append(
                "Python multiline embutido em PowerShell: "
                f"{path.relative_to(ROOT)}"
            )

    obsolete_files = (
        "lib/features/animal_health/domain/services/"
        "animal_health_inventory_service.dart",
        "lib/features/executive_core/presentation/screens/"
        "atlas_executive_core_screen.dart",
        "lib/features/authentication/presentation/screens/"
        "welcome_screen.dart",
        "lib/core/network/atlas_connected_repository.dart",
    )
    for relative in obsolete_files:
        if (ROOT / relative).exists():
            errors.append(f"arquivo obsoleto reapareceu: {relative}")

    placeholders = sorted(
        ROOT.glob("test/**/*placeholder_test.dart")
    )
    for path in placeholders:
        errors.append(
            f"teste placeholder reapareceu: {path.relative_to(ROOT)}"
        )

    gitignore = (
        (ROOT / ".gitignore")
        .read_text(encoding="utf-8", errors="ignore")
    )
    if "backend/.venv/" not in gitignore:
        errors.append(
            ".gitignore não protege backend/.venv/"
        )

    ensure_source = (
        (ROOT / "scripts/dev/ensure_backend_venv.ps1")
        .read_text(encoding="utf-8", errors="ignore")
    )
    if "check_python_environment.py" not in ensure_source:
        errors.append(
            "ensure_backend_venv.ps1 não usa validador Python externo"
        )

    bootstrap_source = (
        (ROOT / "scripts/dev/bootstrap_project.ps1")
        .read_text(encoding="utf-8", errors="ignore")
    )
    if "flutter pub get" not in bootstrap_source:
        errors.append(
            "bootstrap_project.ps1 não restaura dependências Flutter"
        )

    start_backend_source = (
        (ROOT / "scripts/dev/start_backend.ps1")
        .read_text(encoding="utf-8", errors="ignore")
    )
    if "ensure_backend_venv.ps1" not in start_backend_source:
        errors.append(
            "start_backend.ps1 não prepara a .venv"
        )

    reconcile_source = (
        (BACKEND / "scripts/reconcile_local_alembic.py")
        .read_text(encoding="utf-8", errors="ignore")
    )
    if "ensure_development_schema_compatibility" not in reconcile_source:
        errors.append(
            "reconciliador Alembic perdeu o reparo aditivo local"
        )

    result = {
        "status": "FAIL" if errors else "OK",
        "declared_dart_packages": sorted(declared_packages),
        "imported_dart_packages": sorted(imported_packages),
        "missing_dart_packages": missing_packages,
        "python_syntax_error_count": len(
            [item for item in errors if ".py:" in item]
        ),
        "errors": errors,
        "warnings": warnings,
    }

    output = ROOT / "ATLAS_BASELINE_STATIC_AUDIT.json"
    output.write_text(
        json.dumps(
            result,
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )

    print(json.dumps(result, ensure_ascii=False, indent=2))
    print(
        "\nATLAS BASELINE STATIC AUDIT:",
        "FAIL" if errors else "OK",
    )
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
