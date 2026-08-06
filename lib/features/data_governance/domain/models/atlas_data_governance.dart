import 'dart:convert';

class AtlasBackupSnapshot {
  const AtlasBackupSnapshot({
    required this.id,
    required this.createdAt,
    required this.itemCount,
    required this.sizeBytes,
    required this.payload,
    required this.label,
  });

  final String id;
  final DateTime createdAt;
  final int itemCount;
  final int sizeBytes;
  final Map<String, dynamic> payload;
  final String label;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'itemCount': itemCount,
        'sizeBytes': sizeBytes,
        'payload': payload,
        'label': label,
      };

  factory AtlasBackupSnapshot.fromJson(Map<String, dynamic> json) {
    return AtlasBackupSnapshot(
      id: json['id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      itemCount: json['itemCount'] as int? ?? 0,
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      payload: Map<String, dynamic>.from(
        json['payload'] as Map<dynamic, dynamic>? ?? <String, dynamic>{},
      ),
      label: json['label'] as String? ?? 'Backup Atlas',
    );
  }

  String get formattedSize {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    }
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

class AtlasIntegrityCheck {
  const AtlasIntegrityCheck({
    required this.title,
    required this.description,
    required this.passed,
    required this.weight,
  });

  final String title;
  final String description;
  final bool passed;
  final int weight;
}

class AtlasDataGovernanceSummary {
  const AtlasDataGovernanceSummary({
    required this.backups,
    required this.checks,
    required this.lastBackupAt,
  });

  final List<AtlasBackupSnapshot> backups;
  final List<AtlasIntegrityCheck> checks;
  final DateTime? lastBackupAt;

  int get totalItems => backups.fold<int>(0, (sum, item) => sum + item.itemCount);

  int get integrityScore {
    final int totalWeight = checks.fold<int>(0, (sum, item) => sum + item.weight);
    if (totalWeight == 0) {
      return 0;
    }
    final int passedWeight = checks
        .where((item) => item.passed)
        .fold<int>(0, (sum, item) => sum + item.weight);
    return ((passedWeight / totalWeight) * 100).round();
  }
}
