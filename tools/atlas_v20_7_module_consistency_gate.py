from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
checks = []

def check(name, condition):
    checks.append((name, bool(condition)))

screens = {
    'Rebanho': 'lib/features/herd/presentation/screens/herd_overview_screen.dart',
    'Sanidade': 'lib/features/animal_health/presentation/screens/health_overview_screen.dart',
    'Reprodução': 'lib/features/animal_reproduction/presentation/screens/reproduction_overview_screen.dart',
    'Nutrição': 'lib/features/nutrition/presentation/screens/nutrition_overview_screen.dart',
    'Estoque': 'lib/features/farm_inventory/presentation/screens/farm_inventory_list_screen.dart',
    'Financeiro': 'lib/features/farm_finance/presentation/screens/farm_finance_list_screen.dart',
    'Agenda': 'lib/features/farm_agenda/presentation/screens/farm_agenda_list_screen.dart',
}
labels = {
    'Rebanho': 'Novo animal',
    'Sanidade': 'Novo evento sanitário',
    'Reprodução': 'Novo evento reprodutivo',
    'Nutrição': 'Nova dieta',
    'Estoque': 'Novo produto',
    'Financeiro': 'Novo lançamento',
    'Agenda': 'Novo compromisso',
}

for module, rel in screens.items():
    text = (ROOT / rel).read_text(encoding='utf-8')
    check(f'{module}: barra canônica', 'AtlasOperationalActionBar(' in text)
    check(f'{module}: ação principal', labels[module] in text)
    check(f'{module}: sem FAB concorrente', 'floatingActionButton:' not in text)
    check(f'{module}: atualização por pull', 'RefreshIndicator(' in text)

widget = (ROOT / 'lib/core/widgets/atlas_operational_action_bar.dart').read_text(encoding='utf-8')
check('barra responsiva', 'constraints.maxWidth < 560' in widget)
check('barra possui Atualizar', "Text('Atualizar')" in widget)
check('barra bloqueia ações durante carga', 'busy ? null' in widget)

bad = ('Ã§','Ã£','Ã©','Ã³','Ãª','Ã¡','Ã­','Ãº','Â')
hits = []
for path in (ROOT / 'lib').rglob('*.dart'):
    if '/presentation/' not in str(path).replace('\\','/'):
        continue
    text = path.read_text(encoding='utf-8', errors='ignore')
    if any(token in text for token in bad):
        hits.append(str(path.relative_to(ROOT)))
check('interface sem mojibake', not hits)

failed = [name for name, ok in checks if not ok]
print(f'ATLAS V20.7 MODULE CONSISTENCY: {len(checks)-len(failed)}/{len(checks)}')
for name in failed:
    print('FAIL:', name)
if hits:
    print('MOJIBAKE:', *hits, sep='\n- ')
raise SystemExit(1 if failed else 0)
