import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/dairy_production/domain/services/dairy_reproduction_indicator_calculator.dart';

void main() {
  test(
    'calcula DEL e concepção apenas de matrizes e eventos identificados',
    () {
      const calculator = DairyReproductionIndicatorCalculator();
      final cow = AnimalData(
        id: 'cow_1',
        tag: '101',
        name: 'Aurora',
        sex: 'Fêmea',
        breed: 'Nelore',
        birthDate: '01/01/2020',
        weight: 480,
        status: 'Ativo',
      );
      final result = calculator.calculate(
        animals: [cow],
        records: [
          const AnimalReproductionData(
            id: 'calving',
            type: 'Parto',
            date: '01/09/2026',
            result: '',
            bullOrSemen: '',
            responsible: '',
            notes: '',
            eventCode: 'calving',
            animalId: 'cow_1',
          ),
          const AnimalReproductionData(
            id: 'ai',
            type: 'IATF',
            date: '05/09/2026',
            result: '',
            bullOrSemen: '',
            responsible: '',
            notes: '',
            eventCode: 'iatf',
            animalId: 'cow_1',
          ),
          const AnimalReproductionData(
            id: 'preg',
            type: 'Diagnóstico de gestação',
            date: '15/09/2026',
            result: '',
            bullOrSemen: '',
            responsible: '',
            notes: '',
            eventCode: 'pregnancy_diagnosis',
            reproductiveStatus: 'pregnant',
            animalId: 'cow_1',
          ),
        ],
        referenceDate: DateTime(2026, 9, 15),
      );
      expect(result.averageDaysInMilk, 14);
      expect(result.lactatingCowsWithKnownCalving, 1);
      expect(result.conceptionRate, 100);
      expect(result.averageServicePeriodDays, 4);
      expect(result.averageAgeAtFirstCalvingDays, 2435);
      expect(result.pregnancyRateFromLatestDiagnosis, 100);
      expect(result.cowsWithPregnancyDiagnosis, 1);
      expect(result.replacementCoverageRate, isNull);
      expect(result.femaleEntries, 0);
      expect(result.dataCoveragePercent, 75);
      expect(result.recommendationConfidenceLabel, 'Confiança parcial');
    },
  );

  test(
    'calcula cobertura de reposição apenas com entradas e saídas datadas',
    () {
      const calculator = DairyReproductionIndicatorCalculator();
      final result = calculator.calculate(
        referenceDate: DateTime(2026, 9, 16),
        animals: [
          AnimalData(
            id: 'entry',
            tag: '1',
            name: 'Novilha',
            sex: 'Fêmea',
            breed: 'G',
            birthDate: '01/01/2024',
            weight: 300,
            status: 'Ativo',
            acquisitionDate: '20/09/2025',
          ),
          AnimalData(
            id: 'exit',
            tag: '2',
            name: 'Matriz',
            sex: 'Fêmea',
            breed: 'G',
            birthDate: '01/01/2020',
            weight: 480,
            status: 'Vendido',
            saleDate: '10/09/2026',
          ),
        ],
        records: const [],
      );
      expect(result.femaleEntries, 1);
      expect(result.femaleExits, 1);
      expect(result.replacementCoverageRate, 100);
      expect(result.dataCoveragePercent, 25);
      expect(result.recommendationConfidenceLabel, 'Confiança limitada');
    },
  );

  test('ignora eventos reprodutivos inválidos, futuros ou fora do período', () {
    const calculator = DairyReproductionIndicatorCalculator();
    final result = calculator.calculate(
      referenceDate: DateTime(2026, 9, 16),
      animals: [
        AnimalData(
          id: 'cow',
          tag: '1',
          name: 'Matriz',
          sex: 'Fêmea',
          breed: 'G',
          birthDate: '01/01/2020',
          weight: 480,
          status: 'Ativo',
        ),
      ],
      records: const [
        AnimalReproductionData(
          id: 'invalid',
          type: 'IATF',
          date: '31/02/2026',
          result: '',
          bullOrSemen: '',
          responsible: '',
          notes: '',
          eventCode: 'iatf',
          animalId: 'cow',
        ),
        AnimalReproductionData(
          id: 'future',
          type: 'IATF',
          date: '20/09/2026',
          result: '',
          bullOrSemen: '',
          responsible: '',
          notes: '',
          eventCode: 'iatf',
          animalId: 'cow',
        ),
        AnimalReproductionData(
          id: 'old',
          type: 'IATF',
          date: '01/09/2024',
          result: '',
          bullOrSemen: '',
          responsible: '',
          notes: '',
          eventCode: 'iatf',
          animalId: 'cow',
        ),
      ],
    );

    expect(result.inseminationAttempts, 0);
    expect(result.conceptionRate, isNull);
    expect(result.reproductiveEventsWithoutValidDate, 1);
    expect(result.reproductiveEventsInFuture, 1);
    expect(result.dataQualityAlerts.join(' '), contains('data válida'));
    expect(result.dataQualityAlerts.join(' '), contains('data futura'));
  });
}
