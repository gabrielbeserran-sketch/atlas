from __future__ import annotations
import json
from sqlalchemy import inspect
from app.database import engine
from app.models import SyncChange, EntityState, ProcessedOperation
from app.offline_models import OfflineDevice, SyncConflict, OfflineDiagnostic

required = {m.__tablename__ for m in (SyncChange, EntityState, ProcessedOperation, OfflineDevice, SyncConflict, OfflineDiagnostic)}
existing = set(inspect(engine).get_table_names())
missing = sorted(required - existing)
print(json.dumps({"status": "ready" if not missing else "not_ready", "required_tables": sorted(required), "missing_tables": missing}, indent=2, ensure_ascii=False))
raise SystemExit(1 if missing else 0)
