"""Homologa apenas PostgreSQL novo criado por este executor; não recebe URL externa.

Execute com .venv/Scripts/python tests/run_isolated_postgres_bootstrap.py.
Não usa pytest/conftest.py nem atlas_test.db. Docker Desktop precisa estar ativo.
"""
from __future__ import annotations

import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
import uuid

BACKEND = Path(__file__).resolve().parents[1]
LABEL = "atlas.isolated-bootstrap"
IMAGE = "postgres:16"
LOCAL_DOCKER_PIPE = "npipe:////./pipe/dockerDesktopLinuxEngine"


def command(args: list[str], *, env: dict[str, str] | None = None) -> str:
    timeout = 180
    if args[0] == "docker":
        if args[1] in {"info", "inspect"}:
            timeout = 10
        elif args[1] == "exec":
            timeout = 10
        elif args[1] == "stop":
            timeout = 30
        args = ["docker", "--host", LOCAL_DOCKER_PIPE, *args[1:]]
        env = os.environ.copy()
        env.pop("DOCKER_CONTEXT", None)
        env.pop("DOCKER_HOST", None)
    result = subprocess.run(args, cwd=BACKEND, env=env, capture_output=True,
                            text=True, timeout=timeout, check=False)
    if result.returncode:
        # Do not echo environment, connection strings or external diagnostics.
        raise RuntimeError(f"Falha em {args[0]} (código {result.returncode}).")
    return result.stdout.strip()


def isolated_port(description: dict, identity: str) -> int:
    """Never connect unless inspect proves our container and loopback-only binding."""
    config = description.get("Config", {})
    if config.get("Labels", {}).get(LABEL) != identity:
        raise ValueError("Contêiner não pertence a este ensaio.")
    if config.get("Image") != IMAGE:
        raise ValueError("Imagem inesperada.")
    if description.get("Mounts"):
        # postgres image creates an anonymous volume: only that ephemeral data volume is allowed.
        mounts = description["Mounts"]
        if any(m.get("Type") != "volume" or
               m.get("Destination") != "/var/lib/postgresql/data" for m in mounts):
            raise ValueError("Montagem não permitida no ensaio.")
    bindings = description.get("NetworkSettings", {}).get("Ports", {}).get("5432/tcp")
    if not isinstance(bindings, list) or len(bindings) != 1:
        raise ValueError("Porta não isolada.")
    binding = bindings[0]
    if binding.get("HostIp") != "127.0.0.1":
        raise ValueError("Conexão precisa ser exclusivamente local.")
    port = int(binding.get("HostPort", 0))
    if not 1 <= port <= 65535:
        raise ValueError("Porta inválida.")
    return port


def database_url(port: int, identity: str) -> str:
    if not re.fullmatch(r"[0-9a-f]{32}", identity) or not 1 <= port <= 65535:
        raise ValueError("Identidade ou porta inválida.")
    return f"postgresql+psycopg://atlas_probe@127.0.0.1:{port}/atlas_probe_{identity}"


def run() -> None:
    command(["docker", "info", "--format", "{{.ServerVersion}}"])
    identity = uuid.uuid4().hex
    container = command([
        "docker", "run", "--detach", "--rm", "--label", f"{LABEL}={identity}",
        "--publish", "127.0.0.1::5432", "--env", "POSTGRES_USER=atlas_probe",
        "--env", f"POSTGRES_DB=atlas_probe_{identity}",
        "--env", "POSTGRES_HOST_AUTH_METHOD=trust", IMAGE,
    ])
    if not re.fullmatch(r"[0-9a-f]{64}", container):
        raise RuntimeError("Identificador de contêiner inesperado; não executar limpeza por nome.")
    try:
        description = json.loads(command(["docker", "inspect", container]))[0]
        port = isolated_port(description, identity)
        for attempt in range(30):
            try:
                command(["docker", "exec", container, "pg_isready", "-U", "atlas_probe"])
                break
            except RuntimeError:
                if attempt == 29:
                    raise RuntimeError("PostgreSQL isolado não ficou pronto.") from None
                time.sleep(1)
        env = os.environ.copy()
        env["ATLAS_DATABASE_URL"] = database_url(port, identity)
        for _ in range(2):
            command([sys.executable, "-m", "alembic", "upgrade", "head"], env=env)
        verify = """
from sqlalchemy import create_engine, inspect, text
import os
engine = create_engine(os.environ['ATLAS_DATABASE_URL'])
with engine.connect() as connection:
    assert connection.execute(text('SELECT version_num FROM alembic_version')).scalar_one() == '20260926_0057'
    inspector = inspect(connection)
    assert 'client_operation_id' in {c['name'] for c in inspector.get_columns('weight_records')}
    for table, columns in [('weight_records', ['company_id', 'client_operation_id']),
                           ('pasture_grazing_bases', ['company_id', 'client_operation_id'])]:
        unique = inspector.get_unique_constraints(table)
        unique += [i for i in inspector.get_indexes(table) if i.get('unique')]
        assert any(i['column_names'] == columns for i in unique), table
engine.dispose()
"""
        command([sys.executable, "-c", verify], env=env)
    finally:
        description = json.loads(command(["docker", "inspect", container]))[0]
        if description.get("Config", {}).get("Labels", {}).get(LABEL) != identity:
            raise RuntimeError("Identidade divergente na limpeza; ensaio não aprovado.")
        command(["docker", "stop", container])
    print("PostgreSQL: upgrade até 0057, repetição e unicidades aprovados.")


if __name__ == "__main__":
    try:
        run()
    except (RuntimeError, ValueError, OSError, subprocess.TimeoutExpired):
        print("Ensaio não homologado. Verifique Docker local e dependências do backend.", file=sys.stderr)
        sys.exit(1)
