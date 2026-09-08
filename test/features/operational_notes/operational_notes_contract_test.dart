import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('anotações possuem uma cadeia única até a Agenda', () {
    final navigation = read('lib/core/navigation/atlas_home_shell.dart');
    final screen = read(
      'lib/features/operational_notes/presentation/screens/operational_notes_screen.dart',
    );
    final service = read(
      'lib/features/operational_notes/data/services/operational_note_remote_service.dart',
    );
    final router = read('backend/app/routers/operational_notes.py');
    final migration = read(
      'backend/alembic/versions/20260906_0052_operational_notes.py',
    );

    expect(navigation, contains("label: 'Anotações'"));
    expect(navigation, contains('OperationalNotesScreen(farm: farm, embedded: true)'));
    expect(screen, contains('DrBeserraVoiceService.instance'));
    expect(screen, contains('Criar compromisso na Agenda'));
    expect(service, contains("'/operational-notes'"));
    expect(service, contains("'/operational-notes/\$noteId/task'"));
    expect(router, contains('require_farm_scope'));
    expect(router, contains('record_audit'));
    expect(router, contains('source_type == "operational_note"'));
    expect(migration, contains('operational_notes'));
    expect(migration, contains('down_revision = "20260905_0051"'));
  });
}
