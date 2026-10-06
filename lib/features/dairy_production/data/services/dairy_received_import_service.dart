import 'package:projeto_atlas/features/dairy_production/data/services/dairy_herd_snapshot_storage_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_production_storage_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_received_cache_service.dart';

/// Adds one verified server copy to this device without sending it back or
/// replacing an existing local record.
class DairyReceivedImportService {
  DairyReceivedImportService({
    DairyReceivedCacheService? cache,
    DairyProductionStorageService? productionStorage,
    DairyHerdSnapshotStorageService? snapshotStorage,
  }) : _cache = cache ?? DairyReceivedCacheService(),
       _productionStorage =
           productionStorage ?? DairyProductionStorageService(),
       _snapshotStorage = snapshotStorage ?? DairyHerdSnapshotStorageService();

  final DairyReceivedCacheService _cache;
  final DairyProductionStorageService _productionStorage;
  final DairyHerdSnapshotStorageService _snapshotStorage;

  Future<void> add({
    required DairyReceivedCacheRecord selected,
    required String companyId,
    required String tenantId,
    required String farmId,
    required bool Function() isScopeCurrent,
  }) async {
    _requireCurrentScope(isScopeCurrent);
    final current = await _cache.load(
      companyId: companyId,
      tenantId: tenantId,
      farmId: farmId,
    );
    _requireCurrentScope(isScopeCurrent);
    final latest = current
        .where(
          (item) =>
              item.entityType == selected.entityType &&
              item.entityId == selected.entityId,
        )
        .firstOrNull;
    if (latest == null || latest.version != selected.version) {
      throw StateError(
        'A cópia recebida mudou desde que a tela foi aberta. Atualize a tela e revise a versão mais recente.',
      );
    }

    if (latest.production != null) {
      final local = await _productionStorage.load(farmId, strict: true);
      _requireCurrentScope(isScopeCurrent);
      if (local.any((item) => _sameDay(item.date, latest.date))) {
        throw StateError(
          'Já existe uma ordenha local nessa data. O Atlas não a substituiu.',
        );
      }
      _requireCurrentScope(isScopeCurrent);
      await _productionStorage.upsert(farmId, latest.production!);
      return;
    }
    if (latest.snapshot != null) {
      final local = await _snapshotStorage.load(farmId, strict: true);
      _requireCurrentScope(isScopeCurrent);
      if (local.any((item) => _sameDay(item.date, latest.date))) {
        throw StateError(
          'Já existe um estado local do lote nessa data. O Atlas não o substituiu.',
        );
      }
      _requireCurrentScope(isScopeCurrent);
      await _snapshotStorage.upsert(farmId, latest.snapshot!);
      return;
    }
    throw StateError('O conteúdo recebido não pode ser adicionado.');
  }

  static bool _sameDay(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  static void _requireCurrentScope(bool Function() isScopeCurrent) {
    if (!isScopeCurrent()) {
      throw StateError(
        'A fazenda ou a sessão mudou. Nenhum dado foi importado.',
      );
    }
  }
}
