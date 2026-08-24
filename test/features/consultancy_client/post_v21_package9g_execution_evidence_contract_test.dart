import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('conclusao consultiva exige resultado e registra executor', () {
    final router = File('backend/app/routers/business.py').readAsStringSync();
    expect(router.contains('Informe o resultado executado antes de concluir a ação.'), isTrue);
    expect(router.contains('row.completed_by_user_id = principal.user.id'), isTrue);
    expect(router.contains('execution_evidence_json'), isTrue);
    expect(router.contains('record_audit('), isTrue);
  });

  test('Agenda nao conclui acao consultiva sem evidencia', () {
    final operations = File('backend/app/routers/operations.py').readAsStringSync();
    expect(operations.contains('requested_evidence'), isTrue);
    expect(operations.contains('Informe a evidência/resultado da execução'), isTrue);
    expect(operations.contains('action.completed_by_user_id = principal.user.id'), isTrue);
  });

  test('Central solicita evidencia real antes de concluir', () {
    final screen = File(
      'lib/features/consultancy_client/presentation/screens/'
      'atlas_client_consultancy_center_screen.dart',
    ).readAsStringSync();
    expect(screen.contains('Registrar execução'), isTrue);
    expect(screen.contains('Concluir com evidência'), isTrue);
    expect(screen.contains("actualResult: 'Concluída pela Central da Consultoria.'"), isFalse);
  });

  test('migration 0048 adiciona executor e evidencia estruturada', () {
    final migration = File(
      'backend/alembic/versions/20260824_0048_consultancy_execution_evidence.py',
    ).readAsStringSync();
    expect(migration.contains('revision = "20260824_0048"'), isTrue);
    expect(migration.contains('down_revision = "20260824_0047"'), isTrue);
    expect(migration.contains('completed_by_user_id'), isTrue);
    expect(migration.contains('execution_evidence_json'), isTrue);
  });
}
