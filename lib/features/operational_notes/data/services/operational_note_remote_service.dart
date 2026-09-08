import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:projeto_atlas/features/operational_notes/domain/models/operational_note.dart';

class OperationalNoteRemoteService {
  OperationalNoteRemoteService({AtlasEnterpriseApiClient? api})
    : _api = api ?? AtlasEnterpriseApiClient.instance;

  final AtlasEnterpriseApiClient _api;

  Future<List<OperationalNote>> list(String farmId) async {
    final rows = await _api.requestList(
      'GET',
      '/operational-notes',
      queryParameters: {'farm_id': farmId},
    );
    return rows.map(OperationalNote.fromMap).toList(growable: false);
  }

  Future<OperationalNote> create({
    required String farmId,
    required String content,
    required bool cameFromVoice,
  }) async {
    final row = await _api.request(
      'POST',
      '/operational-notes',
      body: {
        'farm_id': farmId,
        'content': content,
        'source': cameFromVoice ? 'voice_transcription' : 'text',
        'transcript': cameFromVoice ? content : '',
      },
    );
    return OperationalNote.fromMap(row);
  }

  Future<bool> createAgendaTask({
    required String noteId,
    required String title,
    required String priority,
  }) async {
    final result = await _api.request(
      'POST',
      '/operational-notes/$noteId/task',
      body: {'title': title, 'priority': priority},
    );
    return result['created'] == true;
  }
}
