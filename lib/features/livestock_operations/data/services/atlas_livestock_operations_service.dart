import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:projeto_atlas/features/livestock_operations/domain/models/atlas_livestock_module_snapshot.dart';

class AtlasLivestockOperationsService {
  AtlasLivestockOperationsService({AtlasEnterpriseApiClient? api})
    : _api = api ?? AtlasEnterpriseApiClient.instance;

  final AtlasEnterpriseApiClient _api;

  Future<AtlasLivestockModuleSnapshot> load({
    required AtlasLivestockModule module,
    required String farmId,
  }) {
    switch (module) {
      case AtlasLivestockModule.reproduction:
        return _loadReproduction(farmId);
      case AtlasLivestockModule.health:
        return _loadHealth(farmId);
      case AtlasLivestockModule.nutrition:
        return _loadNutrition(farmId);
      case AtlasLivestockModule.inventory:
        return _loadInventory(farmId);
      case AtlasLivestockModule.finance:
        return _loadFinance(farmId);
    }
  }

  Future<AtlasLivestockModuleSnapshot> _loadReproduction(String farmId) async {
    final summary = await _api.request(
      'GET',
      '/livestock/reproduction/summary',
      queryParameters: <String, String>{'farm_id': farmId},
    );
    final upcoming = _maps(summary['upcoming_actions']);
    return AtlasLivestockModuleSnapshot(
      module: AtlasLivestockModule.reproduction,
      farmId: farmId,
      loadedAt: DateTime.now(),
      metrics: <AtlasMetricData>[
        AtlasMetricData(
          label: 'Fêmeas',
          value: _integer(summary['total_females']),
        ),
        AtlasMetricData(
          label: 'Prenhes',
          value: _integer(summary['pregnant_animals']),
        ),
        AtlasMetricData(
          label: 'Taxa de prenhez',
          value: _percent(summary['pregnancy_rate']),
        ),
        AtlasMetricData(
          label: 'Taxa de concepção',
          value: _percent(summary['conception_rate']),
        ),
        AtlasMetricData(
          label: 'Serviços',
          value: _integer(summary['services']),
        ),
        AtlasMetricData(label: 'Partos', value: _integer(summary['calvings'])),
      ],
      items: upcoming
          .map(
            (item) => AtlasModuleItemData(
              title: item['type']?.toString() ?? 'Ação reprodutiva',
              subtitle:
                  'Animal ${item['animal_id'] ?? ''} • ${item['due_at'] ?? ''}',
              status: 'pending',
              payload: item,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<AtlasLivestockModuleSnapshot> _loadHealth(String farmId) async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _api.requestList(
        'GET',
        '/livestock/health',
        queryParameters: <String, String>{'farm_id': farmId},
      ),
      _api.requestList(
        'GET',
        '/livestock/health/protocols',
        queryParameters: <String, String>{'farm_id': farmId},
      ),
      _api.requestList(
        'GET',
        '/livestock/health/alerts',
        queryParameters: <String, String>{'farm_id': farmId},
      ),
    ]);
    final events = results[0] as List<Map<String, dynamic>>;
    final protocols = results[1] as List<Map<String, dynamic>>;
    final alerts = results[2] as List<Map<String, dynamic>>;
    final withdrawal = events.where((event) {
      return _isFuture(event['withdrawal_meat_until']) ||
          _isFuture(event['withdrawal_milk_until']);
    }).length;
    return AtlasLivestockModuleSnapshot(
      module: AtlasLivestockModule.health,
      farmId: farmId,
      loadedAt: DateTime.now(),
      metrics: <AtlasMetricData>[
        AtlasMetricData(label: 'Eventos', value: '${events.length}'),
        AtlasMetricData(label: 'Protocolos', value: '${protocols.length}'),
        AtlasMetricData(label: 'Alertas', value: '${alerts.length}'),
        AtlasMetricData(label: 'Em carência', value: '$withdrawal'),
      ],
      items: <AtlasModuleItemData>[
        ...alerts.map(
          (item) => AtlasModuleItemData(
            title:
                item['message']?.toString() ??
                item['alert_type']?.toString() ??
                'Alerta sanitário',
            subtitle:
                item['animal_id']?.toString() ??
                item['lot_id']?.toString() ??
                '',
            status: item['severity']?.toString() ?? 'warning',
            payload: item,
          ),
        ),
        ...events
            .take(20)
            .map(
              (item) => AtlasModuleItemData(
                title: item['event_type']?.toString() ?? 'Evento sanitário',
                subtitle: item['occurred_at']?.toString() ?? '',
                status: 'registered',
                payload: item,
              ),
            ),
      ],
    );
  }

  Future<AtlasLivestockModuleSnapshot> _loadNutrition(String farmId) async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _api.request(
        'GET',
        '/livestock/nutrition/performance',
        queryParameters: <String, String>{'farm_id': farmId},
      ),
      _api.requestList(
        'GET',
        '/livestock/nutrition/ingredients',
        queryParameters: <String, String>{'farm_id': farmId},
      ),
      _api.requestList(
        'GET',
        '/livestock/nutrition/plans',
        queryParameters: <String, String>{'farm_id': farmId},
      ),
    ]);
    final performance = results[0] as Map<String, dynamic>;
    final ingredients = results[1] as List<Map<String, dynamic>>;
    final plans = results[2] as List<Map<String, dynamic>>;
    return AtlasLivestockModuleSnapshot(
      module: AtlasLivestockModule.nutrition,
      farmId: farmId,
      loadedAt: DateTime.now(),
      metrics: <AtlasMetricData>[
        AtlasMetricData(
          label: 'Eventos',
          value: _integer(performance['events']),
        ),
        AtlasMetricData(
          label: 'Consumo',
          value: '${_decimal(performance['total_quantity'])} kg',
        ),
        AtlasMetricData(
          label: 'Custo',
          value: _currency(performance['total_cost']),
        ),
        AtlasMetricData(
          label: 'GMD',
          value: '${_decimal(performance['average_daily_gain_kg'])} kg/dia',
        ),
        AtlasMetricData(label: 'Ingredientes', value: '${ingredients.length}'),
        AtlasMetricData(label: 'Planos', value: '${plans.length}'),
      ],
      items: plans
          .map(
            (item) => AtlasModuleItemData(
              title:
                  item['name']?.toString() ??
                  item['diet_name']?.toString() ??
                  'Plano nutricional',
              subtitle: item['description']?.toString() ?? '',
              status: item['active'] == false ? 'inactive' : 'active',
              payload: item,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<AtlasLivestockModuleSnapshot> _loadInventory(String farmId) async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _api.requestList(
        'GET',
        '/livestock/inventory/products',
        queryParameters: <String, String>{'farm_id': farmId},
      ),
      _api.requestList(
        'GET',
        '/livestock/inventory/alerts',
        queryParameters: <String, String>{
          'farm_id': farmId,
          'expiry_days': '30',
        },
      ),
    ]);
    final products = results[0] as List<Map<String, dynamic>>;
    final alerts = results[1] as List<Map<String, dynamic>>;
    final totalValue = products.fold<double>(0, (sum, item) {
      return sum + _number(item['quantity']) * _number(item['average_cost']);
    });
    return AtlasLivestockModuleSnapshot(
      module: AtlasLivestockModule.inventory,
      farmId: farmId,
      loadedAt: DateTime.now(),
      metrics: <AtlasMetricData>[
        AtlasMetricData(label: 'Produtos', value: '${products.length}'),
        AtlasMetricData(label: 'Alertas', value: '${alerts.length}'),
        AtlasMetricData(
          label: 'Valor em estoque',
          value: _currency(totalValue),
        ),
        AtlasMetricData(
          label: 'Sem estoque',
          value:
              '${alerts.where((item) => item['alert_type'] == 'out_of_stock').length}',
        ),
      ],
      items: <AtlasModuleItemData>[
        ...alerts.map(
          (item) => AtlasModuleItemData(
            title: item['product_name']?.toString() ?? 'Produto',
            subtitle: item['message']?.toString() ?? '',
            status:
                item['severity']?.toString() ??
                item['alert_type']?.toString() ??
                'warning',
            payload: item,
          ),
        ),
        ...products
            .take(30)
            .map(
              (item) => AtlasModuleItemData(
                title: item['name']?.toString() ?? 'Produto',
                subtitle:
                    'Quantidade: ${_decimal(item['quantity'])} • Mínimo: ${_decimal(item['minimum_quantity'])}',
                status: 'active',
                payload: item,
              ),
            ),
      ],
    );
  }

  Future<AtlasLivestockModuleSnapshot> _loadFinance(String farmId) async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _api.request(
        'GET',
        '/livestock/finance/summary',
        queryParameters: <String, String>{'farm_id': farmId},
      ),
      _api.requestList(
        'GET',
        '/livestock/finance/v2',
        queryParameters: <String, String>{'farm_id': farmId},
      ),
    ]);
    final summary = results[0] as Map<String, dynamic>;
    final entries = results[1] as List<Map<String, dynamic>>;
    return AtlasLivestockModuleSnapshot(
      module: AtlasLivestockModule.finance,
      farmId: farmId,
      loadedAt: DateTime.now(),
      metrics: <AtlasMetricData>[
        AtlasMetricData(label: 'Receitas', value: _currency(summary['income'])),
        AtlasMetricData(
          label: 'Despesas',
          value: _currency(summary['expense']),
        ),
        AtlasMetricData(
          label: 'Saldo realizado',
          value: _currency(summary['balance']),
        ),
        AtlasMetricData(
          label: 'Saldo projetado',
          value: _currency(summary['projected_balance']),
        ),
        AtlasMetricData(
          label: 'A receber',
          value: _currency(summary['receivable']),
        ),
        AtlasMetricData(label: 'A pagar', value: _currency(summary['payable'])),
      ],
      items: entries
          .take(40)
          .map((item) {
            final type = item['entry_type']?.toString() ?? '';
            return AtlasModuleItemData(
              title:
                  item['description']?.toString() ??
                  item['category']?.toString() ??
                  'Lançamento',
              subtitle:
                  '${type == 'income' ? 'Receita' : 'Despesa'} • ${_currency(item['amount'])}',
              status: item['status']?.toString() ?? 'pending',
              payload: item,
            );
          })
          .toList(growable: false),
    );
  }

  static List<Map<String, dynamic>> _maps(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static double _number(dynamic value) => (value as num?)?.toDouble() ?? 0;
  static String _integer(dynamic value) => '${(value as num?)?.toInt() ?? 0}';
  static String _decimal(dynamic value) => _number(value).toStringAsFixed(2);
  static String _percent(dynamic value) => '${_decimal(value)}%';
  static String _currency(dynamic value) =>
      'R\$ ${_number(value).toStringAsFixed(2)}';
  static bool _isFuture(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    return date != null && date.isAfter(DateTime.now());
  }
}
