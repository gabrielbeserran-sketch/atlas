import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final voice = File(
    'lib/features/dr_beserra/data/services/'
    'dr_beserra_voice_service.dart',
  ).readAsStringSync();
  final screen = File(
    'lib/features/dr_beserra/presentation/screens/'
    'dr_beserra_screen.dart',
  ).readAsStringSync();
  final gateway = File(
    'lib/features/dr_beserra/data/services/'
    'dr_beserra_command_gateway.dart',
  ).readAsStringSync();
  final android = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();

  test('voz apenas transcreve e não grava dados de negócio', () {
    expect(voice.contains('SpeechToText()'), isTrue);
    expect(voice.contains('FarmAgendaStorageService'), isFalse);
    expect(voice.contains('AnimalHealthStorageService'), isFalse);
    expect(voice.contains('FarmHandlingEnterpriseService'), isFalse);
    expect(voice.contains('AtlasHttpClient'), isFalse);
  });

  test('resultado final de voz usa o mesmo sendText do teclado', () {
    expect(screen.contains('state.transcript'), isTrue);
    expect(screen.contains('sendText(lastVoiceFinal)'), isTrue);
    expect(screen.contains('gateway.interpret('), isTrue);
  });

  test('voz não possui escrita própria e usa o gateway compartilhado', () {
    expect(gateway.contains('FarmAgendaStorageService'), isTrue);
    expect(gateway.contains('confirmOperation('), isTrue);
    expect(voice.contains('FarmHandlingEnterpriseService'), isFalse);
    expect(voice.contains('AnimalHealthStorageService'), isFalse);
    expect(voice.contains('AnimalReproductionStorageService'), isFalse);
  });

  test('Android possui microfone e serviço de reconhecimento', () {
    expect(
      android.contains('android.permission.RECORD_AUDIO'),
      isTrue,
    );
    expect(
      android.contains('android.speech.RecognitionService'),
      isTrue,
    );
  });

  test('interface permite falar e parar de ouvir', () {
    expect(screen.contains('Icons.mic_outlined'), isTrue);
    expect(screen.contains('Icons.stop_circle_outlined'), isTrue);
    expect(screen.contains('Falar com Dr. Beserra'), isTrue);
  });
}
