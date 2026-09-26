import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_grazing_animals_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_grazing_stocking_calculator.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_grazing_basis_service.dart';
import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_storage_service.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_enterprise_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final now = DateTime(2026, 9, 25, 12);
AtlasPastureGrazingBasis basis({double area = 10, DateTime? at}) =>
    AtlasPastureGrazingBasis(
      operationId: 'operation-1',
      tenantId: 't',
      companyId: 'c',
      farmId: 'f',
      effectiveAreaHa: area,
      grazingAnimals: 2,
      uniqueAreaConfirmed: true,
      recordedAt: at ?? now,
    );
AtlasGrazingSelection selection(
  AtlasPastureGrazingBasis b, {
  List<String>? ids,
  DateTime? at,
}) => AtlasGrazingSelection(b, ids ?? ['a', 'b'], at ?? now, now);
AtlasGrazingRoster roster({DateTime? at, bool activeB = true}) =>
    AtlasGrazingRoster([
      const AtlasGrazingCandidate('a', 'A', 'A', true),
      AtlasGrazingCandidate('b', 'B', 'B', activeB),
    ], at ?? now);
AnimalWeightData weight(
  double kg, {
  String date = '25/09/2026',
  bool confirmed = true,
}) => AnimalWeightData(
  id: 'weight-$kg-$date',
  date: date,
  weight: kg,
  notes: '',
  isRemote: confirmed,
);

class NoNetworkWeights extends AnimalWeightEnterpriseService {
  int calls = 0;
  @override
  Future<List<AnimalWeightData>> listWeights({required String animalId}) async {
    calls++;
    throw StateError('rede não deve ser consultada');
  }
}

void main() {
  AtlasGrazingStockingResult calculate(
    Map<String, List<AnimalWeightData>> weights, {
    AtlasPastureGrazingBasis? b,
    AtlasGrazingSelection? s,
    AtlasGrazingRoster? r,
    bool conflict = false,
    double? area,
  }) {
    final current = b ?? basis();
    return const AtlasGrazingStockingCalculator().calculate(
      basis: current,
      selection: s ?? selection(current),
      roster: r ?? roster(),
      weightsByAnimalId: weights,
      now: now,
      hasUnresolvedBasisConflict: conflict,
      farmTotalAreaHa: area,
    );
  }

  test(
    'pendências distinguem ausência, confirmação, idade e dados inválidos',
    () {
      final missing = calculate({});
      expect(missing.pendingReasons['a'], contains('Nenhuma pesagem'));
      final mixed = calculate({
        'a': [
          weight(450, confirmed: false),
          weight(450, date: '01/01/2026'),
          weight(-1),
        ],
        'b': [weight(450)],
      });
      expect(mixed.pendingReasons['a'], contains('aguardando confirmação'));
      expect(mixed.pendingReasons['a'], contains('mais de 90 dias'));
      expect(mixed.pendingReasons['a'], contains('inválidos'));
      expect(mixed.pendingReasons.containsKey('b'), isFalse);
      expect(mixed.uaPerHa, isNull);
      expect(
        () => mixed.pendingReasons['x'] = 'alterado',
        throwsUnsupportedError,
      );
    },
  );

  test('pendências distinguem inatividade e divergência na última data', () {
    final inactive = calculate({
      'b': [weight(450)],
    }, r: roster(activeB: false));
    expect(inactive.pendingReasons['b'], contains('inativo'));
    final conflict = calculate({
      'a': [weight(450), weight(460)],
      'b': [weight(450)],
    });
    expect(conflict.pendingReasons['a'], contains('divergentes'));
    expect(conflict.coveredCount, 1);
    expect(conflict.uaPerHa, isNull);
  });

  test('UA por hectare usa soma de pesos individuais e área efetiva', () {
    final result = calculate({
      'a': [weight(450)],
      'b': [weight(900)],
    });
    expect(result.uaPerHa, closeTo(0.3, 1e-10));
    expect(result.totalWeightKg, 1350);
    expect(result.coveredCount, 2);
    expect(result.pendingAnimalIds, isEmpty);
  });

  test('usa uma última pesagem por animal e não soma duplicações', () {
    final result = calculate({
      'a': [weight(300, date: '24/09/2026'), weight(450), weight(450)],
      'b': [weight(450)],
      'other': [weight(10000)],
    });
    expect(result.totalWeightKg, 900);
    expect(result.uaPerHa, closeTo(0.2, 1e-10));
    expect(result.oldestWeightDate, DateTime.utc(2026, 9, 25));
  });

  test('amostra parcial não vira índice completo', () {
    final result = calculate({
      'a': [weight(450)],
    });
    expect(result.coveredCount, 1);
    expect(result.pendingAnimalIds, ['b']);
    expect(result.uaPerHa, isNull);
    expect(result.totalWeightKg, isNull);
  });

  test(
    'ignora pendências locais, pesos inválidos, antigos e datas impossíveis',
    () {
      final result = calculate({
        'a': [weight(450)],
        'b': [
          weight(900, confirmed: false),
          weight(0),
          weight(double.nan),
          weight(double.infinity),
          weight(900, date: '26/09/2026'),
          weight(900, date: '31/02/2026'),
          weight(900, date: '26/06/2026'),
        ],
      });
      expect(result.ignoredLocalWeights, 1);
      expect(result.coveredCount, 1);
      expect(result.uaPerHa, isNull);
    },
  );

  test(
    '90 dias é limite operacional inclusivo, não recomendação de suporte',
    () {
      final result = calculate({
        'a': [weight(450, date: '27/06/2026')],
        'b': [weight(450)],
      });
      expect(result.coveredCount, 2);
      expect(result.uaPerHa, closeTo(0.2, 1e-10));
    },
  );

  test('animal inativo não é assumido em pastejo por ter peso', () {
    final result = calculate({
      'a': [weight(450)],
      'b': [weight(450)],
    }, r: roster(activeB: false));
    expect(result.pendingAnimalIds, ['b']);
    expect(result.uaPerHa, isNull);
  });

  test('duas pesagens diferentes no mesmo dia não têm ordem verificável', () {
    final result = calculate({
      'a': [weight(450), weight(460)],
      'b': [weight(450)],
    });
    expect(result.pendingAnimalIds, ['a']);
    expect(result.uaPerHa, isNull);
  });

  test('base seleção ou carteira desatualizada impede índice', () {
    final weights = {
      'a': [weight(450)],
      'b': [weight(450)],
    };
    for (final result in [
      calculate(weights, b: basis(at: now.subtract(const Duration(days: 8)))),
      calculate(weights, s: selection(basis(area: 20))),
      calculate(weights, s: selection(basis(), ids: ['a', 'a'])),
      calculate(
        weights,
        s: selection(basis(), at: now.add(const Duration(days: 1))),
      ),
      calculate(weights, r: roster(at: now.subtract(const Duration(days: 8)))),
      calculate(weights, conflict: true),
      calculate(weights, area: 5),
    ]) {
      expect(result.uaPerHa, isNull);
    }
  });

  test('overflow não produz infinito nem um índice enganoso', () {
    expect(
      calculate({
        'a': [weight(1e308)],
        'b': [weight(1e308)],
      }).uaPerHa,
      isNull,
    );
    expect(
      calculate({
        'a': [weight(450)],
        'b': [weight(450)],
      }, b: basis(area: 1e-308)).uaPerHa,
      isNull,
    );
  });

  test(
    'pesagens locais confirmadas usam IDs de empresa e fazenda sem chamar rede',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final network = NoNetworkWeights();
      final storage = AnimalWeightStorageService(
        companyId: 'c',
        farmId: 'f',
        enterprise: network,
      );
      await storage.saveWeights(
        farmName: 'nome antigo',
        groupName: 'lote antigo',
        animalId: 'a',
        weights: [weight(450)],
      );
      final loaded = await storage.loadWeights(
        farmName: 'nome novo',
        groupName: '',
        animalId: 'a',
        preferRemote: false,
      );
      expect(loaded.single.weight, 450);
      expect(network.calls, 0);
      final other = AnimalWeightStorageService(
        companyId: 'other',
        farmId: 'f',
        enterprise: network,
      );
      expect(
        await other.loadWeights(
          farmName: 'nome novo',
          groupName: '',
          animalId: 'a',
          preferRemote: false,
        ),
        isEmpty,
      );
    },
  );
}
