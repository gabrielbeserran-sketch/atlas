import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/models/atlas_enterprise_remote_session.dart';

void main() {
  test('serializes the connected session', () {
    final session = AtlasRemoteSession.fromMap({
      'access_token': 'access',
      'refresh_token': 'refresh',
      'expires_in_seconds': 3600,
      'user_id': 'user',
      'user_name': 'Gabriel',
      'email': 'gabriel@example.com',
      'company_id': 'company',
      'tenant_id': 'tenant',
      'role': 'owner',
      'companies': <Map<String, dynamic>>[],
      'effective_permissions': ['herd.read'],
      'farm_ids': ['farm'],
    });

    expect(session.refreshToken, 'refresh');
    expect(session.allows('herd.read'), isTrue);
    expect(session.toMap()['companyId'], 'company');
  });

  test('companyAdministrator has unrestricted farm access', () {
    final session = AtlasRemoteSession.fromMap({
      'access_token': 'access',
      'refresh_token': 'refresh',
      'expires_in_seconds': 3600,
      'user_id': 'user',
      'user_name': 'Administrador Atlas',
      'email': 'admin@atlas.local',
      'company_id': 'company',
      'tenant_id': 'tenant',
      'role': 'companyAdministrator',
      'companies': <Map<String, dynamic>>[],
      'effective_permissions': <String>[],
      'farm_ids': ['farm_antiga'],
    });

    expect(session.hasUnrestrictedFarmAccess, isTrue);
    expect(session.allows('farms.update'), isTrue);
  });
}
