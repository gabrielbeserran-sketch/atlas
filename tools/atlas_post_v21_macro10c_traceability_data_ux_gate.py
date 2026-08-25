from __future__ import annotations

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        print(f"[ERRO] {message}")
        raise SystemExit(1)
    print(f"[OK] {message}")


migration = read("backend/alembic/versions/20260825_0050_data_quality_utf8_traceability.py")
require('revision = "20260825_0050"' in migration, "Migration 0050 declarada.")
require('down_revision = "20260825_0049"' in migration, "Migration 0050 encadeada em 0049.")
require("atlas_data_quality_state" in migration, "Estado de qualidade persistente criado para prova de produção.")
require("jsonb_array_elements" in migration and "jsonb_each" in migration, "Saneamento recursivo cobre JSON/JSONB legado.")
require("information_schema.columns" in migration, "Saneamento varre colunas textuais persistidas.")

backend_norm = read("backend/app/database.py")
require("before_flush" in backend_norm and "repair_mojibake_text" in backend_norm, "Normalização UTF-8 permanece na borda de persistência.")
require("normalize_text_payload" in backend_norm, "Payloads JSON também são normalizados antes do flush.")

http = read("lib/core/network/atlas_http_client.dart")
require("AtlasTextNormalizer.normalize(body)" in http, "Entrada remota Flutter é normalizada antes do envio.")
require("AtlasTextNormalizer.normalize(jsonDecode(text))" in http, "Saída remota Flutter é normalizada após leitura UTF-8.")

ui_text = read("lib/core/text/atlas_ui_text.dart")
for code, label in {
    "health": "Sanidade",
    "nutrition": "Nutrição",
    "maintenance": "Manutenção",
    "inventory": "Estoque",
    "reproduction": "Reprodução",
    "livestock": "Rebanho",
}.items():
    require(f"'{code}': '{label}'" in ui_text, f"Categoria técnica {code} tem rótulo de domínio {label}.")

animal_detail = read("lib/features/animal/presentation/screens/animal_detail_screen.dart")
require("int get traceabilityCoverage" in animal_detail, "Central do Animal calcula cobertura de rastreabilidade.")
require("title: 'Rastreabilidade'" in animal_detail, "Central do Animal exibe rastreabilidade ao usuário.")
require("enterpriseTimelineCount > 0" in animal_detail, "Cobertura considera timeline oficial enterprise.")

cache_services = [
    "lib/features/animal_weight/data/services/animal_weight_storage_service.dart",
    "lib/features/animal_movement/data/services/animal_movement_storage_service.dart",
    "lib/features/animal_event/data/services/animal_event_storage_service.dart",
    "lib/features/animal_photo/data/services/animal_photo_storage_service.dart",
    "lib/features/animal_document/data/services/animal_document_storage_service.dart",
]
for rel in cache_services:
    source = read(rel)
    require("AtlasTextNormalizer.normalize(jsonDecode(" in source, f"Cache legado normalizado: {rel}.")

livestock = read("backend/app/routers/livestock.py")
require('/data-quality/deployment-readiness' in livestock, "Readiness público 10C disponível.")
require('"contract_version": "10C"' in livestock, "Readiness publica contrato 10C.")
require('"farm_scope_guard": True' in livestock, "Readiness declara proteção de escopo de fazenda.")

# Bloqueia mojibake real em superfícies de produção. Exemplos deliberados do
# normalizador/migrations/gates são excluídos porque são fixtures de reparo.
bad_tokens = (
    "Ã§", "Ã£", "Ã©", "Ã³", "Ãª", "Ã¡", "Ã­", "Ãº",
    "Â·", "Âº", "Âª", "â€“", "â€”", "â€™", "â€œ", "â€\x9d", "ðŸ", "�",
)
excluded = {
    ROOT / "lib/core/text/atlas_text_normalizer.dart",
    ROOT / "backend/app/text_normalization.py",
    ROOT / "backend/alembic/versions/20260821_0041_repair_mojibake_text.py",
    ROOT / "backend/alembic/versions/20260825_0050_data_quality_utf8_traceability.py",
    ROOT / "tools/atlas_post_v21_macro10c_traceability_data_ux_gate.py",
}
violations: list[str] = []
for base in (ROOT / "lib", ROOT / "backend/app", ROOT / "backend/scripts"):
    if not base.exists():
        continue
    for path in base.rglob("*"):
        if not path.is_file() or path in excluded:
            continue
        if path.suffix.lower() not in {".dart", ".py", ".json", ".yaml", ".yml", ".txt"}:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            violations.append(f"{path.relative_to(ROOT)}: arquivo não é UTF-8 válido")
            continue
        for line_no, line in enumerate(text.splitlines(), 1):
            if any(token in line for token in bad_tokens):
                violations.append(f"{path.relative_to(ROOT)}:{line_no}: {line.strip()[:140]}")
                break
require(not violations, "Nenhum mojibake literal em superfícies de produção." + ("\n" + "\n".join(violations[:20]) if violations else ""))

# Evita que códigos internos comuns voltem a aparecer diretamente em Text().
# A regra é conservadora: só procura literais exatos nas superfícies Dart.
technical_literals = re.compile(r"Text\(\s*['\"](?:health|nutrition|maintenance|inventory|reproduction|livestock)['\"]\s*\)")
tech_hits: list[str] = []
for path in (ROOT / "lib").rglob("*.dart"):
    text = path.read_text(encoding="utf-8")
    if technical_literals.search(text):
        tech_hits.append(str(path.relative_to(ROOT)))
require(not tech_hits, "Categorias técnicas não aparecem como rótulos Text() literais." + (" " + ", ".join(tech_hits[:10]) if tech_hits else ""))

print("ATLAS POS-V21 MACROPACOTE 10C: APROVADO")
print("[OK] Central do Animal com rastreabilidade explícita.")
print("[OK] Dados legados saneados em texto e JSON/JSONB.")
print("[OK] Entrada, persistência, saída e cache possuem fallback UTF-8.")
print("[OK] Vocabulário técnico de UI protegido por gate.")
