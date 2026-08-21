from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
http = (ROOT / 'lib/core/network/atlas_http_client.dart').read_text(encoding='utf-8')
normalizer = (ROOT / 'lib/core/text/atlas_text_normalizer.dart').read_text(encoding='utf-8')
ui_text = (ROOT / 'lib/core/text/atlas_ui_text.dart').read_text(encoding='utf-8')
genealogy_service = (ROOT / 'lib/features/animal_genealogy/data/services/animal_genealogy_enterprise_service.dart').read_text(encoding='utf-8')
livestock = (ROOT / 'backend/app/routers/livestock.py').read_text(encoding='utf-8')
reports = (ROOT / 'lib/features/reports/presentation/screens/reports_screen.dart').read_text(encoding='utf-8')
nutrition = (ROOT / 'lib/features/nutrition/presentation/screens/nutrition_overview_screen.dart').read_text(encoding='utf-8')
inventory = (ROOT / 'lib/features/farm_inventory/presentation/screens/farm_inventory_list_screen.dart').read_text(encoding='utf-8')
text_tests = (ROOT / 'test/core/text/atlas_text_normalizer_test.dart').read_text(encoding='utf-8')
seed = (ROOT / 'scripts/dev/seed_demo_production.ps1').read_bytes()

checks = {
    'http_decodes_utf8_bytes': '_decodeBodyBytes(response.bodyBytes)' in http,
    'http_normalizes_legacy_text': 'AtlasTextNormalizer.normalize(jsonDecode(text))' in http,
    'mojibake_repair_is_conservative': '_mojibakeMarkers.hasMatch(value)' in normalizer,
    'ui_status_dictionary': "'registered': 'Registrado'" in ui_text and "'active': 'Ativo'" in ui_text,
    'ui_category_dictionary': "'nutrition': 'Nutrição'" in ui_text and "'health': 'Sanidade'" in ui_text,
    'reports_normalize_category': 'AtlasUiText.category(record.category)' in reports,
    'nutrition_normalizes_display_and_search': 'AtlasUiText.clean(plan.dietName)' in nutrition and 'AtlasUiText.clean(search)' in nutrition,
    'inventory_normalizes_display_and_search': 'AtlasUiText.clean(item.name)' in inventory and 'AtlasUiText.clean(searchText)' in inventory,
    'text_normalizer_has_regression_tests': "Plano HomologaÃ§Ã£o V18 Matrizes" in text_tests and "Concentrado Homologação V18" in text_tests,
    'genealogy_flutter_uses_livestock': "'/livestock/animals/$animalId/genealogy'" in genealogy_service,
    'legacy_genealogy_path_removed_from_flutter': "'/animals/$animalId/genealogy'" not in genealogy_service,
    'backend_canonical_genealogy_route': 'def livestock_animal_genealogy(' in livestock,
    'backend_genealogy_uses_livestock_animal': 'select(LivestockAnimal).where(' in livestock,
    'backend_genealogy_supports_parent_ids': 'id_field="father_id"' in livestock and 'id_field="mother_id"' in livestock,
    'backend_genealogy_supports_legacy_tags': 'metadata_field="father_tag"' in livestock and 'metadata_field="mother_tag"' in livestock,
    'seed_has_single_utf8_bom': seed.startswith(b'\xef\xbb\xbf') and seed[3:].count(b'\xef\xbb\xbf') == 0,
}

# Nenhum mojibake literal deve existir nas telas/código de produto; o arquivo
# normalizador é a única exceção porque precisa reconhecer esses marcadores.
mojibake_markers = ('Ã§', 'Ã£', 'Ã©', 'Ã¡', 'Ã³', 'Ãª', 'Ã­', 'Ãº', 'Â', 'â€', '�')
mojibake_files = []
for path in (ROOT / 'lib').rglob('*.dart'):
    if path.name == 'atlas_text_normalizer.dart':
        continue
    text = path.read_text(encoding='utf-8', errors='ignore')
    if any(marker in text for marker in mojibake_markers):
        mojibake_files.append(str(path.relative_to(ROOT)))
checks['no_mojibake_literals_in_product_source'] = not mojibake_files

checks['advanced_status_display_standardized'] = all(
    '${record.date} • ${record.status}' not in path.read_text(encoding='utf-8', errors='ignore')
    for path in (ROOT / 'lib/features').rglob('presentation/**/*.dart')
)

failed = [name for name, ok in checks.items() if not ok]
print(f"ATLAS V20.1 TEXT + GENEALOGY: {len(checks)-len(failed)}/{len(checks)}")
if mojibake_files:
    print('Mojibake source files:', *mojibake_files, sep='\n- ')
if failed:
    print('FAIL:', ', '.join(failed))
    sys.exit(1)
print('ATLAS V20.1 TEXT + GENEALOGY: OK')
