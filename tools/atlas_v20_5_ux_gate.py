from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
checks = []

def check(name, condition, detail=''):
    checks.append((name, bool(condition), detail))

feedback = ROOT / 'lib/core/widgets/atlas_feedback.dart'
check('feedback central existe', feedback.exists())
if feedback.exists():
    text = feedback.read_text(encoding='utf-8')
    check('validação central', 'validateForm' in text)
    check('confirmação destrutiva central', 'confirmDelete' in text)
    check('dialogo não fecha por toque externo', 'barrierDismissible: false' in text)

forms = [
    'animal/presentation/screens/animal_form_screen.dart',
    'herd/presentation/screens/herd_group_form_screen.dart',
    'animal_health/presentation/screens/animal_health_form_screen.dart',
    'animal_reproduction/presentation/screens/animal_reproduction_form_screen.dart',
    'farm_inventory/presentation/screens/farm_inventory_form_screen.dart',
    'farm_finance/presentation/screens/farm_finance_form_screen.dart',
    'farm_agenda/presentation/screens/farm_agenda_form_screen.dart',
]
for rel in forms:
    text = (ROOT / 'lib/features' / rel).read_text(encoding='utf-8')
    check(f'form feedback: {rel.split("/")[0]}', 'AtlasFeedback.validateForm' in text)
    check(f'form actions: {rel.split("/")[0]}', 'AtlasFormActions' in text)

lists = [
    'animal_health/presentation/screens/animal_health_list_screen.dart',
    'animal_reproduction/presentation/screens/animal_reproduction_list_screen.dart',
    'farm_inventory/presentation/screens/farm_inventory_list_screen.dart',
    'farm_finance/presentation/screens/farm_finance_list_screen.dart',
    'farm_agenda/presentation/screens/farm_agenda_list_screen.dart',
    'nutrition/presentation/screens/nutrition_overview_screen.dart',
]
for rel in lists:
    text = (ROOT / 'lib/features' / rel).read_text(encoding='utf-8')
    check(f'exclusão segura: {rel.split("/")[0]}', 'AtlasFeedback.confirmDelete' in text)

# Nenhuma string estática de marco/pacote/fase deve aparecer em apresentação.
for path in (ROOT / 'lib/features').rglob('presentation/**/*.dart'):
    text = path.read_text(encoding='utf-8', errors='ignore')
    bad = any(token in text for token in ('Marco 1', 'Marco 2', 'Pacote 1', 'Fase 1'))
    check(f'sem rótulo técnico: {path.relative_to(ROOT)}', not bad)

failed = [item for item in checks if not item[1]]
print(f'ATLAS V20.5 UX GATE: {len(checks)-len(failed)}/{len(checks)}')
for name, ok, detail in failed:
    print(f'FAIL: {name} {detail}')
raise SystemExit(1 if failed else 0)
