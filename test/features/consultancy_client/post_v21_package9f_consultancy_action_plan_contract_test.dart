import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backend cria ação consultiva e tarefa oficial da Agenda', () {
    final router = File('backend/app/routers/business.py').readAsStringSync();
    expect(router.contains('source_type="consultancy_action"'), isTrue);
    expect(router.contains('source_id=row.id'), isTrue);
    expect(router.contains('idempotency_key'), isTrue);
    expect(router.contains('replayed=True'), isTrue);
  });

  test('Agenda devolve conclusão para o plano consultivo', () {
    final operations = File(
      'backend/app/routers/operations.py',
    ).readAsStringSync();
    expect(
      operations.contains('task.source_type == "consultancy_action"'),
      isTrue,
    );
    expect(operations.contains('action.status = task.status'), isTrue);
    expect(operations.contains('action.completed_at = task.completed_at'), isTrue);
  });

  test('Central da Consultoria consome plano persistente', () {
    final screen = File(
      'lib/features/consultancy_client/presentation/screens/'
      'atlas_client_consultancy_center_screen.dart',
    ).readAsStringSync();
    expect(screen.contains('AtlasConsultancyActionPlanCard'), isTrue);
    expect(screen.contains('createActionsFromPriorities'), isTrue);
    expect(screen.contains('completeConsultancyAction'), isTrue);
  });

  test('migration 0047 protege reenvio do mesmo plano', () {
    final migration = File(
      'backend/alembic/versions/'
      '20260824_0047_consultancy_action_idempotency.py',
    ).readAsStringSync();
    expect(migration.contains('revision = "20260824_0047"'), isTrue);
    expect(migration.contains('down_revision = "20260824_0046"'), isTrue);
    expect(migration.contains('uq_atlas_action_company_farm_idempotency'), isTrue);
  });
}
