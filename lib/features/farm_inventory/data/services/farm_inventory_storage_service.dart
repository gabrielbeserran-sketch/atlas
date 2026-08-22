import 'dart:convert';

import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/core/text/atlas_text_normalizer.dart';
import 'package:projeto_atlas/features/farm_inventory/domain/models/farm_inventory_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FarmInventoryStorageService {
  FarmInventoryStorageService({AtlasHttpClient? httpClient})
    : _http = httpClient ?? AtlasHttpClient();

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final AtlasHttpClient _http;

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  String _createStorageKey(String farmName) =>
      'atlas_farm_inventory_${_normalize(farmName)}';

  Future<List<FarmInventoryData>> loadItems(
    String farmName, {
    String farmId = '',
  }) async {
    final key = _createStorageKey(farmName);
    final resolvedFarmId = farmId.trim().isNotEmpty
        ? farmId.trim()
        : await _resolveFarmId(farmName);
    if (resolvedFarmId.isNotEmpty) {
      try {
        final response = await _http.send(
          'GET',
          '/livestock/inventory/products',
          queryParameters: {'farm_id': resolvedFarmId},
        );
        final remote = response.asMapList();
        final cached = await _loadLocal(key);
        final cachedById = {for (final item in cached) item.id: item};
        final items = remote
            .map((map) => _fromApi(map, cachedById[map['id']?.toString()]))
            .toList();
        await _saveLocal(key, items);
        return items;
      } catch (_) {
        // Cache local mantém o módulo disponível em modo offline.
      }
    }
    return _loadLocal(key);
  }

  Future<FarmInventoryData> createItem({
    required String farmName,
    required String farmId,
    required FarmInventoryData item,
  }) async {
    final response = await _http.send(
      'POST',
      '/livestock/inventory/products/v2',
      body: _toApi(item, farmId),
    );
    final saved = _fromApi(response.asMap(), item);
    final verified = await _verifyProduct(
      farmId: farmId,
      productId: saved.id,
      fallback: saved,
    );
    await _upsertLocal(farmName, verified);
    return verified;
  }

  Future<FarmInventoryData> updateItem({
    required String farmName,
    required String farmId,
    required FarmInventoryData item,
  }) async {
    final response = await _http.send(
      'PATCH',
      '/livestock/inventory/products/${item.id}/v2',
      body: _toApi(item, farmId),
    );
    final saved = _fromApi(response.asMap(), item);
    final verified = await _verifyProduct(
      farmId: farmId,
      productId: saved.id,
      fallback: saved,
    );
    await _upsertLocal(farmName, verified);
    return verified;
  }

  Future<FarmInventoryData> registerMovement({
    required String farmName,
    required FarmInventoryData item,
    required FarmInventoryMovement movement,
    String referenceType = '',
    String referenceId = '',
  }) async {
    final response = await _http.send(
      'POST',
      '/livestock/inventory/products/${item.id}/movements/v2',
      body: {
        'movement_type': movement.type.toLowerCase().contains('entrada')
            ? 'entry'
            : 'exit',
        'quantity': movement.quantity,
        'unit_cost': movement.unitValue,
        'reason': movement.reason,
        'document_number': movement.document,
        'reference_type': referenceType,
        'reference_id': referenceId,
        'occurred_at': _dateToIso(movement.date),
      },
    );
    final movementMap = response.asMap();
    final updated = item.copyWith(
      quantity:
          (movementMap['balance_after'] as num?)?.toDouble() ?? item.quantity,
      movements: [movement, ...item.movements],
    );
    final farmId = await _resolveFarmId(farmName);
    final verifiedBase = farmId.isEmpty
        ? updated
        : await _verifyProduct(
            farmId: farmId,
            productId: item.id,
            fallback: updated,
          );
    final verified = verifiedBase.copyWith(
      movements: [movement, ...item.movements],
    );
    await _upsertLocal(farmName, verified);
    return verified;
  }

  Future<void> deleteItem({
    required String farmName,
    required String productId,
  }) async {
    await _http.send('DELETE', '/livestock/inventory/products/$productId/v2');
    final key = _createStorageKey(farmName);
    final items = await _loadLocal(key);
    items.removeWhere((item) => item.id == productId);
    await _saveLocal(key, items);
  }

  Future<void> saveItems({
    required String farmName,
    required List<FarmInventoryData> items,
  }) async => _saveLocal(_createStorageKey(farmName), items);

  Future<List<FarmInventoryData>> _loadLocal(String key) async {
    final raw = await _preferences.getString(key);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      return (AtlasTextNormalizer.normalize(jsonDecode(raw)) as List<dynamic>)
          .map(
            (item) => FarmInventoryData.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocal(String key, List<FarmInventoryData> items) =>
      _preferences.setString(
        key,
        jsonEncode(items.map((item) => item.toMap()).toList()),
      );

  Future<void> _upsertLocal(String farmName, FarmInventoryData item) async {
    final key = _createStorageKey(farmName);
    final items = await _loadLocal(key);
    final index = items.indexWhere((current) => current.id == item.id);
    if (index < 0) {
      items.add(item);
    } else {
      items[index] = item;
    }
    await _saveLocal(key, items);
  }

  Future<FarmInventoryData> _verifyProduct({
    required String farmId,
    required String productId,
    required FarmInventoryData fallback,
  }) async {
    final response = await _http.send(
      'GET',
      '/livestock/inventory/products',
      queryParameters: {'farm_id': farmId},
    );
    for (final map in response.asMapList()) {
      if (map['id']?.toString() == productId) {
        return _fromApi(map, fallback);
      }
    }
    throw StateError(
      'O produto não foi confirmado após nova leitura do servidor.',
    );
  }

  Future<String> _resolveFarmId(String farmName) async {
    try {
      final response = await _http.send('GET', '/farms');
      final normalized = farmName.trim().toLowerCase();
      for (final item in response.asMapList()) {
        if ((item['name']?.toString().trim().toLowerCase() ?? '') ==
            normalized) {
          return item['id']?.toString() ?? '';
        }
      }
    } catch (_) {}
    return '';
  }

  Map<String, dynamic> _toApi(FarmInventoryData item, String farmId) => {
    'farm_id': farmId,
    'sku': item.internalCode.isEmpty ? 'ATLAS-${item.id}' : item.internalCode,
    'name': item.name,
    'category': item.category,
    'unit': item.unit,
    'quantity': item.quantity,
    'minimum_quantity': item.minimumQuantity,
    'maximum_quantity': item.maximumQuantity,
    'average_cost': item.unitValue,
    'last_purchase_cost': item.lastPurchaseValue,
    'expiry_date': _dateToIso(item.expirationDate),
    'manufacturing_date': _dateToIso(item.manufacturingDate),
    'batch_number': item.batch,
    'supplier': item.supplier,
    'storage_location': item.storageLocation,
    'active_ingredient': item.activeIngredient,
    'barcode': item.barcode,
    'notes': item.notes,
  };

  FarmInventoryData _fromApi(
    Map<String, dynamic> map,
    FarmInventoryData? fallback,
  ) => FarmInventoryData(
    id: map['id']?.toString() ?? fallback?.id ?? '',
    name: map['name']?.toString() ?? fallback?.name ?? '',
    category: map['category']?.toString() ?? fallback?.category ?? 'Outro',
    quantity: (map['quantity'] as num?)?.toDouble() ?? fallback?.quantity ?? 0,
    minimumQuantity:
        (map['minimum_quantity'] as num?)?.toDouble() ??
        fallback?.minimumQuantity ??
        0,
    unit: map['unit']?.toString() ?? fallback?.unit ?? 'unidade',
    unitValue:
        (map['average_cost'] as num?)?.toDouble() ?? fallback?.unitValue ?? 0,
    expirationDate: _isoToDate(map['expiry_date']).isNotEmpty
        ? _isoToDate(map['expiry_date'])
        : (fallback?.expirationDate ?? ''),
    supplier: map['supplier']?.toString() ?? fallback?.supplier ?? '',
    batch: map['batch_number']?.toString() ?? fallback?.batch ?? '',
    notes: map['notes']?.toString() ?? fallback?.notes ?? '',
    internalCode: map['sku']?.toString() ?? fallback?.internalCode ?? '',
    barcode: map['barcode']?.toString() ?? fallback?.barcode ?? '',
    brand: fallback?.brand ?? '',
    manufacturer: fallback?.manufacturer ?? '',
    maximumQuantity:
        (map['maximum_quantity'] as num?)?.toDouble() ??
        fallback?.maximumQuantity ??
        0,
    lastPurchaseValue:
        (map['last_purchase_cost'] as num?)?.toDouble() ??
        fallback?.lastPurchaseValue ??
        0,
    manufacturingDate: _isoToDate(map['manufacturing_date']).isNotEmpty
        ? _isoToDate(map['manufacturing_date'])
        : (fallback?.manufacturingDate ?? ''),
    withdrawalDays: fallback?.withdrawalDays ?? 0,
    storageLocation:
        map['storage_location']?.toString() ?? fallback?.storageLocation ?? '',
    activeIngredient:
        map['active_ingredient']?.toString() ??
        fallback?.activeIngredient ??
        '',
    purchaseDocument: fallback?.purchaseDocument ?? '',
    lastInventoryDate: fallback?.lastInventoryDate ?? '',
    movements: fallback?.movements ?? const [],
  );

  String? _dateToIso(String value) {
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value.trim());
    if (match == null) {
      return DateTime.tryParse(value)?.toUtc().toIso8601String();
    }
    return DateTime(
      int.parse(match.group(3)!),
      int.parse(match.group(2)!),
      int.parse(match.group(1)!),
    ).toUtc().toIso8601String();
  }

  String _isoToDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) {
      return '';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
