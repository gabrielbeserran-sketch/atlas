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

  Future<List<OperationalNoteFolder>> listFolders(String farmId) async {
    final rows = await _api.requestList(
      'GET',
      '/operational-notes/folders',
      queryParameters: {'farm_id': farmId},
    );
    return rows.map(OperationalNoteFolder.fromMap).toList(growable: false);
  }

  Future<OperationalNoteFolder> createFolder({
    required String farmId,
    required String name,
  }) async {
    final row = await _api.request(
      'POST',
      '/operational-notes/folders',
      body: {'farm_id': farmId, 'name': name},
    );
    return OperationalNoteFolder.fromMap(row);
  }

  Future<OperationalNote> create({
    required String farmId,
    required String content,
    required bool cameFromVoice,
    String? folderId,
  }) async {
    final row = await _api.request(
      'POST',
      '/operational-notes',
      body: {
        'farm_id': farmId,
        'content': content,
        'source': cameFromVoice ? 'voice_transcription' : 'text',
        'transcript': cameFromVoice ? content : '',
        'folder_id': folderId,
      },
    );
    return OperationalNote.fromMap(row);
  }

  Future<OperationalNote> moveToFolder({
    required String noteId,
    String? folderId,
  }) async {
    final row = await _api.request(
      'PATCH',
      '/operational-notes/$noteId/folder',
      body: {'folder_id': folderId},
    );
    return OperationalNote.fromMap(row);
  }

  Future<bool> delete(String noteId) async {
    final result = await _api.request('DELETE', '/operational-notes/$noteId');
    return result['agenda_task_preserved'] == true;
  }

  Future<int> deleteFolder(String folderId) async {
    final result = await _api.request('DELETE', '/operational-notes/folders/$folderId');
    return (result['notes_preserved'] as num?)?.toInt() ?? 0;
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
