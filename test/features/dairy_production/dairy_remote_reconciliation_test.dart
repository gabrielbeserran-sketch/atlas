import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_offline_stage_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_remote_lookup_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_remote_reconciliation.dart';

const _key = DairyLookupKey(
  entityType: 'dairy_daily_production',
  entityId: 'farm-a:2026-10-01',
);
const _payload = <String, dynamic>{
  'farm_id': 'farm-a',
  'date': '2026-10-01',
  'morning_liters': 10,
  'afternoon_liters': 8,
  'cows_milked': 3,
};

DairyReviewReport _local({
  DairyReviewStatus status = DairyReviewStatus.waitingForCache,
  Map<String, dynamic>? payload,
}) => DairyReviewReport(<DairyReviewItem>[
  DairyReviewItem(
    _key.entityType,
    _key.entityId,
    status,
    stagedPayload: payload ?? _payload,
  ),
]);

DairyRemoteState _remote({
  bool found = true,
  bool deleted = false,
  Map<String, dynamic> payload = _payload,
}) => DairyRemoteState(
  key: _key,
  found: found,
  version: found ? 1 : 0,
  deleted: deleted,
  payload: found ? payload : const {},
  readAt: DateTime.utc(2026, 10, 1),
);

void main() {
  test('distingue igualdade, ausência, exclusão e divergência remotas', () {
    for (final (remote, expected)
        in <(DairyRemoteState, DairyRemoteReviewStatus)>[
          (_remote(), DairyRemoteReviewStatus.sameOnServer),
          (_remote(found: false), DairyRemoteReviewStatus.absentOnServer),
          (_remote(deleted: true), DairyRemoteReviewStatus.deletedOnServer),
          (
            _remote(payload: {..._payload, 'morning_liters': 11}),
            DairyRemoteReviewStatus.differsOnServer,
          ),
        ]) {
      final report = DairyRemoteReconciliation.compare(
        before: _local(),
        after: _local(),
        remote: [remote],
      );
      expect(report.count(expected), 1);
    }
  });

  test('mudança ou ausência local exige revisão mesmo se remoto for igual', () {
    for (final status in [
      DairyReviewStatus.localChanged,
      DairyReviewStatus.localMissing,
      DairyReviewStatus.invalidStage,
      DairyReviewStatus.scopeConflict,
    ]) {
      final report = DairyRemoteReconciliation.compare(
        before: _local(),
        after: _local(status: status),
        remote: [_remote()],
      );
      expect(report.count(DairyRemoteReviewStatus.localReview), 1);
    }
  });

  test('staging alterado durante consulta invalida toda a comparação', () {
    expect(
      () => DairyRemoteReconciliation.compare(
        before: _local(),
        after: _local(payload: {..._payload, 'morning_liters': 12}),
        remote: [_remote()],
      ),
      throwsStateError,
    );
    expect(
      () => DairyRemoteReconciliation.compare(
        before: _local(),
        after: _local(),
        remote: const [],
      ),
      throwsStateError,
    );
  });
}
