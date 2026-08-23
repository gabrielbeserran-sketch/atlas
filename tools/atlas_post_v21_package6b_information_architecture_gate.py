from pathlib import Path
import re, sys

ROOT = Path(__file__).resolve().parents[1]
checks=[]
def check(name, ok, detail=''):
    checks.append((name,bool(ok),detail))

def text(rel): return (ROOT/rel).read_text(encoding='utf-8')

policy=text('lib/core/navigation/atlas_product_surface_policy.dart')
home=text('lib/core/navigation/atlas_home_shell.dart')
animal=text('lib/features/animal/presentation/screens/animal_detail_screen.dart')
intel=text('lib/features/atlas_intelligence_center/presentation/screens/atlas_intelligence_center_screen.dart')
finance=text('lib/features/farm_finance/presentation/screens/finance_overview_screen.dart')

owners=['Reprodução','Sanidade','Nutrição','Estoque','Financeiro','Campo','Inteligência','Relatórios','Consultoria']
for owner in owners:
    check(f'owner:{owner}', f"'{owner}'" in policy)

for forbidden in ['Agenda','Pendências','Nutrição','Financeiro','Estoque']:
    section=re.search(r'animalCenterSections\s*=\s*\{(.*?)\};',policy,re.S)
    check(f'animal-center-excludes:{forbidden}', section is not None and f"'{forbidden}'" not in section.group(1))

for allowed in ['Resumo','Histórico','Desempenho','Sanidade','Reprodução','Genealogia','Arquivos']:
    check(f'animal-center-keeps:{allowed}', f"'{allowed}'" in section.group(1) if section else False)

check('menu:analises-human-label', "menuLabel: 'Análises'" in home)
check('menu:offline-human-label', "menuLabel: 'Sem internet'" in home)
check('analysis:seven-domain-areas', intel.count('_AnalysisArea(') >= 7)
check('finance:cycle-aware-language', 'ciclo produtivo' in finance.lower())
check(
    'timeline:official-contract',
    '_enterpriseTimelineLoadLabel' in animal
    and "'Timeline Enterprise';" in animal
    and 'enterpriseTimelineService.loadTimeline(animal.id)' in animal
)
check('timeline:no-local-6s-timeout', 'Duration(seconds: 6)' not in animal)
check('timeline:no-local-8s-timeout', 'Duration(seconds: 8)' not in animal)
check('timeline:no-loader-timeout', 'return await loader().timeout(' not in animal)
check('timeline:official-loader-await', 'return await loader();' in animal)
check('timeline:fallback', 'List<T>.unmodifiable(fallback)' in animal)

# No development vocabulary in visible navigation labels.
visible_menu = re.findall(r"(?:label|menuLabel):\s*'([^']+)'", home)
for label in visible_menu:
    check(f'visible-label:{label}', not re.search(r'\b(?:Pacote|Marco|Etapa)\s*\d+', label, re.I), label)

failed=[c for c in checks if not c[1]]
for name,ok,detail in checks:
    print(f"[{'OK' if ok else 'FAIL'}] {name}" + (f' - {detail}' if detail else ''))
print(f'\nPASS: {len(checks)-len(failed)}')
print(f'FAIL: {len(failed)}')
if failed:
    sys.exit(1)
print('ATLAS POS-V21 PACOTE 6B: ARQUITETURA DE INFORMACAO APROVADA')
