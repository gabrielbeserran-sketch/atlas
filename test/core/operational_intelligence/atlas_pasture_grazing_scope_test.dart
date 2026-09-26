import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_grazing_scope.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/models/atlas_enterprise_remote_session.dart';
import 'package:projeto_atlas/features/farm/domain/models/atlas_remote_farm.dart';

AtlasRemoteSession session({
  String company = 'company-a',
  String tenant = 'tenant-a',
  String role = 'worker',
  List<String> farmIds = const ['farm-a'],
}) => AtlasRemoteSession.fromMap({
  'access_token': 'token',
  'refresh_token': 'refresh',
  'user_id': 'user-a',
  'company_id': company,
  'tenant_id': tenant,
  'role': role,
  'farm_ids': farmIds,
});

const farm = AtlasRemoteFarm(
  id: 'farm-a',
  tenantId: 'tenant-a',
  companyId: 'company-a',
  name: 'Fazenda Atlas',
  city: 'Goiânia',
  state: 'GO',
  animals: 100,
  area: 60,
  active: true,
);

void main() {
  test('atalho exige o ID exato mesmo quando o nome coincide', () {
    for (final id in ['farm-b', '']) {
      expect(
        AtlasPastureGrazingScope.resolve(
          session: session(),
          activeFarmId: 'farm-a',
          portfolio: const [farm],
          expectedFarmName: farm.name,
          expectedFarmId: id,
        ),
        isNull,
      );
    }
    expect(
      AtlasPastureGrazingScope.resolve(
        session: session(),
        activeFarmId: 'farm-a',
        portfolio: const [farm],
        expectedFarmName: farm.name,
        expectedFarmId: farm.id,
      )?.id,
      farm.id,
    );
  });
  test('aceita só fazenda ativa da sessão e do contexto exibido', () {
    expect(
      AtlasPastureGrazingScope.resolve(
        session: session(),
        activeFarmId: 'farm-a',
        portfolio: const [farm],
        expectedFarmName: ' fazenda atlas ',
      )?.id,
      'farm-a',
    );
    expect(
      AtlasPastureGrazingScope.resolve(
        session: session(),
        activeFarmId: 'farm-a',
        portfolio: const [farm],
        expectedFarmName: 'Outra fazenda',
      ),
      isNull,
    );
  });

  test('recusa outra empresa, outro tenant e trabalhador sem acesso', () {
    for (final current in [
      session(company: 'company-b'),
      session(tenant: 'tenant-b'),
      session(farmIds: const ['farm-b']),
    ]) {
      expect(
        AtlasPastureGrazingScope.resolve(
          session: current,
          activeFarmId: 'farm-a',
          portfolio: const [farm],
        ),
        isNull,
      );
    }
  });

  test('sem sessão ou fazenda ativa não expõe base de pastejo', () {
    expect(
      AtlasPastureGrazingScope.resolve(
        session: null,
        activeFarmId: 'farm-a',
        portfolio: const [farm],
      ),
      isNull,
    );
    expect(
      AtlasPastureGrazingScope.resolve(
        session: session(),
        activeFarmId: null,
        portfolio: const [farm],
      ),
      isNull,
    );
  });
}
