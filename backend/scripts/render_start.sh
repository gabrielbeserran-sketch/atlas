#!/bin/sh
set -eu

PORT="${PORT:-10000}"

echo "ATLAS STARTUP: executando preflight de dependências..."
python /app/scripts/render_preflight.py

echo "ATLAS STARTUP: aplicando migrations Alembic..."
python -m alembic upgrade head

echo "ATLAS STARTUP: verificando head das migrations..."
python /app/scripts/render_post_migration_check.py

echo "ATLAS STARTUP: dependências e migrations aprovadas."
echo "ATLAS STARTUP: iniciando API na porta ${PORT}..."
exec uvicorn app.main:app --host 0.0.0.0 --port "$PORT"
