import 'package:projeto_atlas/features/data_governance/domain/models/atlas_data_governance.dart';

class AtlasDataGovernanceEngine {
  const AtlasDataGovernanceEngine();

  AtlasDataGovernanceSummary buildSummary(List<AtlasBackupSnapshot> backups) {
    final AtlasBackupSnapshot? latest = backups.isEmpty ? null : backups.first;
    final DateTime now = DateTime.now();
    final bool recentBackup =
        latest != null && now.difference(latest.createdAt).inDays <= 7;

    final List<AtlasIntegrityCheck> checks = <AtlasIntegrityCheck>[
      AtlasIntegrityCheck(
        title: 'Backup recente',
        description: 'Existe uma cópia criada nos últimos 7 dias.',
        passed: recentBackup,
        weight: 35,
      ),
      AtlasIntegrityCheck(
        title: 'Dados incluídos',
        description: 'O backup mais recente contém registros do Atlas.',
        passed: latest != null && latest.itemCount > 0,
        weight: 30,
      ),
      AtlasIntegrityCheck(
        title: 'Histórico disponível',
        description: 'Há pelo menos duas versões para recuperação.',
        passed: backups.length >= 2,
        weight: 20,
      ),
      AtlasIntegrityCheck(
        title: 'Retenção controlada',
        description: 'O histórico respeita o limite seguro de cinco cópias.',
        passed: backups.length <= 5,
        weight: 15,
      ),
    ];

    return AtlasDataGovernanceSummary(
      backups: backups,
      checks: checks,
      lastBackupAt: latest?.createdAt,
    );
  }
}
