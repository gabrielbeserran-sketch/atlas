import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final shell = File(
    'lib/core/navigation/atlas_home_shell.dart',
  ).readAsStringSync();
  final language = File(
    'lib/features/dr_beserra/domain/services/'
    'dr_beserra_language_service.dart',
  ).readAsStringSync();
  final gateway = File(
    'lib/features/dr_beserra/data/services/'
    'dr_beserra_command_gateway.dart',
  ).readAsStringSync();
  final screen = File(
    'lib/features/dr_beserra/presentation/screens/'
    'dr_beserra_screen.dart',
  ).readAsStringSync();

  test('Dr. Beserra é módulo oficial de Hoje e depende da fazenda', () {
    expect(shell.contains("label: 'Dr. Beserra'"), isTrue);
    expect(shell.contains("selected.label == 'Dr. Beserra'"), isTrue);
    expect(shell.contains('DrBeserraScreen('), isTrue);
  });

  test('linguagem aceita fala simples e variações do campo', () {
    for (final phrase in <String>[
      'trabaio de hoje',
      'o que e pra fazer hoje',
      'terminei',
      'acabei',
      'vacin',
      'vermifug',
      'iatf',
      'brete',
    ]) {
      expect(language.contains(phrase), isTrue);
    }
  });

  test('única escrita do 7A passa pela Agenda oficial e confirmação', () {
    expect(gateway.contains('FarmAgendaStorageService'), isTrue);
    expect(gateway.contains('_agenda.updateTask('), isTrue);
    expect(gateway.contains('confirmTaskCompletion('), isTrue);
    expect(gateway.contains('AtlasHttpClient'), isFalse);
    expect(gateway.contains('SharedPreferences'), isFalse);
  });

  test('capacidades posteriores preservam fronteira explícita de confirmação', () {
    expect(gateway.contains('confirmOperation('), isTrue);
    expect(gateway.contains('AtlasHttpClient'), isFalse);
    expect(gateway.contains('SharedPreferences'), isFalse);
  });

  test('interface confirma antes de concluir e não finge voz', () {
    expect(screen.contains('_ConfirmationBar'), isTrue);
    expect(screen.contains("Text('Confirmar')"), isTrue);
    expect(screen.contains('SpeechToText'), isFalse);
    expect(screen.contains('speech_to_text'), isFalse);
  });
}
