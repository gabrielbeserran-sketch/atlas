import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/atlas_consultancy_record.dart';

class AtlasConsultancyRepository {
  static const _key = 'atlas_consultancy_records_v1';

  Future<List<AtlasConsultancyRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      final seed = _seed();
      await save(seed);
      return seed;
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (e) => AtlasConsultancyRecord.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (_) {
      return _seed();
    }
  }

  Future<void> save(List<AtlasConsultancyRecord> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  List<AtlasConsultancyRecord> _seed() => [
    AtlasConsultancyRecord(
      id: 'client-1',
      clientName: 'Produtor Modelo',
      propertyName: 'Fazenda Horizonte',
      phone: '(61) 99999-0001',
      city: 'Brasília - DF',
      status: AtlasClientStatus.active,
      nextVisit: DateTime.now().add(const Duration(days: 7)),
      executiveScore: 82,
      openActions: 3,
      monthlyFee: 1800,
      notes: 'Priorizar reprodução e custo por arroba.',
    ),
    AtlasConsultancyRecord(
      id: 'client-2',
      clientName: 'Cliente Demonstração',
      propertyName: 'Fazenda Boa Esperança',
      phone: '(62) 99999-0002',
      city: 'Formosa - GO',
      status: AtlasClientStatus.attention,
      nextVisit: DateTime.now().add(const Duration(days: 2)),
      executiveScore: 64,
      openActions: 6,
      monthlyFee: 2200,
      notes: 'Revisar fluxo de caixa e calendário sanitário.',
    ),
  ];
}
