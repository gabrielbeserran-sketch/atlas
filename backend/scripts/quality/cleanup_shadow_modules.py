"""Remove módulos antigos que sombreiam os pacotes consolidados.

Execute a partir da raiz do backend. É seguro repetir o comando.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONFLICTS = [ROOT / "app" / "models.py", ROOT / "app" / "schemas.py"]
removed = []
for path in CONFLICTS:
    if path.exists():
        path.unlink()
        removed.append(path.relative_to(ROOT).as_posix())

if removed:
    print("OK: módulos antigos removidos: " + ", ".join(removed))
else:
    print("OK: nenhum módulo antigo conflitante encontrado.")
