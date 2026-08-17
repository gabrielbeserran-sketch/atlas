from __future__ import annotations

import ast
import hashlib
import json
import re
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[2]
BACKEND = ROOT / "backend"
MANIFEST = ROOT / "ATLAS_BASELINE_MANIFEST.json"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def parse_env(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    if not path.is_file():
        return result
    for raw in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        result[key.strip()] = value.strip().strip('"').strip("'")
    return result


def critical_source_files() -> set[str]:
    result: set[str] = set()
    patterns = (
        ("lib", "*.dart"),
        ("test", "*.dart"),
        ("scripts", "*.ps1"),
        ("scripts", "*.py"),
        ("backend/app", "*.py"),
        ("backend/scripts", "*.py"),
        ("backend/tests", "*.py"),
        ("backend/alembic/versions", "*.py"),
    )
    for directory, pattern in patterns:
        base = ROOT / directory
        if not base.exists():
            continue
        for path in base.rglob(pattern):
            if "__pycache__" in path.parts:
                continue
            result.add(str(path.relative_to(ROOT)).replace("\\", "/"))
    return result


def check_direct_python_bootstrap(relative: str, errors: list[str]) -> None:
    path = ROOT / relative
    if not path.is_file():
        errors.append(f"script Python obrigatório ausente: {relative}")
        return

    source = path.read_text(encoding="utf-8", errors="ignore")
    try:
        tree = ast.parse(source)
    except SyntaxError as exc:
        errors.append(
            f"{relative}: sintaxe Python: {exc.msg} linha {exc.lineno}"
        )
        return

    app_lines: list[int] = []
    path_lines: list[int] = []

    for node in ast.walk(tree):
        if (
            isinstance(node, ast.ImportFrom)
            and node.module
            and (node.module == "app" or node.module.startswith("app."))
        ):
            app_lines.append(node.lineno)

        if isinstance(node, ast.Call):
            func = node.func
            if (
                isinstance(func, ast.Attribute)
                and func.attr in {"insert", "append"}
                and isinstance(func.value, ast.Attribute)
                and func.value.attr == "path"
                and isinstance(func.value.value, ast.Name)
                and func.value.value.id == "sys"
            ):
                path_lines.append(node.lineno)

    if app_lines and (
        not path_lines or min(path_lines) > min(app_lines)
    ):
        errors.append(
            f"{relative}: importa app antes de garantir backend/ em sys.path"
        )


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []

    if not MANIFEST.is_file():
        errors.append("ATLAS_BASELINE_MANIFEST.json ausente")
        manifest: dict[str, object] = {}
    else:
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))

    expected = set(manifest.get("critical_source_files", []))
    actual = critical_source_files()

    for item in sorted(expected - actual):
        errors.append(f"arquivo da baseline ausente: {item}")
    for item in sorted(actual - expected):
        errors.append(
            f"arquivo-fonte inesperado/resíduo de outra versão: {item}"
        )

    protected = manifest.get("protected_file_sha256", {})
    if isinstance(protected, dict):
        for relative, expected_hash in protected.items():
            path = ROOT / relative
            if not path.is_file():
                errors.append(f"arquivo protegido ausente: {relative}")
                continue
            if sha256(path) != expected_hash:
                errors.append(
                    f"arquivo protegido divergiu da baseline: {relative}"
                )

    env = parse_env(BACKEND / ".env")
    db_url = env.get("ATLAS_DATABASE_URL", "")
    if not db_url:
        errors.append("backend/.env sem ATLAS_DATABASE_URL")
    else:
        parsed = urlparse(
            db_url.replace(
                "postgresql+psycopg://",
                "postgresql://",
            )
        )
        if parsed.hostname not in {"localhost", "127.0.0.1"}:
            errors.append(
                "ATLAS_DATABASE_URL local deve usar localhost/127.0.0.1"
            )
        if parsed.port != 5432:
            errors.append(
                "ATLAS_DATABASE_URL local deve usar porta 5432"
            )
        if not parsed.username or not parsed.password:
            errors.append(
                "ATLAS_DATABASE_URL local precisa conter usuário e senha"
            )

    compose = (ROOT / "docker-compose.yml").read_text(
        encoding="utf-8",
        errors="ignore",
    )
    for token in (
        "5432:5432",
        "POSTGRES_DB",
        "POSTGRES_USER",
        "POSTGRES_PASSWORD",
    ):
        if token not in compose:
            errors.append(
                f"docker-compose.yml sem contrato obrigatório: {token}"
            )

    for relative in (
        "backend/scripts/check_local_database_connection.py",
        "backend/scripts/reconcile_local_alembic.py",
    ):
        check_direct_python_bootstrap(relative, errors)

    obsolete = (
        "lib/features/animal_health/domain/services/"
        "animal_health_inventory_service.dart",
        "lib/features/executive_core/presentation/screens/"
        "atlas_executive_core_screen.dart",
        "lib/features/authentication/presentation/screens/"
        "welcome_screen.dart",
        "lib/core/network/atlas_connected_repository.dart",
    )
    for relative in obsolete:
        if (ROOT / relative).exists():
            errors.append(f"resíduo histórico reapareceu: {relative}")

    # Contratos de auditoria que travam crescimento legítimo em uma contagem
    # exata (>1) já causaram regressão falsa no Marco 4. Bloqueamos o padrão.
    brittle_pattern = re.compile(r"len\\([^\\n]+\\)\\s*!=\\s*([2-9][0-9]*)")
    for path in (ROOT / "scripts" / "quality").glob("*.py"):
        if path.name == Path(__file__).name:
            continue
        source_text = path.read_text(encoding="utf-8", errors="ignore")
        for match in brittle_pattern.finditer(source_text):
            errors.append(
                "contrato de contagem exata frágil (>1) detectado: "
                f"{path.relative_to(ROOT)} -> != {match.group(1)}"
            )

    predicted_risks = [
        {
            "risk": "porta_8000_em_uso",
            "probability": "media",
            "prevention": (
                "usar somente uma instância de start_backend e não iniciar "
                "Uvicorn manualmente em paralelo"
            ),
        },
        {
            "risk": "porta_5432_ocupada_ou_container_antigo",
            "probability": "media",
            "prevention": (
                "validar socket real e autenticação; recriar somente db "
                "quando necessário, preservando volume"
            ),
        },
        {
            "risk": "dependencias_flutter_nao_restauradas",
            "probability": "alta_em_extracao_limpa",
            "prevention": (
                "bootstrap_project executa flutter pub get e exige "
                ".dart_tool/package_config.json"
            ),
        },
        {
            "risk": "venv_ausente_ou_desatualizada",
            "probability": "alta_em_extracao_limpa",
            "prevention": (
                "ensure_backend_venv cria a venv e valida fingerprint "
                "dos requirements"
            ),
        },
        {
            "risk": "schema_local_antigo",
            "probability": "alta_em_base_existente",
            "prevention": (
                "reconcile_local_alembic faz reparo aditivo e revalida "
                "antes do stamp"
            ),
        },
        {
            "risk": "arquivos_antigos_mesclados",
            "probability": "alta_se_copiar_por_cima",
            "prevention": (
                "manifesto da baseline bloqueia arquivos-fonte inesperados"
            ),
        },
        {
            "risk": "codificacao_windows_powershell",
            "probability": "media",
            "prevention": (
                "scripts .ps1 distribuídos em UTF-8 BOM + CRLF"
            ),
        },
        {
            "risk": "parser_powershell",
            "probability": "media",
            "prevention": (
                "preflight usa parser nativo do PowerShell antes de executar"
            ),
        },
        {
            "risk": "import_python_direto",
            "probability": "media",
            "prevention": (
                "auditoria exige bootstrap de sys.path antes de import app"
            ),
        },
    ]

    result = {
        "status": "FAIL" if errors else "OK",
        "errors": errors,
        "warnings": warnings,
        "predicted_risks": predicted_risks,
    }

    (ROOT / "ATLAS_PREDICTIVE_RISK_AUDIT.json").write_text(
        json.dumps(result, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(json.dumps(result, ensure_ascii=False, indent=2))
    print(
        "\nATLAS PREDICTIVE RISK AUDIT:",
        "FAIL" if errors else "OK",
    )
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
