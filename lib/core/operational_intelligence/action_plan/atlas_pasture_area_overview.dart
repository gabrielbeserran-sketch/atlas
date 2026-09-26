import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_models.dart';

/// Resume registros de piquetes sem tratá-los como área efetiva de pastejo.
/// Piquetes podem se sobrepor ou estar fora de uso; a lotação exige uma base
/// de área confirmada separadamente pelo produtor.
class AtlasPastureAreaOverview {
  const AtlasPastureAreaOverview({
    required this.nominalAreaHa,
    required this.totalDryMatterKg,
    required this.weightedSupportAuHa,
    required this.validPaddockCount,
    required this.invalidPaddockCount,
    this.ambiguousPaddockCount = 0,
    this.dryMatterPaddockCount = 0,
    this.supportPaddockCount = 0,
  });

  final double? nominalAreaHa;
  final double? totalDryMatterKg;
  final double? weightedSupportAuHa;
  final int validPaddockCount;
  final int invalidPaddockCount;
  final int ambiguousPaddockCount;
  final int dryMatterPaddockCount;
  final int supportPaddockCount;
  bool get hasPartialDryMatter =>
      dryMatterPaddockCount > 0 && dryMatterPaddockCount < validPaddockCount;
  bool get hasPartialSupport =>
      supportPaddockCount > 0 && supportPaddockCount < validPaddockCount;
  bool get hasUncalculableValues =>
      (validPaddockCount > 0 && nominalAreaHa == null) ||
      (dryMatterPaddockCount > 0 && totalDryMatterKg == null) ||
      (supportPaddockCount > 0 && weightedSupportAuHa == null);

  factory AtlasPastureAreaOverview.fromPaddocks(List<AtlasPaddock> paddocks) {
    var area = 0.0;
    var dryMatter = 0.0;
    var supportArea = 0.0;
    var weightedSupport = 0.0;
    var valid = 0;
    var invalid = 0;
    var dryCount = 0;
    var supportCount = 0;
    var ambiguous = 0;
    final ids = <String, int>{};
    for (final paddock in paddocks) {
      ids.update(paddock.id, (count) => count + 1, ifAbsent: () => 1);
    }

    for (final paddock in paddocks) {
      if (paddock.id.trim().isEmpty || ids[paddock.id] != 1) {
        ambiguous++;
        continue;
      }
      final hectares = paddock.areaHectares;
      if (!hectares.isFinite || hectares <= 0) {
        invalid++;
        continue;
      }
      valid++;
      area += hectares;

      final dry = paddock.dryMatterKgHa;
      if (dry.isFinite && dry >= 0) {
        dryMatter += dry * hectares;
        dryCount++;
      }

      final support = paddock.supportCapacityAuHa;
      if (support.isFinite && support >= 0) {
        weightedSupport += support * hectares;
        supportArea += hectares;
        supportCount++;
      }
    }

    return AtlasPastureAreaOverview(
      nominalAreaHa: valid == 0 || !area.isFinite ? null : area,
      totalDryMatterKg: dryCount == 0 || !dryMatter.isFinite ? null : dryMatter,
      weightedSupportAuHa:
          supportArea == 0 || !supportArea.isFinite || !weightedSupport.isFinite
          ? null
          : weightedSupport / supportArea,
      validPaddockCount: valid,
      invalidPaddockCount: invalid,
      ambiguousPaddockCount: ambiguous,
      dryMatterPaddockCount: dryCount,
      supportPaddockCount: supportCount,
    );
  }
}
