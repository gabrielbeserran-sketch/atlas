import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/security_camera/domain/models/atlas_security_camera_data.dart';

void main() {
  test('status da câmera preserva configuração de segurança', () {
    final status = AtlasSecurityCameraStatus.fromMap({
      'device_id': 'camera-1',
      'device_external_id': 'porteira-norte',
      'device_name': 'Entrada principal',
      'enabled': true,
      'recipient_whatsapp': '5561999999999',
      'whatsapp_opt_in_confirmed': true,
      'allowed_event_types': ['person', 'vehicle'],
      'cooldown_seconds': 60,
      'provider_ready': true,
      'ready': true,
    });

    expect(status.deviceId, 'camera-1');
    expect(status.personEnabled, isTrue);
    expect(status.vehicleEnabled, isTrue);
    expect(status.cooldownSeconds, 60);
    expect(status.ready, isTrue);
  });

  test('evento suprimido por anti-spam não oferece reenvio', () {
    final event = AtlasSecurityCameraEvent.fromMap({
      'id': 'event-1',
      'device_id': 'camera-1',
      'event_type': 'person',
      'alert_status': 'suppressed_cooldown',
      'attempt_count': 0,
      'error_message': '',
    });

    expect(event.canRetry, isFalse);
  });

  test('aplicativo usa a camada IoT consolidada e não a legada', () {
    final service = File(
      'lib/features/security_camera/data/services/'
      'atlas_security_camera_service.dart',
    ).readAsStringSync();
    final screen = File(
      'lib/features/precision_hub/presentation/screens/'
      'atlas_precision_hub_screen.dart',
    ).readAsStringSync();

    expect(service.contains('/security-camera/devices'), isTrue);
    expect(service.contains('/security-camera/readiness'), isTrue);
    expect(service.contains('/security-camera/events'), isTrue);
    expect(screen.contains('AtlasSecurityCameraCard('), isTrue);
    expect(service.contains('/iot/devices'), isFalse);
  });

  test('configuração exige opt-in e permite pessoa/veículo', () {
    final widget = File(
      'lib/features/security_camera/presentation/widgets/'
      'atlas_security_camera_card.dart',
    ).readAsStringSync();

    expect(
      widget.contains('Produtor autorizou os alertas no WhatsApp'),
      isTrue,
    );
    expect(
      widget.contains('Alertar quando detectar pessoa'),
      isTrue,
    );
    expect(
      widget.contains('Alertar quando detectar veículo'),
      isTrue,
    );
    expect(
      widget.contains('Intervalo mínimo entre alertas iguais'),
      isTrue,
    );
  });

  test('interface não finge detecção sem equipamento', () {
    final widget = File(
      'lib/features/security_camera/presentation/widgets/'
      'atlas_security_camera_card.dart',
    ).readAsStringSync();

    expect(
      widget.contains('não simula detecção sem hardware'),
      isTrue,
    );
  });

  test('card da câmera não depende de um modelo específico de fazenda', () {
    final widget = File(
      'lib/features/security_camera/presentation/widgets/'
      'atlas_security_camera_card.dart',
    ).readAsStringSync();
    final precision = File(
      'lib/features/precision_hub/presentation/screens/'
      'atlas_precision_hub_screen.dart',
    ).readAsStringSync();

    expect(widget.contains("features/farm/domain/models/farm_data.dart"), isFalse);
    expect(widget.contains('final FarmData farm;'), isFalse);
    expect(widget.contains('final String farmId;'), isTrue);
    expect(precision.contains('farmId: farm.id,'), isTrue);
    expect(precision.contains('farmName: farm.name,'), isFalse);
  });

}
