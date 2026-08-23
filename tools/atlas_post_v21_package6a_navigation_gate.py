from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

route_def = (ROOT / 'lib/core/navigation/atlas_route_definition.dart').read_text(
    encoding='utf-8', errors='ignore'
)
shell = (ROOT / 'lib/core/navigation/atlas_home_shell.dart').read_text(
    encoding='utf-8', errors='ignore'
)
animal = (ROOT / 'lib/features/animal/presentation/screens/animal_detail_screen.dart').read_text(
    encoding='utf-8', errors='ignore'
)

errors: list[str] = []
total = 0

def check(name: str, condition: bool) -> None:
    global total
    total += 1
    if not condition:
        errors.append(name)

# Route definitions must be classified explicitly.
check('grupo de navegação não é obrigatório', 'required this.group' in route_def)
for token in (
    'AtlasNavigationGroup.today',
    'AtlasNavigationGroup.herd',
    'AtlasNavigationGroup.farm',
    'AtlasNavigationGroup.management',
    'AtlasNavigationGroup.support',
):
    check(f'grupo ausente: {token}', token in shell)

# Main producer menu uses task-oriented group labels, not a dumping ground.
for label in ('Hoje', 'Animais', 'Fazenda', 'Gestão', 'Apoio'):
    check(f'cabeçalho de navegação ausente: {label}', f"=> '{label}'" in route_def)
check("'Mais recursos' reapareceu no menu principal", "'Mais recursos'" not in shell)
check('menu ainda usa maturidade como organização visível', '_AtlasMaturityNotice' not in shell)
check('Inteligência não ganhou nome simples no menu', "menuLabel: 'Análises'" in shell)
check('Offline não ganhou nome simples no menu', "menuLabel: 'Sem internet'" in shell)
check('Dashboard não ganhou nome simples no menu', "menuLabel: 'Início'" in shell)
check('sidebar não usa visibleLabel', 'route.visibleLabel' in shell)
check('topbar não usa visibleLabel', 'title: selected.visibleLabel' in shell)

# Route classification contract. Identity label remains stable for navigation/tests.
expected = {
    'Dashboard': 'today',
    'Realizar manejo': 'today',
    'Agenda': 'today',
    'Dr. Beserra': 'today',
    'Rebanho': 'herd',
    'Sanidade': 'herd',
    'Reprodução': 'herd',
    'Fazendas': 'farm',
    'Campo': 'farm',
    'Nutrição': 'farm',
    'Estoque': 'farm',
    'Financeiro': 'management',
    'Inteligência': 'management',
    'Relatórios': 'management',
    'Offline': 'support',
    'Consultoria': 'support',
}
for label, group in expected.items():
    pattern = re.compile(
        rf"AtlasRouteDefinition\(\s*label: '{re.escape(label)}',(?:(?!AtlasRouteDefinition\().)*?group: AtlasNavigationGroup\.{group},",
        re.S,
    )
    check(f'rota {label} classificada incorretamente', bool(pattern.search(shell)))

# No build package/milestone numbering may leak anywhere in the Flutter app.
lib_texts = []
for dart in (ROOT / 'lib').rglob('*.dart'):
    lib_texts.append(dart.read_text(encoding='utf-8', errors='ignore'))
all_flutter = '\n'.join(lib_texts)
check(
    'app ainda expõe Pacote/Marco/Etapa numerado',
    re.search(r'\b(?:Pacote|Marco|Etapa)\s+\d+\b', all_flutter) is None,
)

# The producer menu must not expose build/maturity vocabulary.
for forbidden in ('V1 operacional', 'Avançado em validação', 'Fase ', 'Pacote ', 'Marco '):
    check(f'vocabulário de produção exposto no shell: {forbidden}', forbidden not in shell)

# Animal central visible navigation is intentionally small and animal-scoped.
nav_start = animal.find('class AnimalHubNavigation extends StatelessWidget')
nav_end = animal.find('class NavigationModuleRow', nav_start)
nav = animal[nav_start:nav_end] if nav_start >= 0 and nav_end > nav_start else ''
check('AnimalHubNavigation não localizado', bool(nav))
visible_labels = re.findall(r"label: '([^']+)'", nav)
check(
    f'Central do Animal deve ter 7 áreas, encontrou {len(visible_labels)}',
    visible_labels == [
        'Resumo',
        'Histórico',
        'Desempenho',
        'Sanidade',
        'Reprodução',
        'Genealogia',
        'Arquivos',
    ],
)
for forbidden in (
    'Agenda',
    'Pendências',
    'Nutrição',
    'Financeiro',
    'Estoque',
    'Fazenda',
    'Empresa',
    'Mais recursos',
):
    check(f'Central do Animal expõe área que não pertence ao animal: {forbidden}', f"'{forbidden}'" not in nav)

# Sanidade/Reprodução should render inline; no intermediate push from top navigation.
select_start = animal.find('Future<void> selectSection(AnimalHubSection section)')
select_end = animal.find('@override\n  Widget build', select_start)
if select_end < 0:
    select_end = animal.find('  @override\n  Widget build', select_start)
select_block = animal[select_start:select_end] if select_start >= 0 and select_end > select_start else ''
check('selectSection não localizado', bool(select_block))
check(
    'Sanidade ainda abre tela intermediária pelo seletor',
    'AnimalHubSection.healthEnterprise => AnimalHealthEnterpriseScreen' not in select_block,
)
check(
    'Reprodução ainda abre tela intermediária pelo seletor',
    'AnimalHubSection.reproductionEnterprise => AnimalReproductionEnterpriseScreen' not in select_block,
)
check(
    'Sanidade individual não possui conteúdo inline',
    'Widget buildHealthSection()' in animal and 'Novo evento sanitário' in animal,
)
check(
    'Reprodução individual não possui conteúdo inline',
    'Widget buildReproductionSection()' in animal and 'Novo evento reprodutivo' in animal,
)
check(
    'Central não explica navegação sem tela intermediária',
    'sem outra tela intermediária' in nav,
)

# User-facing central terminology cleanup.
for forbidden in ('Auditoria Enterprise', 'Timeline Enterprise Completa'):
    check(f'jargão Enterprise visível na central: {forbidden}', forbidden not in animal[3200:4150*2])

# Hygiene known regressions.
for name, text in [('route_def', route_def), ('shell', shell), ('animal', animal)]:
    check(
        f'{name}: mojibake',
        not any(token in text for token in ('Ã§', 'Ã£', 'Ã©', 'Ã³', 'Ãª', 'Ã¡', 'Ã­', 'Ãº', 'Â')),
    )
    check(
        f'{name}: DropdownButtonFormField(value:) depreciado',
        not re.search(r'DropdownButtonFormField<[^>]+>\(\s*\n\s*value:', text, re.S),
    )

if errors:
    print(f'ATLAS POST-V21 PACKAGE 6A NAVIGATION: {total-len(errors)}/{total}')
    for error in errors:
        print('-', error)
    sys.exit(1)

print(f'ATLAS POST-V21 PACKAGE 6A NAVIGATION: {total}/{total}')
