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
  });

  final double? nominalAreaHa;
  final double? totalDryMatterKg;
  final double? weightedSupportAuHa;
  final int validPaddockCount;
  final int invalidPaddockCount;

  factory AtlasPastureAreaOverview.fromPaddocks(List<AtlasPaddock> paddocks) {
    var area = 0.0;
    var dryMatter = 0.0;
    var supportArea = 0.0;
    var weightedSupport = 0.0;
    var valid = 0;
    var invalid = 0;
    var hasDryMatter = false;

    for (final paddock in paddocks) {
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
        hasDryMatter = true;
      }

      final support = paddock.supportCapacityAuHa;
      if (support.isFinite && support >= 0) {
        weightedSupport += support * hectares;
        supportArea += hectares;
      }
    }

    return AtlasPastureAreaOverview(
      nominalAreaHa: valid == 0 ? null : area,
      totalDryMatterKg: hasDryMatter ? dryMatter : null,
      weightedSupportAuHa: supportArea == 0
          ? null
          : weightedSupport / supportArea,
      validPaddockCount: valid,
      invalidPaddockCount: invalid,
    );
  }
}
