import 'package:projeto_atlas/features/dairy_production/data/services/dairy_offline_stage_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_remote_lookup_service.dart';

enum DairyRemoteReviewStatus {
  localReview,
  absentOnServer,
  sameOnServer,
  differsOnServer,
  deletedOnServer,
}

class DairyRemoteReviewReport {
  const DairyRemoteReviewReport(this.entries);

  final List<DairyRemoteReviewEntry> entries;

  List<DairyRemoteReviewStatus> get statuses =>
      entries.map((entry) => entry.status).toList(growable: false);

  int count(DairyRemoteReviewStatus status) =>
      statuses.where((value) => value == status).length;
}

class DairyRemoteReviewEntry {
  const DairyRemoteReviewEntry({
    required this.local,
    required this.remote,
    required this.status,
  });

  final DairyReviewItem local;
  final DairyRemoteState remote;
  final DairyRemoteReviewStatus status;
}

/// A read-only comparison of one exact lookup with an unchanged local stage.
/// This never authorizes promotion into the sync queue.
class DairyRemoteReconciliation {
  static DairyRemoteReviewReport compare({
    required DairyReviewReport before,
    required DairyReviewReport after,
    required List<DairyRemoteState> remote,
  }) {
    if (before.items.length != after.items.length ||
        after.items.length != remote.length) {
      throw StateError('Os registros de Leite mudaram durante a consulta.');
    }
    final prior = <String, DairyReviewItem>{
      for (final item in before.items)
        '${item.entityType}:${item.entityId}': item,
    };
    final results = <String, DairyRemoteState>{
      for (final item in remote) item.key.composite: item,
    };
    if (prior.length != before.items.length ||
        results.length != remote.length) {
      throw StateError('A consulta de Leite contém registros duplicados.');
    }
    final entries = <DairyRemoteReviewEntry>[];
    for (final item in after.items) {
      final key = '${item.entityType}:${item.entityId}';
      final previous = prior[key];
      final result = results[key];
      if (previous == null ||
          result == null ||
          !_same(previous.stagedPayload, item.stagedPayload)) {
        throw StateError('Os registros de Leite mudaram durante a consulta.');
      }
      DairyRemoteReviewStatus status;
      if (const {
            DairyReviewStatus.localChanged,
            DairyReviewStatus.localMissing,
            DairyReviewStatus.invalidStage,
            DairyReviewStatus.scopeConflict,
          }.contains(item.status) ||
          item.stagedPayload == null) {
        status = DairyRemoteReviewStatus.localReview;
      } else if (!result.found) {
        status = DairyRemoteReviewStatus.absentOnServer;
      } else if (result.deleted) {
        status = DairyRemoteReviewStatus.deletedOnServer;
      } else if (_same(item.stagedPayload, result.payload)) {
        status = DairyRemoteReviewStatus.sameOnServer;
      } else {
        status = DairyRemoteReviewStatus.differsOnServer;
      }
      entries.add(
        DairyRemoteReviewEntry(local: item, remote: result, status: status),
      );
    }
    return DairyRemoteReviewReport(List.unmodifiable(entries));
  }

  static bool _same(Object? left, Object? right) {
    if (left is Map && right is Map) {
      if (left.length != right.length) return false;
      for (final key in left.keys) {
        if (!right.containsKey(key) || !_same(left[key], right[key])) {
          return false;
        }
      }
      return true;
    }
    if (left is List && right is List) {
      if (left.length != right.length) return false;
      for (var i = 0; i < left.length; i++) {
        if (!_same(left[i], right[i])) return false;
      }
      return true;
    }
    return left == right;
  }
}
