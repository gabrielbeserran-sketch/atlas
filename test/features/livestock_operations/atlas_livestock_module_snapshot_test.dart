import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/livestock_operations/domain/models/atlas_livestock_module_snapshot.dart';

void main() {
  test('conta itens que exigem atenção', () {
    final snapshot = AtlasLivestockModuleSnapshot(
      module: AtlasLivestockModule.inventory,
      farmId: 'farm-1',
      loadedAt: DateTime(2026),
      metrics: const <AtlasMetricData>[],
      items: const <AtlasModuleItemData>[
        AtlasModuleItemData(title: 'A', status: 'critical'),
        AtlasModuleItemData(title: 'B', status: 'active'),
        AtlasModuleItemData(title: 'C', status: 'pending'),
      ],
    );
    expect(snapshot.attentionCount, 2);
  });
}
