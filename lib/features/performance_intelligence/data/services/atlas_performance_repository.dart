import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/atlas_performance_kpi.dart';

class AtlasPerformanceRepository {
  AtlasPerformanceRepository._();
  static final AtlasPerformanceRepository instance =
      AtlasPerformanceRepository._();
  static const _key = 'atlas_performance_intelligence_kpis_v1';

  Future<List<AtlasPerformanceKpi>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      final seed = _seed();
      await saveAll(seed);
      return seed;
    }
    try {
      return (jsonDecode(raw) as List)
          .map(
            (e) => AtlasPerformanceKpi.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (_) {
      final seed = _seed();
      await saveAll(seed);
      return seed;
    }
  }

  Future<void> saveAll(List<AtlasPerformanceKpi> kpis) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(kpis.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> save(AtlasPerformanceKpi kpi) async {
    final all = await loadAll();
    final index = all.indexWhere((e) => e.id == kpi.id);
    if (index < 0) {
      all.add(kpi);
    } else {
      all[index] = kpi;
    }
    await saveAll(all);
  }

  Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((e) => e.id == id);
    await saveAll(all);
  }

  List<AtlasPerformanceKpi> _seed() {
    final now = DateTime.now();
    AtlasPerformanceKpi k(
      String id,
      String name,
      AtlasKpiCategory category,
      String unit,
      double current,
      double target,
      double previous,
      AtlasKpiDirection direction,
    ) => AtlasPerformanceKpi(
      id: id,
      farmId: '',
      name: name,
      category: category,
      unit: unit,
      currentValue: current,
      targetValue: target,
      previousValue: previous,
      direction: direction,
      updatedAt: now,
    );
    return <AtlasPerformanceKpi>[
      k(
        'kpi_prenhez',
        'Taxa de prenhez',
        AtlasKpiCategory.productive,
        '%',
        82,
        88,
        79,
        AtlasKpiDirection.higherIsBetter,
      ),
      k(
        'kpi_desmame',
        'Taxa de desmame',
        AtlasKpiCategory.productive,
        '%',
        76,
        82,
        74,
        AtlasKpiDirection.higherIsBetter,
      ),
      k(
        'kpi_gmd',
        'Ganho médio diário',
        AtlasKpiCategory.productive,
        'kg/dia',
        .61,
        .70,
        .58,
        AtlasKpiDirection.higherIsBetter,
      ),
      k(
        'kpi_mortalidade',
        'Mortalidade',
        AtlasKpiCategory.productive,
        '%',
        2.4,
        1.8,
        2.1,
        AtlasKpiDirection.lowerIsBetter,
      ),
      k(
        'kpi_margem',
        'Margem líquida',
        AtlasKpiCategory.financial,
        '%',
        17.5,
        20,
        15.8,
        AtlasKpiDirection.higherIsBetter,
      ),
      k(
        'kpi_custo_arroba',
        'Custo por arroba',
        AtlasKpiCategory.financial,
        'R\$/@',
        214,
        205,
        221,
        AtlasKpiDirection.lowerIsBetter,
      ),
      k(
        'kpi_spi',
        'SPI do plano estratégico',
        AtlasKpiCategory.operational,
        'índice',
        .91,
        1,
        .88,
        AtlasKpiDirection.higherIsBetter,
      ),
      k(
        'kpi_cpi',
        'CPI do plano estratégico',
        AtlasKpiCategory.operational,
        'índice',
        1.04,
        1,
        .98,
        AtlasKpiDirection.higherIsBetter,
      ),
      k(
        'kpi_okrs',
        'OKRs no ritmo esperado',
        AtlasKpiCategory.strategic,
        '%',
        68,
        80,
        64,
        AtlasKpiDirection.higherIsBetter,
      ),
    ];
  }
}
