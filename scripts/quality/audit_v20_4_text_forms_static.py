from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8", errors="strict")


checks: dict[str, bool] = {}

normalizer = read("lib/core/text/atlas_text_normalizer.dart")
http = read("lib/core/network/atlas_http_client.dart")
database = read("backend/app/database.py")
backend_normalizer = read("backend/app/text_normalization.py")
migration = read("backend/alembic/versions/20260821_0041_repair_mojibake_text.py")
finance = read("lib/features/farm_finance/presentation/screens/farm_finance_list_screen.dart")
form_widget = read("lib/core/widgets/atlas_form_actions.dart")

checks["dart_repairs_mojibake"] = "latin1.encode(current)" in normalizer
checks["dart_common_cp1252_replacements"] = "'â€“': '–'" in normalizer and "'â€™': '’'" in normalizer
checks["http_incoming_normalized"] = "AtlasTextNormalizer.normalize(jsonDecode(text))" in http
checks["http_outgoing_normalized"] = "jsonEncode(AtlasTextNormalizer.normalize(body))" in http
checks["backend_normalizer_exists"] = "def repair_mojibake_text" in backend_normalizer
checks["backend_normalizes_json"] = "def normalize_text_payload" in backend_normalizer
checks["orm_before_flush_guard"] = '@event.listens_for(Session, "before_flush")' in database
checks["orm_string_guard"] = "repair_mojibake_text(value)" in database
checks["orm_json_guard"] = "normalize_text_payload(value)" in database
checks["migration_repairs_existing_rows"] = "20260821_0041" in migration and "information_schema.columns" in migration
checks["migration_follows_0040"] = 'down_revision = "20260815_0040"' in migration

storage_files = [
    "lib/features/farm_finance/data/services/farm_finance_storage_service.dart",
    "lib/features/farm_inventory/data/services/farm_inventory_storage_service.dart",
    "lib/features/nutrition/data/services/nutrition_storage_service.dart",
    "lib/features/animal_health/data/services/animal_health_storage_service.dart",
    "lib/features/animal_reproduction/data/services/animal_reproduction_storage_service.dart",
    "lib/features/herd/data/services/herd_storage_service.dart",
    "lib/features/farm_agenda/data/services/farm_agenda_storage_service.dart",
    "lib/features/animal/data/services/animal_storage_service.dart",
]
checks["all_operational_caches_normalize"] = all(
    "AtlasTextNormalizer.normalize(jsonDecode(" in read(path) for path in storage_files
)

checks["finance_description_clean"] = "AtlasUiText.clean(record.description)" in finance
checks["finance_category_translated"] = "AtlasUiText.category(record.category)" in finance

form_files = [
    "lib/features/animal/presentation/screens/animal_form_screen.dart",
    "lib/features/herd/presentation/screens/herd_group_form_screen.dart",
    "lib/features/animal_health/presentation/screens/animal_health_form_screen.dart",
    "lib/features/animal_reproduction/presentation/screens/animal_reproduction_form_screen.dart",
    "lib/features/farm_agenda/presentation/screens/farm_agenda_form_screen.dart",
    "lib/features/farm_finance/presentation/screens/farm_finance_form_screen.dart",
    "lib/features/farm_inventory/presentation/screens/farm_inventory_form_screen.dart",
]
checks["operational_forms_use_shared_actions"] = all(
    "AtlasFormActions(" in read(path) for path in form_files
)
checks["form_actions_have_cancel"] = "label: const Text('Cancelar')" in form_widget
checks["form_actions_are_responsive"] = "constraints.maxWidth < 520" in form_widget
checks["form_actions_show_saving"] = "'Salvando...'" in form_widget

seed = (ROOT / "scripts/dev/seed_demo_production.ps1").read_bytes()
checks["seed_single_utf8_bom"] = seed.startswith(b"\xef\xbb\xbf") and not seed[3:].startswith(b"\xef\xbb\xbf")
seed_text = seed.decode("utf-8-sig")
checks["seed_correct_portuguese"] = all(
    term in seed_text
    for term in ("Vacinação", "Vermifugação", "Homologação", "Nutrição")
)

marker = re.compile(r"(Ã[§£¡©³ªº\u00adµ¢´¼]|Â[·ºª]|â€|â€™|â€œ|â€|â€“|â€”|ðŸ|�)")
visible_hits: list[str] = []
for path in (ROOT / "lib").rglob("*.dart"):
    rel = str(path.relative_to(ROOT)).replace("\\", "/")
    if "/presentation/" not in f"/{rel}":
        continue
    text = path.read_text(encoding="utf-8", errors="strict")
    if marker.search(text):
        visible_hits.append(rel)
checks["no_mojibake_literals_in_presentation"] = not visible_hits

failed = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(f"[{'OK' if ok else 'FAIL'}] {name}")
if visible_hits:
    print("Mojibake literals in presentation:")
    for item in visible_hits:
        print(f" - {item}")
print(f"\nATLAS V20.4 TEXT + FORMS: {len(checks)-len(failed)}/{len(checks)}")
if failed:
    print("FAIL:", ", ".join(failed))
    sys.exit(1)
print("ATLAS V20.4 TEXT + FORMS: OK")
