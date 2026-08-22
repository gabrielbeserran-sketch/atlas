from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[1]
text=(ROOT/"scripts/quality/run_v21_ux_homologation.ps1").read_text(encoding="utf-8-sig",errors="ignore")
checks={
"detecta processo":"Get-Process -Name \"projeto_atlas\"" in text,
"encerra processo":"Stop-Process -Force" in text,
"confirma encerramento":"$stillRunning" in text,
"retry build":"function Invoke-AtlasWindowsBuild" in text and "Attempts = 2" in text,
"limpeza limitada":"build\\windows" in text,
"sem flutter clean":"flutter clean" not in text,
}
failed=[k for k,v in checks.items() if not v]
print(f"ATLAS V21 WINDOWS BUILD LOCK: {len(checks)-len(failed)}/{len(checks)}")
for f in failed: print("FAIL:",f)
sys.exit(1 if failed else 0)
