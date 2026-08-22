from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
shell=(ROOT/'lib/core/navigation/atlas_home_shell.dart').read_text(encoding='utf-8')
animal=(ROOT/'lib/features/animal/presentation/screens/animal_detail_screen.dart').read_text(encoding='utf-8')
agenda=(ROOT/'lib/features/farm_agenda/presentation/screens/farm_agenda_list_screen.dart').read_text(encoding='utf-8')
inventory=(ROOT/'lib/features/farm_inventory/presentation/screens/farm_inventory_list_screen.dart').read_text(encoding='utf-8')
finance=(ROOT/'lib/features/farm_finance/presentation/screens/farm_finance_list_screen.dart').read_text(encoding='utf-8')

checks=[]
def check(name, cond): checks.append((name,bool(cond)))

check('shell contém módulos operacionais', all(f"label: '{x}'" in shell for x in ['Fazendas','Rebanho','Sanidade','Reprodução','Nutrição','Financeiro','Estoque','Agenda']))
check('módulos dependentes declaram escopo de fazenda', "const farmScopedModules" in shell)
check('rebanho bloqueia sem fazenda', "selected.label == 'Rebanho'" in shell and "const _AtlasSelectFarmMessage()" in shell)
check('agenda bloqueia sem fazenda', "selected.label == 'Agenda'" in shell and "const _AtlasSelectFarmMessage()" in shell)
check('fazendas preserva detalhe canônico', "body = const FarmListScreen(embedded: true);" in shell)
check('dashboard usa contrato de navegação', '_handleRouteSelection(visibleRoutes, index);' in shell)
check('aviso de fazenda é orientador', "'Escolha uma fazenda para continuar'" in shell)
check('aviso explica vínculo dos dados', "'Os animais, registros e indicadores sempre pertencem à fazenda ativa.'" in shell)
check('central animal mantém ações de campo', "'O que você quer fazer?'" in animal)
check('central animal mantém status atual', '_AnimalCurrentSituation(' in animal)
check('agenda preserva barra canônica', 'AtlasOperationalActionBar(' in agenda)
check('estoque preserva barra canônica', 'AtlasOperationalActionBar(' in inventory)
check('financeiro preserva barra canônica', 'AtlasOperationalActionBar(' in finance)
check('shell preserva KeyedSubtree por fazenda', "ValueKey('${selected.label}:${farmId ?? 'none'}')" in shell)
route_start = shell.find("static final List<AtlasRouteDefinition> routes = [")
route_end = shell.find("\n  ];", route_start)
route_block = shell[route_start:route_end] if route_start >= 0 and route_end > route_start else ""
check('menu expõe manejo coletivo', "label: 'Realizar manejo'" in route_block)
check(
    'menu não expõe ferramentas técnicas',
    all(
        f"label: '{label}'" not in route_block
        for label in [
            'Precision Hub',
            'Enterprise',
            'SaaS',
            'Dados',
            'Segurança',
            'Qualidade',
            'Prontidão',
            'Releases',
            'Comercial',
            'Piloto',
            'Publicação',
            'Escala',
        ]
    ),
)

bad=('Ã§','Ã£','Ã©','Ã³','Ãª','Ã¡','Ã­','Ãº','Â')
check('shell sem mojibake', not any(x in shell for x in bad))

failed=[n for n,ok in checks if not ok]
print(f'ATLAS V20.10 INTEGRATED UX: {len(checks)-len(failed)}/{len(checks)}')
for n in failed: print('FAIL:',n)
raise SystemExit(1 if failed else 0)
