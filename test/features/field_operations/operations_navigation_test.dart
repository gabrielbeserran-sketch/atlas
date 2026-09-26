import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/farm_operations/presentation/atlas_operations_navigation.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/models/atlas_enterprise_remote_session.dart';
import 'package:projeto_atlas/features/farm/domain/models/atlas_remote_farm.dart';

AtlasRemoteSession session({
  String role = 'worker',
  List<String> farms = const ['f'],
}) => AtlasRemoteSession(
  accessToken: 'test',
  refreshToken: 'test',
  expiresInSeconds: 3600,
  userId: 'u',
  userName: '',
  email: '',
  companyId: 'c',
  tenantId: 't',
  role: role,
  companies: const [],
  effectivePermissions: const {},
  farmIds: farms,
  savedAt: DateTime(2026, 9, 26),
);
AtlasRemoteFarm farm({
  String id = 'f',
  String company = 'c',
  String tenant = 't',
  bool active = true,
}) => AtlasRemoteFarm(
  id: id,
  companyId: company,
  tenantId: tenant,
  name: 'Fazenda',
  city: '',
  state: '',
  animals: 0,
  area: 10,
  active: active,
);
void main() {
  test(
    'fazenda explicitamente autorizada abre sem depender de PIN ou rede',
    () {
      expect(
        authorizedOperationsFarm(
          authenticated: true,
          session: session(),
          farm: farm(),
        ),
        'f',
      );
    },
  );
  test('sessão ausente e entrada não autenticada são recusadas', () {
    expect(
      authorizedOperationsFarm(
        authenticated: false,
        session: session(),
        farm: farm(),
      ),
      isNull,
    );
    expect(
      authorizedOperationsFarm(
        authenticated: true,
        session: null,
        farm: farm(),
      ),
      isNull,
    );
    expect(
      authorizedOperationsFarm(
        authenticated: true,
        session: session(),
        farm: null,
      ),
      isNull,
    );
  });
  test('outra fazenda, empresa, tenant ou inativa não abre', () {
    for (final target in [
      farm(id: 'outro'),
      farm(company: 'outra'),
      farm(tenant: 'outro'),
      farm(active: false),
      farm(id: ''),
    ]) {
      expect(
        authorizedOperationsFarm(
          authenticated: true,
          session: session(),
          farm: target,
        ),
        isNull,
      );
    }
  });
  test('administrador não ignora empresa ou tenant', () {
    expect(
      authorizedOperationsFarm(
        authenticated: true,
        session: session(role: 'owner', farms: []),
        farm: farm(),
      ),
      'f',
    );
    expect(
      authorizedOperationsFarm(
        authenticated: true,
        session: session(role: 'owner'),
        farm: farm(company: 'outra'),
      ),
      isNull,
    );
  });
  test('atalho antigo não abre fazenda diferente da ativa', () {
    expect(
      authorizedOperationsFarm(
        authenticated: true,
        session: session(),
        farm: farm(),
        expectedFarmId: 'antiga',
      ),
      isNull,
    );
  });
  testWidgets('sem contexto mostra aviso e não navega para lista global', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => openAuthorizedFarmOperations(context),
              child: const Text('Operações'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Operações'));
    await tester.pump();
    expect(
      find.text('Selecione uma fazenda autorizada antes de abrir Operações.'),
      findsOneWidget,
    );
  });
  test('as duas entradas usam navegação autorizada e Central exige fazenda', () {
    for (final path in [
      'lib/features/dashboard/presentation/screens/executive_dashboard_screen.dart',
      'lib/features/field_operations/presentation/screens/farm_field_center_screen.dart',
    ]) {
      expect(
        File(path).readAsStringSync(),
        contains('openAuthorizedFarmOperations(context'),
      );
      expect(
        File(path).readAsStringSync(),
        isNot(contains('AtlasOperationsCenterScreen(')),
      );
    }
    expect(
      File(
        'lib/features/farm_operations/presentation/screens/atlas_operations_center_screen.dart',
      ).readAsStringSync(),
      contains('required this.farmId'),
    );
  });
}
