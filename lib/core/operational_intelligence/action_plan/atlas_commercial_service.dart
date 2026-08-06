import 'dart:convert';

import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_commercial_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasCommercialService {
  AtlasCommercialService._();

  static final AtlasCommercialService instance =
      AtlasCommercialService._();

  static const String _partnersKey =
      'atlas_commercial_partners_v1';
  static const String _dealsKey =
      'atlas_commercial_deals_v1';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<List<AtlasCommercialPartner>> loadPartners({
    String? farmName,
  }) async {
    final values = await _decodeList(
      _partnersKey,
      AtlasCommercialPartner.fromMap,
    );
    return _filterFarm(values, farmName, (item) => item.farmName)
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> savePartner(
    AtlasCommercialPartner partner,
  ) async {
    final values = await _decodeList(
      _partnersKey,
      AtlasCommercialPartner.fromMap,
    );
    _upsert(values, partner, (item) => item.id);
    await _saveList(
      _partnersKey,
      values.map((item) => item.toMap()).toList(),
    );
  }

  Future<List<AtlasCommercialDeal>> loadDeals({
    String? farmName,
  }) async {
    final values = await _decodeList(
      _dealsKey,
      AtlasCommercialDeal.fromMap,
    );
    return _filterFarm(values, farmName, (item) => item.farmName)
      ..sort((a, b) => b.negotiatedAt.compareTo(a.negotiatedAt));
  }

  Future<void> saveDeal(AtlasCommercialDeal deal) async {
    final values = await _decodeList(
      _dealsKey,
      AtlasCommercialDeal.fromMap,
    );
    _upsert(values, deal, (item) => item.id);
    await _saveList(
      _dealsKey,
      values.map((item) => item.toMap()).toList(),
    );
  }

  Future<AtlasCommercialExecutiveSnapshot> buildSnapshot({
    String? farmName,
  }) async {
    final partners = await loadPartners(farmName: farmName);
    final deals = await loadDeals(farmName: farmName);

    final completedSales = deals.where(
      (item) =>
          item.type == AtlasCommercialDealType.sale &&
          item.status == AtlasCommercialDealStatus.completed,
    );
    final completedPurchases = deals.where(
      (item) =>
          item.type == AtlasCommercialDealType.purchase &&
          item.status == AtlasCommercialDealStatus.completed,
    );

    final salesRevenue = completedSales.fold<double>(
      0,
      (total, item) => total + item.grossValue,
    );
    final purchaseValue = completedPurchases.fold<double>(
      0,
      (total, item) => total + item.grossValue,
    );
    final margin = completedSales.fold<double>(
      0,
      (total, item) => total + item.marginValue,
    );
    final marginPercent = completedSales.isEmpty
        ? 0.0
        : completedSales.fold<double>(
              0,
              (total, item) => total + item.marginPercent,
            ) /
            completedSales.length;
    final open = deals.where(
      (item) =>
          item.status == AtlasCommercialDealStatus.prospecting ||
          item.status == AtlasCommercialDealStatus.negotiating ||
          item.status == AtlasCommercialDealStatus.contracted,
    ).length;

    var score = 50.0;
    score += marginPercent.clamp(-20, 30);
    score += partners.isNotEmpty ? 10 : 0;
    score += completedSales.isNotEmpty ? 10 : 0;
    score -= open > 10 ? 10 : 0;

    return AtlasCommercialExecutiveSnapshot(
      totalPartners: partners.length,
      openNegotiations: open,
      completedSales: completedSales.length,
      completedPurchases: completedPurchases.length,
      salesRevenue: salesRevenue,
      purchaseValue: purchaseValue,
      commercialMargin: margin,
      averageMarginPercent: marginPercent,
      commercialScore: score.clamp(0, 100),
    );
  }

  List<String> buildRecommendations({
    required AtlasCommercialExecutiveSnapshot snapshot,
    required List<AtlasCommercialDeal> deals,
  }) {
    final recommendations = <String>[];

    if (snapshot.totalPartners < 3) {
      recommendations.add(
        'Base comercial pequena. Cadastre novos compradores e fornecedores para reduzir dependência.',
      );
    }
    if (snapshot.averageMarginPercent > 0 &&
        snapshot.averageMarginPercent < 10) {
      recommendations.add(
        'Margem comercial média abaixo de 10%. Reforce negociação de preço, frete e condições.',
      );
    }
    if (snapshot.openNegotiations > 5) {
      recommendations.add(
        'Existem muitas negociações abertas. Priorize propostas com maior margem e probabilidade.',
      );
    }
    final delayed = deals.where(
      (item) =>
          item.deliveryAt != null &&
          item.deliveryAt!.isBefore(DateTime.now()) &&
          item.status != AtlasCommercialDealStatus.completed &&
          item.status != AtlasCommercialDealStatus.cancelled,
    ).length;
    if (delayed > 0) {
      recommendations.add(
        '$delayed negociação(ões) possuem entrega vencida.',
      );
    }
    if (snapshot.completedSales == 0) {
      recommendations.add(
        'Nenhuma venda concluída foi registrada. Use o funil comercial para acompanhar oportunidades.',
      );
    }
    if (recommendations.isEmpty) {
      recommendations.add(
        'A operação comercial está equilibrada. Continue comparando preços, margens e parceiros.',
      );
    }
    return recommendations;
  }

  AtlasCommercialPriceScenario simulatePrice({
    required double currentPrice,
    required double projectedPrice,
    required double quantity,
    required double costPerUnit,
  }) {
    return AtlasCommercialPriceScenario(
      currentPrice: currentPrice,
      projectedPrice: projectedPrice,
      quantity: quantity,
      costPerUnit: costPerUnit,
    );
  }

  Future<List<T>> _decodeList<T>(
    String key,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    final raw = await _preferences.getString(key);
    if (raw == null || raw.trim().isEmpty) return <T>[];
    try {
      return (jsonDecode(raw) as List)
          .map(
            (item) => fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <T>[];
    }
  }

  Future<void> _saveList(
    String key,
    List<Map<String, dynamic>> values,
  ) {
    return _preferences.setString(key, jsonEncode(values));
  }

  void _upsert<T>(
    List<T> values,
    T value,
    String Function(T) readId,
  ) {
    final index = values.indexWhere(
      (item) => readId(item) == readId(value),
    );
    if (index == -1) {
      values.add(value);
    } else {
      values[index] = value;
    }
  }

  List<T> _filterFarm<T>(
    List<T> values,
    String? farmName,
    String? Function(T) readFarm,
  ) {
    final normalized = farmName?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return values;
    return values.where((value) {
      return readFarm(value)?.trim().toLowerCase() ==
          normalized;
    }).toList();
  }
}
