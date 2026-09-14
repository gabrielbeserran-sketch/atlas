import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('decisão de análises vira anotação rastreável e pode usar a Agenda existente', () {
    final center = read(
      'lib/features/atlas_intelligence_center/presentation/screens/atlas_intelligence_center_screen.dart',
    );
    final notes = read(
      'lib/features/operational_notes/data/services/operational_note_remote_service.dart',
    );
    final model = read(
      'lib/features/operational_notes/domain/models/operational_note.dart',
    );

    expect(center, contains('Salvar em Anotações'));
    expect(center, contains("source: 'intelligence_decision'"));
    expect(center, contains("referenceType: 'ai_recommendation'"));
    expect(center, contains('referenceId: item.id'));
    expect(notes, contains("'reference_type': referenceType"));
    expect(notes, contains("'reference_id': referenceId"));
    expect(notes, contains(r"'/operational-notes/$noteId/task'"));
    expect(model, contains('final String referenceType;'));
    expect(model, contains('final String referenceId;'));
  });
}
