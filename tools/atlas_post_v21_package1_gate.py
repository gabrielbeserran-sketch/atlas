from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
animal = (ROOT / 'lib/features/animal/presentation/screens/animal_detail_screen.dart').read_text(encoding='utf-8')
handling = (ROOT / 'lib/features/farm_handling/domain/models/farm_handling_draft.dart').read_text(encoding='utf-8')

start = animal.find('class AnimalHubNavigation extends StatelessWidget')
end = animal.find('class NavigationModuleRow', start)
nav = animal[start:end] if start >= 0 and end > start else ''

checks = {
    'central 7 destinos': nav.count('value: AnimalHubSection.') == 7,
    'resumo': "'Resumo'" in nav,
    'historico': "'Histórico'" in nav,
    'desempenho': "'Desempenho'" in nav,
    'sanidade': "'Sanidade'" in nav,
    'reproducao': "'Reprodução'" in nav,
    'genealogia': "'Genealogia'" in nav,
    'arquivos': "'Arquivos'" in nav,
    'sem manejo': "'Manejo'" not in nav,
    'sem agenda': "'Agenda'" not in nav,
    'sem pendencias': "'Pendências'" not in nav,
    'sem mais recursos': "'Mais recursos'" not in nav,
    'sanidade direta': 'AnimalHubSection.healthEnterprise => buildHealthSection()' in animal,
    'reproducao direta': 'AnimalHubSection.reproductionEnterprise => buildReproductionSection()' in animal,
    'desempenho direto': 'AnimalHubSection.zootechnical => buildPerformanceSection()' in animal,
    'arquivos consolidados': 'Widget buildFilesSection()' in animal,
    'saude carregada como modelo canonico': 'List<AnimalHealthData> healthRecords' in animal,
    'manejo preparado por fazenda': 'required this.farmId' in handling,
    'manejo por lote': 'wholeLot' in handling,
    'manejo por intervalo brinco': 'earringRange' in handling,
    'manejo manual': 'manualSelection' in handling,
    'manejo rfid futuro': 'rfid' in handling,
    'manejo venda': 'saleOrExit' in handling,
    'manejo movimentacao': 'lotMovement' in handling,
    'manejo pesagem': 'weighing' in handling,
    'manejo sanidade': 'health' in handling,
    'manejo reproducao': 'reproduction' in handling,
}

failed = [name for name, ok in checks.items() if not ok]
print(f"ATLAS POST-V21 PACKAGE 1: {len(checks)-len(failed)}/{len(checks)}")
for name in failed:
    print('FAIL:', name)
sys.exit(1 if failed else 0)
