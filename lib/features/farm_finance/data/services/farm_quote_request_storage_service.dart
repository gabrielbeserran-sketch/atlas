import 'dart:convert';

import 'package:projeto_atlas/features/farm_finance/domain/models/farm_quote_request.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FarmQuoteRequestStorageService {
  FarmQuoteRequestStorageService({Future<SharedPreferences>? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _preferences;

  String _key(String farmId) => 'atlas_finance_quotes_${farmId.trim()}';

  Future<List<FarmQuoteRequest>> load(String farmId) async {
    final raw = (await _preferences).getString(_key(farmId));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final values = jsonDecode(raw) as List<dynamic>;
      return values
          .whereType<Map>()
          .map(
            (item) => FarmQuoteRequest.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(String farmId, List<FarmQuoteRequest> requests) async {
    await (await _preferences).setString(
      _key(farmId),
      jsonEncode(requests.map((request) => request.toMap()).toList()),
    );
  }
}
