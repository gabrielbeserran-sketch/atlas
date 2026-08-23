import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final center = File(
    'lib/features/consultancy_client/presentation/screens/'
    'atlas_client_consultancy_center_screen.dart',
  ).readAsStringSync();
  final widget = File(
    'lib/features/consultancy_client/presentation/widgets/'
    'atlas_monthly_bulletins_card.dart',
  ).readAsStringSync();
  final service = File(
    'lib/features/consultancy_client/data/services/'
    'atlas_monthly_bulletin_service.dart',
  ).readAsStringSync();

  test('Central da Consultoria exibe os três boletins mensais', () {
    expect(
      center.contains('AtlasMonthlyBulletinsCard(farm: widget.farm)'),
      isTrue,
    );
    expect(widget.contains('Boletins mensais no WhatsApp'), isTrue);
    expect(widget.contains('zootecnia'), isTrue);
    expect(widget.contains('operação/equipe'), isTrue);
    expect(widget.contains('financeiro'), isTrue);
  });

  test('ativação exige destinatário e autorização explícita', () {
    expect(widget.contains('WhatsApp do produtor'), isTrue);
    expect(
      widget.contains('Produtor autorizou o recebimento'),
      isTrue,
    );
    expect(widget.contains('Envio automático mensal'), isTrue);
  });

  test('Flutter usa backend e não agenda envio localmente', () {
    expect(service.contains("'/bulletins/schedules'"), isTrue);
    expect(service.contains("'/bulletins/provider-status'"), isTrue);
    expect(widget.contains('Timer.periodic'), isFalse);
    expect(widget.contains('SharedPreferences'), isFalse);
  });

  test('formulário usa API Flutter atual', () {
    expect(
      RegExp(
        r'DropdownButtonFormField<[^>]+>\(\s*\n\s*value:',
        multiLine: true,
      ).hasMatch(widget),
      isFalse,
    );
  });
}
