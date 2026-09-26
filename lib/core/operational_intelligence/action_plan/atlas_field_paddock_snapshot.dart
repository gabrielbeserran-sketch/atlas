import 'package:projeto_atlas/features/paddock/domain/models/paddock_data.dart';

/// Referência somente de leitura; nunca importada como medições técnicas.
class AtlasFieldPaddockSnapshot {
  AtlasFieldPaddockSnapshot({
    required this.farmId,
    required this.loadedAt,
    required List<PaddockData> paddocks,
  }) : paddocks = List.unmodifiable(paddocks);
  final String farmId;
  final DateTime loadedAt;
  final List<PaddockData> paddocks;

  bool isAvailableFor(String? authorizedFarmId, DateTime now) =>
      farmId.isNotEmpty && farmId == authorizedFarmId && !loadedAt.isAfter(now);

  List<PaddockData> get uniquePaddocks {
    final counts = <String, int>{};
    for (final p in paddocks) {
      counts.update(p.id, (n) => n + 1, ifAbsent: () => 1);
    }
    return List.unmodifiable(
      paddocks.where((p) => p.id.trim().isNotEmpty && counts[p.id] == 1),
    );
  }

  int get ambiguousCount => paddocks.length - uniquePaddocks.length;
  int get invalidAreaCount =>
      uniquePaddocks.where((p) => !p.area.isFinite || p.area <= 0).length;
  double? get nominalAreaHa {
    final areas = uniquePaddocks
        .where((p) => p.area.isFinite && p.area > 0)
        .map((p) => p.area)
        .toList();
    if (areas.isEmpty) return null;
    final total = areas.fold(0.0, (a, b) => a + b);
    return total.isFinite ? total : null;
  }
}
