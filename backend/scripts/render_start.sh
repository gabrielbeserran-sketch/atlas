#!/bin/sh
set -eu

cd /app

PORT="${PORT:-10000}"

echo "ATLAS STARTUP: diretorio=$(pwd)"
echo "ATLAS STARTUP: Python=$(python --version 2>&1)"

echo "ATLAS STARTUP: validando imports e namespaces..."
python -m scripts.render_import_contract_check

echo "ATLAS STARTUP: executando preflight de dependencias..."
python -m scripts.render_preflight

echo "ATLAS STARTUP: aplicando migrations Alembic com reconciliacao estrutural v3 sem recursao..."
python -m alembic upgrade head

echo "ATLAS STARTUP: verificando head das migrations..."
python -m scripts.render_post_migration_check

echo "ATLAS STARTUP: auditando contrato final do schema..."
python -m scripts.render_schema_contract_check

echo "ATLAS STARTUP: dependencias, migrations e schema aprovados."
echo "ATLAS STARTUP: iniciando API na porta ${PORT}..."

exec python -m uvicorn app.main:app   --host 0.0.0.0   --port "$PORT"
