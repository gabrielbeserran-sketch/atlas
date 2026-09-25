import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/auth/atlas_offline_pin_service.dart';
import 'package:projeto_atlas/core/session/atlas_session_controller.dart';
import 'package:projeto_atlas/core/session/atlas_session_scope.dart';
import 'package:projeto_atlas/core/settings/atlas_settings_screen.dart';
import 'package:projeto_atlas/core/subscription/atlas_subscription_service.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _SubscriptionApi implements AtlasEnterpriseApiClient {
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool authenticated = true,
  }) async => const <String, dynamic>{};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('PIN divergente não fecha diálogo nem finge ter sido salvo', (
    tester,
  ) async {
    final controller = AtlasSessionController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: AtlasSessionScope(
          controller: controller,
          child: AtlasSettingsScreen(
            subscriptionService: AtlasSubscriptionService(
              api: _SubscriptionApi(),
            ),
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Configurar PIN offline').last);
    await tester.tap(find.text('Configurar PIN offline').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '123456');
    await tester.enterText(find.byType(TextField).at(1), '654321');
    await tester.tap(find.text('Confirmar'));
    await tester.pump();

    expect(
      find.text('Os dois PINs não coincidem. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.text('Confirmar PIN'), findsOneWidget);
    expect(await AtlasOfflinePinService.instance.isConfigured, isFalse);

    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(await AtlasOfflinePinService.instance.verify('123456'), isTrue);
    expect(controller.offlinePinConfigured, isTrue);
    expect(find.text('PIN offline configurado'), findsOneWidget);
    expect(find.text('PIN offline salvo neste dispositivo.'), findsOneWidget);
  });
}
