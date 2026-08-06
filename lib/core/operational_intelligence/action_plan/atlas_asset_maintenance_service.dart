import 'dart:convert';

import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_asset_maintenance_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasAssetMaintenanceService {
  AtlasAssetMaintenanceService._();

  static final AtlasAssetMaintenanceService instance =
      AtlasAssetMaintenanceService._();

  static const String _assetsKey =
      'atlas_farm_assets_v1';
  static const String _ordersKey =
      'atlas_maintenance_orders_v1';
  static const String _usageKey =
      'atlas_asset_usage_records_v1';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<List<AtlasFarmAsset>> loadAssets({
    String? farmName,
  }) async {
    final all = await _decodeList(
      _assetsKey,
      AtlasFarmAsset.fromMap,
    );
    final filtered =
        _filterFarm(all, farmName, (item) => item.farmName)
          ..sort(
            (first, second) =>
                first.name.compareTo(second.name),
          );
    return filtered;
  }

  Future<void> saveAsset(AtlasFarmAsset asset) async {
    final all = await _decodeList(
      _assetsKey,
      AtlasFarmAsset.fromMap,
    );
    _upsert(all, asset, (item) => item.id);
    await _saveList(
      _assetsKey,
      all.map((item) => item.toMap()).toList(),
    );
  }

  Future<List<AtlasMaintenanceOrder>> loadOrders({
    String? farmName,
  }) async {
    final all = await _decodeList(
      _ordersKey,
      AtlasMaintenanceOrder.fromMap,
    );
    final filtered =
        _filterFarm(all, farmName, (item) => item.farmName)
          ..sort(
            (first, second) =>
                first.scheduledAt.compareTo(second.scheduledAt),
          );
    return filtered;
  }

  Future<void> saveOrder(
    AtlasMaintenanceOrder order,
  ) async {
    final all = await _decodeList(
      _ordersKey,
      AtlasMaintenanceOrder.fromMap,
    );
    _upsert(all, order, (item) => item.id);
    await _saveList(
      _ordersKey,
      all.map((item) => item.toMap()).toList(),
    );

    if (order.status == AtlasMaintenanceStatus.completed) {
      final assets = await _decodeList(
        _assetsKey,
        AtlasFarmAsset.fromMap,
      );
      final index = assets.indexWhere(
        (asset) => asset.id == order.assetId,
      );
      if (index != -1) {
        assets[index] = assets[index].copyWith(
          status: AtlasAssetStatus.available,
          hourMeter: order.hourMeterAtService > 0
              ? order.hourMeterAtService
              : assets[index].hourMeter,
          odometerKm: order.odometerAtServiceKm > 0
              ? order.odometerAtServiceKm
              : assets[index].odometerKm,
        );
        await _saveList(
          _assetsKey,
          assets.map((item) => item.toMap()).toList(),
        );
      }
    }
  }

  Future<List<AtlasAssetUsageRecord>> loadUsage({
    String? farmName,
  }) async {
    final all = await _decodeList(
      _usageKey,
      AtlasAssetUsageRecord.fromMap,
    );
    final filtered =
        _filterFarm(all, farmName, (item) => item.farmName)
          ..sort(
            (first, second) =>
                second.occurredAt.compareTo(first.occurredAt),
          );
    return filtered;
  }

  Future<void> saveUsage(
    AtlasAssetUsageRecord record,
  ) async {
    final all = await _decodeList(
      _usageKey,
      AtlasAssetUsageRecord.fromMap,
    );
    _upsert(all, record, (item) => item.id);
    await _saveList(
      _usageKey,
      all.map((item) => item.toMap()).toList(),
    );

    final assets = await _decodeList(
      _assetsKey,
      AtlasFarmAsset.fromMap,
    );
    final index = assets.indexWhere(
      (asset) => asset.id == record.assetId,
    );
    if (index != -1) {
      assets[index] = assets[index].copyWith(
        status: AtlasAssetStatus.available,
        hourMeter: record.endHourMeter >
                assets[index].hourMeter
            ? record.endHourMeter
            : assets[index].hourMeter,
        odometerKm: record.endOdometerKm >
                assets[index].odometerKm
            ? record.endOdometerKm
            : assets[index].odometerKm,
      );
      await _saveList(
        _assetsKey,
        assets.map((item) => item.toMap()).toList(),
      );
    }
  }

  AtlasAssetMaintenanceSummary buildSummary({
    required List<AtlasFarmAsset> assets,
    required List<AtlasMaintenanceOrder> orders,
    required List<AtlasAssetUsageRecord> usage,
  }) {
    final now = DateTime.now();
    final monthOrders = orders.where(
      (order) =>
          order.scheduledAt.year == now.year &&
          order.scheduledAt.month == now.month,
    );
    final monthUsage = usage.where(
      (record) =>
          record.occurredAt.year == now.year &&
          record.occurredAt.month == now.month,
    );
    final workedHours = monthUsage.fold<double>(
      0,
      (total, record) => total + record.workedHours,
    );
    final fuel = monthUsage.fold<double>(
      0,
      (total, record) => total + record.fuelLiters,
    );

    return AtlasAssetMaintenanceSummary(
      totalAssets:
          assets.where((asset) => asset.active).length,
      availableAssets: assets.where(
        (asset) =>
            asset.active &&
            asset.status == AtlasAssetStatus.available,
      ).length,
      assetsInMaintenance: assets.where(
        (asset) =>
            asset.active &&
            asset.status == AtlasAssetStatus.maintenance,
      ).length,
      stoppedAssets: assets.where(
        (asset) =>
            asset.active &&
            asset.status == AtlasAssetStatus.stopped,
      ).length,
      openOrders: orders.where((order) {
        return order.status !=
                AtlasMaintenanceStatus.completed &&
            order.status !=
                AtlasMaintenanceStatus.cancelled;
      }).length,
      overdueOrders:
          orders.where((order) => order.isOverdue).length,
      monthlyMaintenanceCost: monthOrders.fold<double>(
        0,
        (total, order) => total + order.totalCost,
      ),
      totalDowntimeHours: monthOrders.fold<double>(
        0,
        (total, order) => total + order.downtimeHours,
      ),
      monthlyFuelLiters: fuel,
      averageFuelPerHour:
          workedHours <= 0 ? 0 : fuel / workedHours,
      totalCurrentAssetValue: assets.fold<double>(
        0,
        (total, asset) => total + asset.currentValue,
      ),
    );
  }

  List<String> buildAlerts({
    required List<AtlasFarmAsset> assets,
    required List<AtlasMaintenanceOrder> orders,
  }) {
    final alerts = <String>[];
    final now = DateTime.now();

    for (final asset in assets) {
      if (asset.status == AtlasAssetStatus.stopped) {
        alerts.add(
          '${asset.name}: equipamento parado.',
        );
      }
    }

    for (final order in orders) {
      if (order.isOverdue) {
        alerts.add(
          '${order.title}: manutenção atrasada.',
        );
      }

      if (order.nextServiceAt != null) {
        final days =
            order.nextServiceAt!.difference(now).inDays;
        if (days >= 0 && days <= 15) {
          alerts.add(
            '${order.title}: próxima manutenção em $days dia(s).',
          );
        }
      }

      final asset = _findAsset(assets, order.assetId);
      if (asset != null &&
          order.nextServiceHourMeter > 0 &&
          asset.hourMeter >= order.nextServiceHourMeter) {
        alerts.add(
          '${asset.name}: revisão por horímetro vencida.',
        );
      }

      if (asset != null &&
          order.nextServiceOdometerKm > 0 &&
          asset.odometerKm >=
              order.nextServiceOdometerKm) {
        alerts.add(
          '${asset.name}: revisão por quilometragem vencida.',
        );
      }
    }

    if (alerts.isEmpty) {
      alerts.add(
        'Nenhum alerta crítico de máquinas e manutenção.',
      );
    }
    return alerts.toSet().toList();
  }

  Map<String, double> maintenanceCostByAsset({
    required List<AtlasFarmAsset> assets,
    required List<AtlasMaintenanceOrder> orders,
  }) {
    final result = <String, double>{};
    for (final asset in assets) {
      result[asset.name] = orders
          .where((order) => order.assetId == asset.id)
          .fold<double>(
            0,
            (total, order) => total + order.totalCost,
          );
    }
    result.removeWhere((_, value) => value <= 0);
    return result;
  }

  Map<String, double> fuelConsumptionByAsset({
    required List<AtlasFarmAsset> assets,
    required List<AtlasAssetUsageRecord> usage,
  }) {
    final result = <String, double>{};
    for (final asset in assets) {
      result[asset.name] = usage
          .where((record) => record.assetId == asset.id)
          .fold<double>(
            0,
            (total, record) => total + record.fuelLiters,
          );
    }
    result.removeWhere((_, value) => value <= 0);
    return result;
  }

  List<AtlasMaintenanceOrder> preventivePlan({
    required List<AtlasMaintenanceOrder> orders,
  }) {
    final result = orders.where((order) {
      return order.type == AtlasMaintenanceType.preventive ||
          order.type == AtlasMaintenanceType.predictive ||
          order.type == AtlasMaintenanceType.inspection ||
          order.type == AtlasMaintenanceType.calibration;
    }).toList()
      ..sort(
        (first, second) =>
            first.scheduledAt.compareTo(second.scheduledAt),
      );
    return result;
  }

  AtlasFarmAsset? _findAsset(
    List<AtlasFarmAsset> assets,
    String id,
  ) {
    for (final asset in assets) {
      if (asset.id == id) {
        return asset;
      }
    }
    return null;
  }

  Future<List<T>> _decodeList<T>(
    String key,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    final encoded = await _preferences.getString(key);
    if (encoded == null || encoded.trim().isEmpty) {
      return <T>[];
    }

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return decoded
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
    return _preferences.setString(
      key,
      jsonEncode(values),
    );
  }

  void _upsert<T>(
    List<T> values,
    T value,
    String Function(T) readId,
  ) {
    final id = readId(value);
    final index =
        values.indexWhere((item) => readId(item) == id);
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
    if (normalized == null || normalized.isEmpty) {
      return values;
    }

    return values.where((value) {
      return readFarm(value)?.trim().toLowerCase() ==
          normalized;
    }).toList();
  }
}
