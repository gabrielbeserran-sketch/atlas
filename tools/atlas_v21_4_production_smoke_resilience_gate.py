from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
text = (
    ROOT / "scripts/quality/gate_v16_v17_production.ps1"
).read_text(encoding="utf-8-sig", errors="ignore")

checks = {
    "max attempts parameter": "[int]$MaxAttempts = 5" in text,
    "180s default timeout": "[int]$RequestTimeoutSec = 180" in text,
    "central retry wrapper": "function Invoke-AtlasRequest" in text,
    "transient classifier": "function Test-TransientFailure" in text,
    "retry 408": "408" in text,
    "retry 429": "429" in text,
    "retry 502": "502" in text,
    "retry 503": "503" in text,
    "retry 504": "504" in text,
    "health uses retry wrapper": '-Operation "Health /health/ready"' in text,
    "login uses retry wrapper": '-Operation "Login"' in text,
    "GET wrapper limited retries": "-Attempts 3" in text,
    "cold start messaging": "cold start" in text.lower(),
    "backoff": "Start-Sleep -Seconds $delay" in text,
    "safe operation interpolation": (
        "${Operation}: nova tentativa" in text
        and "${Operation}: falha transitória/cold start" in text
        and "$Operation:" not in text
    ),
}

failed = [name for name, ok in checks.items() if not ok]
print(f"ATLAS V21.4 PRODUCTION SMOKE RESILIENCE: {len(checks)-len(failed)}/{len(checks)}")
for name in failed:
    print("FAIL:", name)
sys.exit(1 if failed else 0)
