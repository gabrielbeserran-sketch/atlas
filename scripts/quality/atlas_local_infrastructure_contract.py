from __future__ import annotations

import json
import re
from pathlib import Path
from urllib.parse import unquote, urlsplit

import yaml

ROOT = Path(__file__).resolve().parents[2]
COMPOSE = ROOT / "docker-compose.yml"
BACKEND_ENV = ROOT / "backend" / ".env"
START_INFRA = ROOT / "scripts" / "dev" / "start_local_infrastructure.ps1"
START_BACKEND = ROOT / "scripts" / "dev" / "start_backend.ps1"
QUALITY_GATE = ROOT / "scripts" / "quality" / "run_full_quality_gate.ps1"
QUALITY_GATE_CORE = ROOT / "scripts" / "quality" / "run_full_quality_gate_core.ps1"
DB_CHECK = ROOT / "backend" / "scripts" / "check_local_database_connection.py"


def env_value(path: Path, key: str) -> str:
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        name, value = line.split("=", 1)
        if name.strip() == key:
            return value.strip()
    raise KeyError(f"{key} ausente em {path.relative_to(ROOT)}")


def parse_database_url(raw: str) -> dict[str, object]:
    normalized = re.sub(r"^postgresql\+[^:]+://", "postgresql://", raw)
    parsed = urlsplit(normalized)
    return {
        "user": unquote(parsed.username or ""),
        "password": unquote(parsed.password or ""),
        "host": parsed.hostname or "",
        "port": parsed.port,
        "database": parsed.path.lstrip("/"),
    }


def main() -> int:
    errors: list[str] = []
    required_files = [COMPOSE, BACKEND_ENV, START_INFRA, START_BACKEND, QUALITY_GATE, QUALITY_GATE_CORE, DB_CHECK]
    for path in required_files:
        if not path.exists():
            errors.append(f"arquivo obrigatório ausente: {path.relative_to(ROOT)}")

    if errors:
        print(json.dumps({"errors": errors}, ensure_ascii=False, indent=2))
        return 1

    compose = yaml.safe_load(COMPOSE.read_text(encoding="utf-8")) or {}
    services = compose.get("services", {})
    db = services.get("db", {})
    db_env = db.get("environment", {}) or {}
    ports = [str(item) for item in db.get("ports", []) or []]
    compose_contract = {
        "user": str(db_env.get("POSTGRES_USER", "")),
        "password": str(db_env.get("POSTGRES_PASSWORD", "")),
        "database": str(db_env.get("POSTGRES_DB", "")),
    }

    if "5432:5432" not in ports:
        errors.append("docker-compose.yml precisa publicar 5432:5432 no serviço db")

    backend_contract = parse_database_url(env_value(BACKEND_ENV, "ATLAS_DATABASE_URL"))
    if backend_contract["host"] not in {"localhost", "127.0.0.1"}:
        errors.append("backend/.env local deve usar localhost ou 127.0.0.1")
    if backend_contract["port"] != 5432:
        errors.append("backend/.env local deve usar a porta 5432")
    for key in ("user", "password", "database"):
        if backend_contract[key] != compose_contract[key]:
            errors.append(f"contrato divergente para {key}")

    docker_backend_url = str(
        (services.get("backend", {}).get("environment", {}) or {}).get("ATLAS_DATABASE_URL", "")
    )
    docker_contract = parse_database_url(docker_backend_url) if docker_backend_url else {}
    if docker_contract.get("host") != "db":
        errors.append("backend Docker deve usar host db")
    if docker_contract.get("port") != 5432:
        errors.append("backend Docker deve usar porta 5432")
    for key in ("user", "password", "database"):
        if docker_contract.get(key) != compose_contract[key]:
            errors.append(f"backend Docker diverge do db para {key}")

    infra = START_INFRA.read_text(encoding="utf-8")
    backend = START_BACKEND.read_text(encoding="utf-8")
    gate = QUALITY_GATE.read_text(encoding="utf-8-sig")
    gate_core = QUALITY_GATE_CORE.read_text(encoding="utf-8-sig")

    required_tokens = [
        "Reconcile-PostgresPassword",
        "Test-TcpEndpoint",
        "Wait-TcpEndpoint",
        "Repair-LocalDatabaseReachability",
        "--force-recreate",
        "Assert-BackendAuthentication",
        "check_local_database_connection.py",
        "127.0.0.1",
    ]
    for token in required_tokens:
        if token not in infra:
            errors.append(f"start_local_infrastructure.ps1 perdeu proteção obrigatória: {token}")

    # Não voltar a transformar metadados/saída textual do Docker em critério de
    # aprovação. O runtime deve ser decidido por TCP + autenticação real.
    forbidden_runtime_gates = [
        "docker compose port db 5432",
        "Get-DbPortBinding",
        "Assert-PublishedPort",
        "HostConfig.PortBindings",
    ]
    for token in forbidden_runtime_gates:
        if token in infra:
            errors.append(f"validação frágil reintroduzida no runtime: {token}")

    if '& $InfraScript' not in backend:
        errors.append("start_backend.ps1 deve executar diretamente start_local_infrastructure.ps1")
    gate_chain_ok = (
        ('preflight_project.ps1' in gate and 'run_full_quality_gate_core.ps1' in gate)
        and ('& $InfrastructureScript' in gate_core)
    )
    if not gate_chain_ok:
        errors.append(
            "Quality Gate deve seguir a cadeia oficial wrapper -> preflight -> core -> infraestrutura"
        )

    for path in (START_INFRA, START_BACKEND, QUALITY_GATE, QUALITY_GATE_CORE):
        low = path.read_text(encoding="utf-8").lower()
        for pattern in ("docker compose down -v", "docker-compose down -v"):
            if pattern in low:
                errors.append(f"comando destrutivo de volumes proibido: {path.relative_to(ROOT)}")

    result = {
        "compose_port_published": "5432:5432" in ports,
        "contracts_match": not any(
            backend_contract[k] != compose_contract[k] for k in ("user", "password", "database")
        ),
        "runtime_truth_source": "tcp_plus_sqlalchemy_authentication",
        "password_reconciliation": "Reconcile-PostgresPassword" in infra,
        "tcp_validation": "Wait-TcpEndpoint" in infra,
        "safe_auto_repair": "Repair-LocalDatabaseReachability" in infra and "--force-recreate" in infra,
        "real_backend_authentication": "Assert-BackendAuthentication" in infra,
        "docker_metadata_not_used_as_runtime_gate": not any(t in infra for t in forbidden_runtime_gates),
        "errors": errors,
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))
    if errors:
        print("\nATLAS LOCAL INFRASTRUCTURE CONTRACT: FAIL")
        return 1
    print("\nATLAS LOCAL INFRASTRUCTURE CONTRACT: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
