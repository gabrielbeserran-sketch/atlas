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
    },
  );
}
