import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/models/dr_beserra_command.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/services/dr_beserra_language_service.dart';

void main() {
  const language = DrBeserraLanguageService();

  test('linguagem entende perguntas contextuais principais', () {
    expect(
      language.parse('o que merece atenção hoje?').intent,
      DrBeserraIntent.contextualAttention,
    );
    expect(
      language.parse('como estão as matrizes?').intent,
      DrBeserraIntent.matricesOverview,
    );
    expect(
      language.parse('qual lote está pior?').intent,
      DrBeserraIntent.worstLot,
    );
    expect(
      language.parse('o que está pesando no financeiro?').intent,
      DrBeserraIntent.financialPressure,
    );
  });

  test('inteligência contextual é somente leitura', () {
    final contextual = File(
      'lib/features/dr_beserra/data/services/'
      'dr_beserra_contextual_intelligence_service.dart',
    ).readAsStringSync();

    for (final forbidden in <String>[
      'createRecord(',
      'updateRecord(',
      'deleteRecord(',
      'savePlan(',
      'registerMovement(',
      'updateTask(',
      'createAnimal(',
      'updateAnimal(',
      'deleteAnimal(',
    ]) {
      expect(contextual.contains(forbidden), isFalse);
    }
  });

  test('resumo financeiro respeita ciclo e não sentencia vermelho', () {
    final contextual = File(
      'lib/features/dr_beserra/data/services/'
      'dr_beserra_contextual_intelligence_service.dart',
    ).readAsStringSync();

    expect(contextual.contains('ciclo pecuário'), isTrue);
    expect(
      contextual.contains(
        'não classifica o negócio como saudável ou inviável',
      ),
      isTrue,
    );
    expect(contextual.contains('Pressão financeira'), isTrue);
  });

  test('pior lote exige meta e ganho observado', () {
    final contextual = File(
      'lib/features/dr_beserra/data/services/'
      'dr_beserra_contextual_intelligence_service.dart',
    ).readAsStringSync();

    expect(contextual.contains('targetDailyGainKg > 0'), isTrue);
    expect(contextual.contains('observedDailyGainKg > 0'), isTrue);
    expect(
      contextual.contains('Não vou apontar um “pior lote” sem base.'),
      isTrue,
    );
  });

  test('matrizes não são inferidas sem classificação explícita', () {
    final contextual = File(
      'lib/features/dr_beserra/data/services/'
      'dr_beserra_contextual_intelligence_service.dart',
    ).readAsStringSync();

    expect(contextual.contains("category.contains('matriz')"), isTrue);
    expect(
      contextual.contains(
        'Sem essa classificação eu não vou inferir quais ',
      ),
      isTrue,
    );
    expect(
      contextual.contains('fêmeas devem entrar no resumo.'),
      isTrue,
    );
    expect(
      contextual.contains('_loadReproductionInBatches('),
      isTrue,
    );
  });

  test('gateway apresenta fontes e insuficiência de dados', () {
    final gateway = File(
      'lib/features/dr_beserra/data/services/'
      'dr_beserra_command_gateway.dart',
    ).readAsStringSync();

    expect(gateway.contains('_contextualReply('), isTrue);
    expect(gateway.contains("Fontes: \${insight.sources.join(', ')}."), isTrue);
    expect(
      gateway.contains('Dados insuficientes para uma conclusão mais forte.'),
      isTrue,
    );
  });

  test('camada de voz continua sem inteligência de negócio', () {
    final voice = File(
      'lib/features/dr_beserra/data/services/'
      'dr_beserra_voice_service.dart',
    ).readAsStringSync();

    expect(
      voice.contains('DrBeserraContextualIntelligenceService'),
      isFalse,
    );
    expect(voice.contains('FarmFinanceStorageService'), isFalse);
    expect(voice.contains('NutritionStorageService'), isFalse);
  });
}
