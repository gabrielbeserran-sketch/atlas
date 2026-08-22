from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

# Prefixos válidos do PowerShell que usam ':' deliberadamente.
VALID_QUALIFIERS = {
    "env",
    "script",
    "global",
    "local",
    "private",
    "using",
    "variable",
    "function",
    "alias",
    "cert",
    "wsman",
    "registry",
}

critical = [
    ROOT / "scripts/quality/gate_v16_v17_production.ps1",
    ROOT / "scripts/quality/run_v21_ux_homologation.ps1",
    ROOT / "scripts/quality/run_post_v21_package1_homologation.ps1",
]

errors = []

for path in critical:
    if not path.exists():
        errors.append(f"Arquivo crítico ausente: {path.relative_to(ROOT)}")
        continue

    text = path.read_text(encoding="utf-8-sig", errors="ignore")

    # Detecta $Nome: e aceita apenas qualificadores/PSDrives conhecidos.
    for match in re.finditer(r'\$([A-Za-z_][A-Za-z0-9_]*):', text):
        name = match.group(1)
        if name.lower() in VALID_QUALIFIERS:
            continue
        line = text[:match.start()].count("\n") + 1
        source_line = text.splitlines()[line - 1].strip()
        errors.append(
            f"{path.relative_to(ROOT)}:{line}: referência ambígua "
            f"${name}:; use ${{{name}}}: | {source_line}"
        )

# Regressão exata que quebrou V21.4.
production = critical[0].read_text(encoding="utf-8-sig", errors="ignore")
if "$Operation:" in production:
    errors.append("gate_v16_v17_production.ps1 ainda contém $Operation:.")

# As duas mensagens que falharam devem usar a forma segura.
required_fragments = (
    '${Operation}: nova tentativa',
    '${Operation}: falha transitória/cold start',
)
for fragment in required_fragments:
    if fragment not in production:
        errors.append(f"Trecho seguro obrigatório ausente: {fragment}")

wrapper = (
    ROOT / "scripts/quality/run_post_v21_package1_homologation.ps1"
).read_text(encoding="utf-8-sig", errors="ignore")
if re.search(r"(?im)^\s*\$args\s*=", wrapper):
    errors.append("Wrapper Pós-V21 não pode sobrescrever a variável automática $Args.")
if re.search(r"(?i)@args\b", wrapper):
    errors.append("Wrapper Pós-V21 não pode usar @Args para encaminhar parâmetros nomeados.")
if "$V21Parameters = @{" not in wrapper or "@V21Parameters" not in wrapper:
    errors.append("Wrapper Pós-V21 deve usar hashtable splatting para encaminhamento nomeado.")

if errors:
    print("ATLAS V21.5 POWERSHELL HYGIENE: FAIL")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS V21.5 POWERSHELL HYGIENE: OK")
