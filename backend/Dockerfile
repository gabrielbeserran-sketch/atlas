FROM python:3.12-slim

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends postgresql-client \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app
COPY scripts ./scripts
COPY alembic ./alembic
COPY alembic.ini ./alembic.ini
COPY tests ./tests

RUN mkdir -p /data/backups /data/attachments \
    && chmod +x /app/scripts/render_start.sh

EXPOSE 10000

CMD ["/app/scripts/render_start.sh"]
