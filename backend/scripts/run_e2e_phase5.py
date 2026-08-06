from __future__ import annotations
import os, sys, requests

BASE=os.getenv("ATLAS_BASE_URL","http://127.0.0.1:8000/api/v1")
TOKEN=os.getenv("ATLAS_ACCESS_TOKEN","")
FARM=os.getenv("ATLAS_FARM_ID","")
if not TOKEN or not FARM:
    raise SystemExit("Defina ATLAS_ACCESS_TOKEN e ATLAS_FARM_ID.")
h={"Authorization":f"Bearer {TOKEN}"}
checks=[
  ("dashboard",f"/platform/dashboard/farms/{FARM}"),
  ("ai_context",f"/platform/ai/context/farms/{FARM}"),
  ("security",f"/platform/security/readiness/farms/{FARM}"),
  ("production","/platform/production/readiness"),
]
failed=[]
for name,path in checks:
    r=requests.get(BASE+path,headers=h,timeout=30)
    print(name,r.status_code)
    if not r.ok: failed.append((name,r.text[:300]))
if failed:
    print(failed); sys.exit(1)
print("Fase 5: smoke E2E aprovado.")
