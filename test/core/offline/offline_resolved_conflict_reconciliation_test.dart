import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/offline/services/offline_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Map<String, Object?> _conflict({
  required String id,
  required String serverId,
  required String company,
  String? tenant,
}) => <String, Object?>{
  'id': id,
  'server_conflict_id': serverId,
  'operation_id': id,
  'company_id': company,
  'tenant_id': tenant ?? 'tenant-$company',
  'status': 'open',
  'resolution': '',
  'resolved_at': null,
};

void main() {
  test(
    'somente confirmação positiva do mesmo escopo fecha pendência',
    () async {
      sqfliteFfiInit();
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      try {
        await db.execute(
          'CREATE TABLE local_conflicts ('
          'id TEXT PRIMARY KEY, server_conflict_id TEXT, operation_id TEXT, '
          'company_id TEXT, tenant_id TEXT, status TEXT, resolution TEXT, '
          'resolved_at TEXT)',
        );
        await db.execute(
          'CREATE TABLE operation_queue ('
          'id TEXT PRIMARY KEY, company_id TEXT, tenant_id TEXT, '
          'status TEXT, last_error TEXT, next_attempt_at TEXT)',
        );
        for (final entry in <Map<String, Object?>>[
          _conflict(id: 'op-a', serverId: 'server-a', company: 'company-a'),
          _conflict(id: 'op-b', serverId: 'server-b', company: 'company-a'),
          _conflict(id: 'op-other', serverId: 'server-a', company: 'company-b'),
          _conflict(
            id: 'op-other-tenant',
            serverId: 'server-a',
            company: 'company-a',
            tenant: 'tenant-other',
          ),
        ]) {
          await db.insert('local_conflicts', entry);
          await db.insert('operation_queue', <String, Object?>{
            'id': entry['id'],
            'company_id': entry['company_id'],
            'tenant_id': entry['tenant_id'],
            'status': 'conflict',
            'last_error': 'Aguardando decisão',
          });
        }

        expect(
          await OfflineRepository.hasOpenServerConflictsInDatabase(
            db,
            companyId: 'company-a',
            tenantId: 'tenant-company-a',
          ),
          isTrue,
        );

        final resolved =
            await OfflineRepository.reconcileResolvedRemoteConflictsInDatabase(
              db,
              companyId: 'company-a',
              tenantId: 'tenant-company-a',
              conflicts: <Map<String, dynamic>>[
                <String, dynamic>{'id': 'server-a', 'status': 'resolved'},
                <String, dynamic>{'id': 'server-b', 'status': 'open'},
              ],
            );
        expect(resolved, 1);
        final conflicts = await db.query('local_conflicts');
        final byId = <String, Map<String, Object?>>{
          for (final row in conflicts) row['id']! as String: row,
        };
        expect(byId['op-a']!['status'], 'resolved');
        expect(byId['op-a']!['resolution'], 'server_confirmed');
        expect(byId['op-b']!['status'], 'open');
        expect(byId['op-other']!['status'], 'open');
        expect(byId['op-other-tenant']!['status'], 'open');
        final operations = await db.query('operation_queue');
        final queue = <String, Map<String, Object?>>{
          for (final row in operations) row['id']! as String: row,
        };
        expect(queue['op-a']!['status'], 'resolved');
        expect(queue['op-a']!['last_error'], '');
        expect(queue['op-b']!['status'], 'conflict');
        expect(queue['op-other']!['status'], 'conflict');
        expect(queue['op-other-tenant']!['status'], 'conflict');

        expect(
          await OfflineRepository.hasOpenServerConflictsInDatabase(
            db,
            companyId: 'company-a',
            tenantId: 'tenant-company-a',
          ),
          isTrue,
        );

        expect(
          await OfflineRepository.reconcileResolvedRemoteConflictsInDatabase(
            db,
            companyId: 'company-a',
            tenantId: 'tenant-company-a',
            conflicts: <Map<String, dynamic>>[
              <String, dynamic>{'id': 'server-a', 'status': 'resolved'},
            ],
          ),
          0,
        );
      } finally {
        await db.close();
      }
    },
  );

  test('lista vazia ou sem confirmação não altera a fila', () async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    try {
      expect(
        await OfflineRepository.reconcileResolvedRemoteConflictsInDatabase(
          db,
          companyId: 'company-a',
          tenantId: 'tenant-company-a',
          conflicts: <Map<String, dynamic>>[],
        ),
        0,
      );
      expect(
        await OfflineRepository.reconcileResolvedRemoteConflictsInDatabase(
          db,
          companyId: 'company-a',
          tenantId: 'tenant-company-a',
          conflicts: <Map<String, dynamic>>[
            <String, dynamic>{'id': 'server-a', 'status': 'open'},
          ],
        ),
        0,
      );
    } finally {
      await db.close();
    }
  });
}
