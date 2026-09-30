import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/animal_health/domain/models/animal_health_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/services/reproduction_return_resolution.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_finance_data.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_farm_summary.dart';

TechnicalFarmSummary summary({
  List<AnimalReproductionData> reproduction = const [],
  List<AnimalHealthData> health = const [],
  List<FarmFinanceData> finances = const [],
  DateTime? referenceDate,
  DateTime? periodStart,
  DateTime? periodEnd,
}) => TechnicalFarmSummary.fromData(
  groups: const [],
  animals: const [],
  healthRecords: health,
  reproductionRecords: reproduction,
  nutritionPlans: const [],
  finances: finances,
  inventory: const [],
  referenceDate: referenceDate ?? DateTime(2026, 9, 30),
  periodStart: periodStart,
  periodEnd: periodEnd,
);

AnimalReproductionData event(String id, String expected) =>
    AnimalReproductionData(
      id: id,
      animalId: 'cow',
      date: '01/09/2026',
      expectedDate: expected,
      type: 'IATF',
      result: '',
      bullOrSemen: '',
      responsible: '',
      notes: '',
    );

void main() {
  test('painel usa triagem de retornos e ignora baixa confirmada', () {
    final resolved = ReproductionReturnResolution.resolve(
      event('baixado', '02/09/2026'),
      status: 'completed',
      responsible: 'Operador',
      at: DateTime.utc(2026, 9, 3),
    );
    final audit = resolved.metadata['atlas_return_resolution'] as Map;
    final confirmed = AnimalReproductionData.fromMap({
      ...resolved.toMap(),
      'metadata': {
        ...resolved.metadata,
        'atlas_return_resolution': {
          ...audit,
          'authenticated_user_id': 'server-user',
        },
      },
    });
    expect(confirmed.hasConfirmedReturnResolution, isTrue);

    final result = summary(
      reproduction: [
        confirmed,
        event('atrasado', '20/09/2026'),
        event('hoje', '30/09/2026'),
        event('impossivel', '31/02/2026'),
        event('repetido', '30/09/2026'),
        event(' repetido ', '30/09/2026'),
      ],
    );
    expect(result.overdueReproductionEvents, 1);
    expect(result.pendingReproductionEvents, 1);
    expect(result.totalAlerts, 1);
  });

  test('filtro mensal não converte datas impossíveis para março', () {
    FarmFinanceData finance(String id, String date, double amount) =>
        FarmFinanceData(
          id: id,
          type: 'Receita',
          category: 'Leite',
          date: date,
          description: id,
          amount: amount,
          paymentMethod: 'Dinheiro',
          notes: '',
        );
    AnimalHealthData treatment(String id, String date, double cost) =>
        AnimalHealthData(
          id: id,
          type: 'Tratamento',
          date: date,
          product: '',
          dose: '',
          responsible: '',
          notes: '',
          treatmentCost: cost,
        );
    final result = summary(
      referenceDate: DateTime(2026, 3, 15),
      periodStart: DateTime(2026, 3, 1),
      periodEnd: DateTime(2026, 3, 31),
      finances: [
        finance('valida', '2026-03-15', 100),
        finance('br-impossivel', '31/02/2026', 900),
        finance('iso-impossivel', '2026-02-30', 700),
      ],
      health: [
        treatment('valido', '15/03/2026', 10),
        treatment('impossivel', '31/02/2026', 90),
      ],
    );
    expect(result.income, 100);
    expect(result.healthRecords, 1);
    expect(result.healthCost, 10);
  });
}
