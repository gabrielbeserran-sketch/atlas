import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/models/dr_beserra_command.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/services/dr_beserra_language_service.dart';

void main() {
  const language = DrBeserraLanguageService();

  test('entende rotina rural de hoje e amanhã', () {
    expect(
      language.parse('qual a lida de hoje').intent,
      DrBeserraIntent.todayTasks,
    );
    expect(
      language.parse('qual a lida de amanhã').intent,
      DrBeserraIntent.tomorrowTasks,
    );
  });

  test('entende sanidade e reprodução em linguagem de campo', () {
    expect(
      language.parse('preciso vermifugar o gado').intent,
      DrBeserraIntent.openHealth,
    );
    expect(
      language.parse('vamos fazer diagnóstico de gestação').intent,
      DrBeserraIntent.openReproduction,
    );
  });

  test('entende manejo, nutrição e campo', () {
    expect(
      language.parse('preciso pesar o lote').intent,
      DrBeserraIntent.openHandling,
    );
    expect(
      language.parse('como está o consumo no cocho').intent,
      DrBeserraIntent.openNutrition,
    );
    expect(
      language.parse('quero ver os piquetes').intent,
      DrBeserraIntent.openField,
    );
  });

  test('entende gestão e inteligência', () {
    expect(
      language.parse('quero ver os custos').intent,
      DrBeserraIntent.openFinance,
    );
    expect(
      language.parse('como está o estoque de insumos').intent,
      DrBeserraIntent.openInventory,
    );
    expect(
      language.parse('quero ver os indicadores').intent,
      DrBeserraIntent.openIntelligence,
    );
  });

  test('termos técnicos vencem palavras genéricas como gado e animal', () {
    expect(
      language.parse('preciso vermifugar o gado').intent,
      DrBeserraIntent.openHealth,
    );
    expect(
      language.parse('vamos vacinar os animais amanhã').intent,
      DrBeserraIntent.openHealth,
    );
    expect(
      language.parse('fazer inseminação no gado').intent,
      DrBeserraIntent.openReproduction,
    );
    expect(
      language.parse('diagnóstico de gestação das vacas').intent,
      DrBeserraIntent.openReproduction,
    );
    expect(
      language.parse('pesagem dos animais no brete').intent,
      DrBeserraIntent.openHandling,
    );
    expect(
      language.parse('ver o consumo de ração do gado').intent,
      DrBeserraIntent.openNutrition,
    );
  });

  test('variações verbais do campo continuam no módulo correto', () {
    expect(
      language.parse('vermifuguei os bezerros').intent,
      DrBeserraIntent.openHealth,
    );
    expect(
      language.parse('vacinamos as novilhas').intent,
      DrBeserraIntent.openHealth,
    );
    expect(
      language.parse('movimentar os bois para outro lote').intent,
      DrBeserraIntent.openHandling,
    );
    expect(
      language.parse('mover brincos 100 a 120 para lote recria').intent,
      DrBeserraIntent.openHandling,
    );
    expect(
      language.parse('suplementar as vacas no cocho').intent,
      DrBeserraIntent.openNutrition,
    );
  });

  test('entende consultoria e relatórios', () {
    expect(
      language.parse('quero falar com o veterinário').intent,
      DrBeserraIntent.openConsulting,
    );
    expect(
      language.parse('quero exportar o relatório').intent,
      DrBeserraIntent.openReports,
    );
  });
}
