import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';
import 'atlas_grazing_animals_service.dart';
import 'atlas_pasture_grazing_basis_service.dart';

class AtlasGrazingStockingResult {
  const AtlasGrazingStockingResult({
    required this.selectedCount,
    required this.coveredCount,
    required this.pendingAnimalIds,
    required this.ignoredLocalWeights,
    required this.reason,
    this.pendingReasons = const {},
    this.uaPerHa,
    this.totalWeightKg,
    this.oldestWeightDate,
    this.latestWeightDate,
  });
  final int selectedCount;
  final int coveredCount;
  final List<String> pendingAnimalIds;
  final int ignoredLocalWeights;
  final String reason;
  final Map<String, String> pendingReasons;
  final double? uaPerHa;
  final double? totalWeightKg;
  final DateTime? oldestWeightDate;
  final DateTime? latestWeightDate;
}

class AtlasGrazingStockingCalculator {
  const AtlasGrazingStockingCalculator();
  // Embrapa: peso vivo / 450 kg = UA. Janela é política do Atlas, não capacidade de suporte.
  static const kilogramsPerUa = 450.0;
  static const maximumWeightAgeDays = 90;

  DateTime? _date(String text) {
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(text.trim());
    if (match == null) return null;
    final day = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final year = int.parse(match[3]!);
    final value = DateTime.utc(year, month, day);
    return value.year == year && value.month == month && value.day == day
        ? value
        : null;
  }

  AtlasGrazingStockingResult calculate({
    required AtlasPastureGrazingBasis basis,
    required AtlasGrazingSelection? selection,
    required AtlasGrazingRoster? roster,
    required Map<String, List<AnimalWeightData>> weightsByAnimalId,
    required DateTime now,
    double? farmTotalAreaHa,
    bool hasUnresolvedBasisConflict = false,
  }) {
    AtlasGrazingStockingResult unavailable(String reason) =>
        AtlasGrazingStockingResult(
          selectedCount: selection?.animalIds.length ?? 0,
          coveredCount: 0,
          pendingAnimalIds: List.unmodifiable(selection?.animalIds ?? []),
          ignoredLocalWeights: 0,
          reason: reason,
        );
    try {
      basis.validate(farmTotalAreaHa: farmTotalAreaHa);
    } catch (_) {
      return unavailable('Base de pastejo inválida.');
    }
    if (hasUnresolvedBasisConflict) {
      return unavailable('Revise o conflito da base antes de calcular UA/ha.');
    }
    if (!basis.isCurrentAt(now)) {
      return unavailable('Atualize a confirmação da base de pastejo.');
    }
    if (selection == null ||
        !selection.basis.hasSameData(basis) ||
        selection.animalIds.length != basis.grazingAnimals ||
        selection.animalIds.toSet().length != selection.animalIds.length) {
      return unavailable(
        'Identifique os animais desta base antes de calcular.',
      );
    }
    if (now.isBefore(selection.recordedAt) ||
        now.difference(selection.recordedAt) > const Duration(days: 7) ||
        roster == null ||
        !roster.isCurrent(now)) {
      return unavailable('Atualize a carteira e a seleção dos animais.');
    }
    final activeIds = roster.animals
        .where((e) => e.active)
        .map((e) => e.id)
        .toSet();
    final today = DateTime.utc(now.year, now.month, now.day);
    final pending = <String>[];
    final pendingReasons = <String, String>{};
    var ignoredLocal = 0;
    var total = 0.0;
    DateTime? oldest;
    DateTime? latest;
    for (final id in selection.animalIds) {
      if (!activeIds.contains(id)) {
        pending.add(id);
        pendingReasons[id] = 'Animal ausente ou inativo na carteira atual.';
        continue;
      }
      final candidates = <(DateTime, double)>[];
      var localCount = 0;
      var invalidCount = 0;
      var oldCount = 0;
      for (final measurement in weightsByAnimalId[id] ?? <AnimalWeightData>[]) {
        if (!measurement.isRemote) {
          ignoredLocal++;
          localCount++;
          continue;
        }
        final date = _date(measurement.date);
        if (date == null ||
            date.isAfter(today) ||
            !measurement.weight.isFinite ||
            measurement.weight <= 0) {
          invalidCount++;
          continue;
        }
        if (today.difference(date).inDays > maximumWeightAgeDays) {
          oldCount++;
          continue;
        }
        candidates.add((date, measurement.weight));
      }
      if (candidates.isEmpty) {
        pending.add(id);
        final details = <String>[
          if (localCount > 0) '$localCount pesagem(ns) aguardando confirmação',
          if (oldCount > 0) '$oldCount pesagem(ns) com mais de 90 dias',
          if (invalidCount > 0)
            '$invalidCount pesagem(ns) com peso ou data inválidos/futuros',
        ];
        pendingReasons[id] = details.isEmpty
            ? 'Nenhuma pesagem confirmada disponível neste dispositivo.'
            : '${details.join('; ')}.';
        continue;
      }
      candidates.sort((a, b) => b.$1.compareTo(a.$1));
      final chosen = candidates.first;
      // O modelo legado só tem dia: duas medições diferentes no mesmo dia não têm ordem verificável.
      if (candidates.any((e) => e.$1 == chosen.$1 && e.$2 != chosen.$2)) {
        pending.add(id);
        pendingReasons[id] =
            'Pesos divergentes na última data; confira o histórico antes de calcular.';
        continue;
      }
      total += chosen.$2;
      if (oldest == null || chosen.$1.isBefore(oldest)) oldest = chosen.$1;
      if (latest == null || chosen.$1.isAfter(latest)) latest = chosen.$1;
    }
    final candidateUa = total / kilogramsPerUa / basis.effectiveAreaHa;
    final complete = pending.isEmpty && total.isFinite && candidateUa.isFinite;
    return AtlasGrazingStockingResult(
      selectedCount: selection.animalIds.length,
      coveredCount: selection.animalIds.length - pending.length,
      pendingAnimalIds: List.unmodifiable(pending),
      pendingReasons: Map.unmodifiable(pendingReasons),
      ignoredLocalWeights: ignoredLocal,
      uaPerHa: complete ? candidateUa : null,
      totalWeightKg: complete ? total : null,
      oldestWeightDate: oldest,
      latestWeightDate: latest,
      reason: complete
          ? 'Calculado com as últimas pesagens confirmadas, até 90 dias.'
          : pending.isNotEmpty
          ? 'Complete ou revise as pesagens dos animais indicados; não extrapolamos a amostra.'
          : 'Valores fora do intervalo calculável; revise área e pesos.',
    );
  }
}
