#!/bin/sh
set -eu

PORT="${PORT:-10000}"

echo "ATLAS STARTUP: aplicando migrations Alembic..."
python -m alembic upgrade head

echo "ATLAS STARTUP: migrations concluídas. Iniciando API na porta ${PORT}..."
exec uvicorn app.main:app --host 0.0.0.0 --port "$PORT"
