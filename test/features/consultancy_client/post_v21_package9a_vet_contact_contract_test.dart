import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/consultancy_client/domain/models/atlas_consultancy_contact_profile.dart';

void main() {
  test('perfil remoto só habilita WhatsApp quando configurado', () {
    final missing = AtlasConsultancyContactProfile.fromMap({
      'configured': false,
      'active': false,
      'display_name': '',
      'role': 'Veterinário responsável',
      'whatsapp_number': '',
      'company_label': '',
    });
    expect(missing.hasValidWhatsapp, isFalse);

    final ready = AtlasConsultancyContactProfile.fromMap({
      'configured': true,
      'active': true,
      'display_name': 'Veterinário',
      'role': 'Veterinário responsável',
      'whatsapp_number': '5561999999999',
      'company_label': 'Consultoria',
    });
    expect(ready.hasValidWhatsapp, isTrue);
  });

  test('contato da consultoria vem do backend e não do código Flutter', () {
    final service = File(
      'lib/features/consultancy_client/data/services/'
      'atlas_consultancy_contact_service.dart',
    ).readAsStringSync();

    expect(service.contains('/consultancy/contact'), isTrue);
    expect(service.contains('5561993886261'), isFalse);
    expect(service.contains('Gabriel Beserra do Nascimento'), isFalse);
  });

  test('central mantém WhatsApp visita resumo e gestão do responsável', () {
    final screen = File(
      'lib/features/consultancy_client/presentation/screens/'
      'atlas_client_consultancy_center_screen.dart',
    ).readAsStringSync();

    expect(screen.contains('Falar no WhatsApp'), isTrue);
    expect(screen.contains('Solicitar visita'), isTrue);
    expect(screen.contains('Enviar resumo'), isTrue);
    expect(screen.contains('Configurar responsável'), isTrue);
    expect(screen.contains('canManageContact'), isTrue);
  });

  test('home shell só libera edição a farms.update', () {
    final shell = File(
      'lib/core/navigation/atlas_home_shell.dart',
    ).readAsStringSync();

    expect(
      shell.contains("canManageContact: controller.allows('farms.update')"),
      isTrue,
    );
  });
}
