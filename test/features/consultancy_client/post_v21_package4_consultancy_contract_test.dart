import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final shell = File(
    'lib/core/navigation/atlas_home_shell.dart',
  ).readAsStringSync();
  final screen = File(
    'lib/features/consultancy_client/presentation/screens/'
    'atlas_client_consultancy_center_screen.dart',
  ).readAsStringSync();
  final contact = File(
    'lib/features/consultancy_client/data/services/'
    'atlas_consultancy_contact_service.dart',
  ).readAsStringSync();
  final whatsapp = File(
    'lib/features/consultancy_client/data/services/'
    'atlas_consultancy_whatsapp_service.dart',
  ).readAsStringSync();
  final profile = File(
    'lib/features/consultancy_client/domain/models/'
    'atlas_consultancy_contact_profile.dart',
  ).readAsStringSync();

  test('Consultoria é um módulo real vinculado à fazenda', () {
    expect(shell.contains("label: 'Consultoria'"), isTrue);
    expect(
      shell.contains('AtlasClientConsultancyCenterScreen('),
      isTrue,
    );
    expect(shell.contains('AtlasConsultancyDashboard'), isFalse);
  });

  test('cliente fala diretamente com veterinário responsável', () {
    expect(screen.contains("'Falar no WhatsApp'"), isTrue);
    expect(screen.contains("'Solicitar visita'"), isTrue);
    expect(screen.contains("'Enviar resumo'"), isTrue);
    expect(screen.contains('whatsAppService.openConversation('), isTrue);
    expect(screen.contains('contact.role'), isTrue);
    expect(screen.contains('contact.displayName'), isTrue);
    expect(contact.contains("'/consultancy/contact'"), isTrue);
    expect(contact.contains('loadForFarm('), isTrue);
    expect(profile.contains("'Veterinário responsável'"), isTrue);
  });

  test('WhatsApp usa link seguro e mensagem codificada', () {
    expect(whatsapp.contains("'wa.me'"), isTrue);
    expect(whatsapp.contains('Uri.https('), isTrue);
    expect(whatsapp.contains("{'text': cleanMessage}"), isTrue);
  });

  test('Consultoria usa dados oficiais sem CRM local paralelo', () {
    expect(
      screen.contains('AtlasOperationalIntelligenceService'),
      isTrue,
    );
    expect(screen.contains('FarmAgendaStorageService'), isTrue);
    expect(screen.contains('SharedPreferences'), isFalse);
    expect(screen.contains('consultancy_hub'), isFalse);
  });

  test('mensagem exige ação humana antes do envio', () {
    expect(
      screen.contains('O Atlas não envia mensagens sem a sua ação'),
      isTrue,
    );
  });
}
