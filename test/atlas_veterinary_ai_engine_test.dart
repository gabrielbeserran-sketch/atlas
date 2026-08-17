import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_veterinary_ai/domain/models/atlas_veterinary_case.dart';
import 'package:projeto_atlas/features/atlas_veterinary_ai/domain/services/atlas_veterinary_ai_engine.dart';

void main() {
  const engine = AtlasVeterinaryAiEngine();

  AtlasVeterinaryCase buildCase({
    List<String> symptoms = const [],
    double temperature = 38.5,
    int respiratoryRate = 25,
    int heartRate = 70,
    String hydration = 'Normal',
    String locomotion = 'Normal',
  }) {
    return AtlasVeterinaryCase(
      id: '1',
      date: '04/08/2026',
      title: 'Teste',
      status: 'Em avaliação',
      symptoms: symptoms,
      temperatureCelsius: temperature,
      heartRateBpm: heartRate,
      respiratoryRateBpm: respiratoryRate,
      appetite: 'Normal',
      hydration: hydration,
      locomotion: locomotion,
      durationHours: 12,
      notes: '',
      responsible: '',
      createdAt: '',
      updatedAt: '',
    );
  }

  test('identifies respiratory hypothesis', () {
    final result = engine.assess(
      buildCase(
        symptoms: const ['Tosse', 'Secreção nasal', 'Dificuldade respiratória'],
        temperature: 40,
        respiratoryRate: 65,
      ),
    );

    expect(result.hypotheses.first.name, 'Afecção respiratória');
    expect(result.triageScore, greaterThanOrEqualTo(40));
  });

  test('flags emergency red signs', () {
    final result = engine.assess(
      buildCase(
        temperature: 41,
        respiratoryRate: 70,
        heartRate: 130,
        hydration: 'Grave',
        locomotion: 'Não consegue ficar em pé',
      ),
    );

    expect(result.triageLevel, 'Emergência');
    expect(result.redFlags, isNotEmpty);
    expect(result.triageScore, inInclusiveRange(0, 100));
  });
}
