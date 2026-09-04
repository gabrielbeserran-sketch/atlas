import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/farm/data/services/atlas_farm_intelligence_snapshot_loader.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_agenda/domain/models/farm_agenda_data.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_finance_data.dart';
import 'package:projeto_atlas/features/farm_inventory/domain/models/farm_inventory_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/features/paddock/domain/models/paddock_data.dart';

void main() {
  const farm = FarmData(
    id: 'farm-1',
    name: 'Fazenda Atlas',
    city: 'Uberaba',
    state: 'MG',
    animals: 0,
    area: 120,
  );

  AtlasFarmIntelligenceSnapshotLoader loader({
    AtlasFarmSnapshotListLoader<HerdGroupData>? loadGroups,
    AtlasFarmSnapshotListLoader<PaddockData>? loadPaddocks,
    AtlasFarmSnapshotListLoader<AnimalData>? loadAnimals,
    AtlasFarmSnapshotListLoader<FarmFinanceData>? loadFinanceRecords,
    AtlasFarmSnapshotListLoader<FarmInventoryData>? loadInventoryItems,
    AtlasFarmSnapshotListLoader<FarmAgendaData>? loadAgendaTasks,
  }) => AtlasFarmIntelligenceSnapshotLoader(
    loadGroups: loadGroups ?? (_) async => <HerdGroupData>[],
    loadPaddocks: loadPaddocks ?? (_) async => <PaddockData>[],
    loadAnimals: loadAnimals ?? (_) async => <AnimalData>[],
    loadFinanceRecords: loadFinanceRecords ?? (_) async => <FarmFinanceData>[],
    loadInventoryItems:
        loadInventoryItems ?? (_) async => <FarmInventoryData>[],
    loadAgendaTasks: loadAgendaTasks ?? (_) async => <FarmAgendaData>[],
  );

  test(
    'forma um contexto único mesmo quando a fazenda ainda não tem dados',
    () async {
      final snapshot = await loader().load(farm);

      expect(snapshot.warnings, isEmpty);
      expect(snapshot.intelligence, isNotNull);
      expect(snapshot.diagnostic, isNotNull);
      expect(snapshot.aiContext, isNotNull);
      expect(snapshot.aiContext!.farmName, farm.name);
    },
  );

  test('isola falha de uma fonte sem apagar o contexto das demais', () async {
    final snapshot = await loader(
      loadPaddocks: (_) async => throw StateError('indisponível'),
    ).load(farm);

    expect(snapshot.paddocks, isEmpty);
    expect(snapshot.warnings, contains('piquetes'));
    expect(snapshot.intelligence, isNotNull);
    expect(snapshot.diagnostic, isNotNull);
    expect(snapshot.aiContext, isNotNull);
  });
}
