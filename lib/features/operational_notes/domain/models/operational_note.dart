class OperationalNote {
  const OperationalNote({
    required this.id,
    required this.farmId,
    required this.folderId,
    required this.authorUserId,
    required this.content,
    required this.source,
    required this.transcript,
    required this.createdAt,
  });

  final String id;
  final String farmId;
  final String? folderId;
  final String authorUserId;
  final String content;
  final String source;
  final String transcript;
  final DateTime? createdAt;

  bool get cameFromVoice => source == 'voice_transcription';

  factory OperationalNote.fromMap(Map<String, dynamic> map) => OperationalNote(
    id: map['id']?.toString() ?? '',
    farmId: map['farm_id']?.toString() ?? '',
    folderId: map['folder_id']?.toString(),
    authorUserId: map['author_user_id']?.toString() ?? '',
    content: map['content']?.toString() ?? '',
    source: map['source']?.toString() ?? 'text',
    transcript: map['transcript']?.toString() ?? '',
    createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '')?.toLocal(),
  );
}

class OperationalNoteFolder {
  const OperationalNoteFolder({
    required this.id,
    required this.farmId,
    required this.name,
  });

  final String id;
  final String farmId;
  final String name;

  factory OperationalNoteFolder.fromMap(Map<String, dynamic> map) =>
      OperationalNoteFolder(
        id: map['id']?.toString() ?? '',
        farmId: map['farm_id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
      );
}
