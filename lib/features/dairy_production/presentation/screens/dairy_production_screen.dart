import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_production_storage_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_herd_snapshot_storage_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_offline_stage_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_received_cache_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_remote_lookup_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_remote_reconciliation.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_sync_decision_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_sync_promotion_service.dart';
import 'package:projeto_atlas/core/offline/services/offline_sync_coordinator.dart';
import 'package:projeto_atlas/core/offline/services/offline_device_identity.dart';
import 'package:projeto_atlas/features/dairy_production/presentation/widgets/dairy_review_display.dart';
import 'package:projeto_atlas/core/auth/atlas_active_context.dart';
import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_herd_snapshot_data.dart';
import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_daily_production_data.dart';
import 'package:projeto_atlas/features/dairy_production/domain/services/dairy_indicator_calculator.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';

class DairyProductionScreen extends StatefulWidget {
  const DairyProductionScreen({required this.farm, super.key});
  final FarmData farm;

  @override
  State<DairyProductionScreen> createState() => _DairyProductionScreenState();
}

class _DairyProductionScreenState extends State<DairyProductionScreen> {
  final _storage = DairyProductionStorageService();
  final _snapshotStorage = DairyHerdSnapshotStorageService();
  final _offlineStage = DairyOfflineStageService();
  final _offlineReview = DairyOfflineReviewService();
  final _receivedCache = DairyReceivedCacheService();
  final _remoteLookup = DairyRemoteLookupService();
  final _decisions = DairySyncDecisionService();
  final _promotion = DairySyncPromotionService();
  final _syncCoordinator = OfflineSyncCoordinator();
  final _calculator = const DairyIndicatorCalculator();
  List<DairyDailyProductionData> _records = const [];
  DairyHerdSnapshotData? _snapshot;
  List<DairyHerdSnapshotData> _snapshots = const [];
  List<DairyReceivedCacheRecord> _receivedRecords = const [];
  bool _loading = true;
  bool _productionReadFailed = false;
  String? _readError;
  String? _stageNotice;
  bool _hasScopedStage = false;
  bool _checkingServer = false;
  bool _savingDecision = false;
  bool _approvingSend = false;

  String get _farmKey => widget.farm.id ?? widget.farm.name;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<DairyDailyProductionData> values = const [];
    List<DairyHerdSnapshotData> snapshots = const [];
    String? readError;
    var productionReadFailed = false;
    try {
      values = await _storage.load(_farmKey, strict: true);
    } catch (_) {
      productionReadFailed = true;
      readError =
          'Não foi possível ler as ordenhas salvas. Nenhum registro foi apagado. Revise os dados antes de registrar nova produção.';
    }
    try {
      snapshots = await _snapshotStorage.load(_farmKey, strict: true);
    } catch (_) {
      readError ??= 'Não foi possível ler o estado do lote nesta consulta.';
    }
    String? stageNotice;
    var hasScopedStage = false;
    var receivedRecords = const <DairyReceivedCacheRecord>[];
    final active = AtlasActiveContext.instance;
    final session = active.session;
    final farmId = widget.farm.id;
    if (readError == null &&
        farmId != null &&
        farmId.isNotEmpty &&
        active.farmId == farmId &&
        session != null &&
        session.companyId.isNotEmpty &&
        session.tenantId.isNotEmpty &&
        (session.hasUnrestrictedFarmAccess ||
            session.farmIds.contains(farmId))) {
      try {
        final report = await _offlineStage.stage(
          companyId: session.companyId,
          tenantId: session.tenantId,
          farmId: farmId,
        );
        final review = await _offlineReview.review(
          companyId: session.companyId,
          tenantId: session.tenantId,
          farmId: farmId,
        );
        hasScopedStage = review.items.isNotEmpty;
        final localKeys = <String>{
          for (final record in values)
            'dairy_daily_production:${DairyOfflineStageService.entityId(farmId, record.date)}',
          for (final snapshot in snapshots)
            'dairy_herd_snapshot:${DairyOfflineStageService.entityId(farmId, snapshot.date)}',
        };
        receivedRecords = await _receivedCache.load(
          companyId: session.companyId,
          tenantId: session.tenantId,
          farmId: farmId,
          locallyPresentKeys: localKeys,
        );
        final decisions = report.needsReview + review.needingDecision;
        if (decisions > 0) {
          stageNotice =
              '$decisions registro(s) de Leite exigem revisão '
              'antes de uma futura sincronização. Nada foi enviado ou apagado.';
        } else if (review.waiting > 0) {
          stageNotice =
              '${review.waiting} registro(s) de Leite preparados '
              'neste aparelho; ainda não há cópia remota recebida para '
              'comparar. Nada foi enviado.';
        } else if (review.matchingCache > 0) {
          stageNotice =
              '${review.matchingCache} registro(s) de Leite '
              'coincidem com a última cópia remota recebida. Isso não '
              'confirma o estado atual do servidor.';
        }
      } catch (_) {
        stageNotice =
            'Não foi possível preparar a cópia de segurança '
            'para sincronização. Os registros neste aparelho permanecem disponíveis.';
      }
    }
    if (mounted) {
      setState(() {
        _records = values;
        _snapshot = snapshots.isEmpty ? null : snapshots.first;
        _snapshots = snapshots;
        _loading = false;
        _productionReadFailed = productionReadFailed;
        _readError = readError;
        _stageNotice = stageNotice;
        _hasScopedStage = hasScopedStage;
        _receivedRecords = receivedRecords;
      });
    }
  }

  Future<void> _checkServer() async {
    if (_checkingServer) return;
    final active = AtlasActiveContext.instance;
    final session = active.session;
    final farmId = widget.farm.id;
    if (session == null || farmId == null || active.farmId != farmId) return;
    final userId = session.userId;
    final companyId = session.companyId;
    final tenantId = session.tenantId;
    bool scopeCurrent() {
      final current = active.session;
      return mounted &&
          active.farmId == farmId &&
          current?.userId == userId &&
          current?.companyId == companyId &&
          current?.tenantId == tenantId;
    }

    setState(() => _checkingServer = true);
    try {
      final before = await _offlineReview.review(
        companyId: companyId,
        tenantId: tenantId,
        farmId: farmId,
      );
      if (!scopeCurrent() || before.items.isEmpty) return;
      final supported = await _remoteLookup.supportsLookup(
        isScopeCurrent: scopeCurrent,
      );
      if (!mounted || !scopeCurrent()) return;
      if (!supported) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Este servidor ainda não oferece a conferência de Leite. Os dados locais continuam disponíveis.',
            ),
          ),
        );
        return;
      }
      final remote = await _remoteLookup.lookup(
        farmId: farmId,
        keys: [
          for (final item in before.items)
            DairyLookupKey(
              entityType: item.entityType,
              entityId: item.entityId,
            ),
        ],
        isScopeCurrent: scopeCurrent,
      );
      if (!scopeCurrent()) return;
      final after = await _offlineReview.review(
        companyId: companyId,
        tenantId: tenantId,
        farmId: farmId,
      );
      if (!scopeCurrent()) return;
      final report = DairyRemoteReconciliation.compare(
        before: before,
        after: after,
        remote: remote,
      );
      final saved = await _decisions.list(
        companyId: companyId,
        tenantId: tenantId,
        farmId: farmId,
      );
      if (!scopeCurrent()) return;
      final savedByKey = {for (final item in saved) item.key: item};
      if (!mounted) return;
      await _showReviewDialog(
        title: 'Conferência de Leite no servidor',
        summary:
            'Iguais: ${report.count(DairyRemoteReviewStatus.sameOnServer)} · '
            'Ausentes: ${report.count(DairyRemoteReviewStatus.absentOnServer)} · '
            'Divergentes: ${report.count(DairyRemoteReviewStatus.differsOnServer)} · '
            'Excluídos: ${report.count(DairyRemoteReviewStatus.deletedOnServer)} · '
            'Revisão local: ${report.count(DairyRemoteReviewStatus.localReview)}. '
            'Toque em cada registro para comparar. Nada foi enviado ou aprovado.',
        details: [
          for (final entry in report.entries)
            DairyReviewDetails(
              local: entry.local,
              remote: entry,
              decision:
                  savedByKey['${entry.local.entityType}:${entry.local.entityId}'],
              onPreferLocal: () =>
                  _saveDecision(entry, DairyDecisionChoice.preferLocal),
              onKeepServer: () =>
                  _saveDecision(entry, DairyDecisionChoice.keepServer),
            ),
        ],
      );
    } catch (_) {
      if (mounted && scopeCurrent()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível conferir o servidor agora. Os dados locais permanecem disponíveis; tente mais tarde.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingServer = false);
    }
  }

  Future<void> _showLocalReview() async {
    final active = AtlasActiveContext.instance;
    final session = active.session;
    final farmId = widget.farm.id;
    if (session == null || farmId == null || active.farmId != farmId) return;
    try {
      final report = await _offlineReview.review(
        companyId: session.companyId,
        tenantId: session.tenantId,
        farmId: farmId,
      );
      final saved = await _decisions.list(
        companyId: session.companyId,
        tenantId: session.tenantId,
        farmId: farmId,
      );
      final savedByKey = {for (final item in saved) item.key: item};
      if (!mounted ||
          active.farmId != farmId ||
          active.session?.userId != session.userId ||
          active.session?.companyId != session.companyId ||
          active.session?.tenantId != session.tenantId) {
        return;
      }
      await _showReviewDialog(
        title: 'Registros preparados de Leite',
        summary:
            'Nesta fazenda: ${report.items.length} registro(s). '
            'A comparação com a última cópia recebida não confirma o estado atual do servidor. '
            'Nada foi enviado.',
        details: [
          for (final item in report.items)
            DairyReviewDetails(
              local: item,
              decision: savedByKey['${item.entityType}:${item.entityId}'],
              onRemoveDecision:
                  savedByKey.containsKey('${item.entityType}:${item.entityId}')
                  ? () => _removeDecision(item)
                  : null,
              onApproveSend:
                  session.allows('sync.manage') &&
                      savedByKey.containsKey(
                        '${item.entityType}:${item.entityId}',
                      )
                  ? () => _approveSend(item)
                  : null,
            ),
        ],
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível revisar os registros preparados. Os dados originais permanecem disponíveis.',
          ),
        ),
      );
    }
  }

  Future<void> _approveSend(DairyReviewItem item) async {
    if (_approvingSend) return;
    final active = AtlasActiveContext.instance;
    final session = active.session;
    final farmId = widget.farm.id;
    if (session == null ||
        farmId == null ||
        active.farmId != farmId ||
        !session.allows('sync.manage')) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Aprovar envio deste registro?'),
        content: const Text(
          'O Atlas consultará novamente o servidor e os dados deste aparelho. '
          'Se nada mudou, criará uma operação na fila offline, que poderá ser enviada '
          'automaticamente quando houver conexão. Depois disso, retirar a preferência '
          'não cancela o envio.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Aprovar entrada na fila'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    bool scopeCurrent() {
      final current = active.session;
      return mounted &&
          active.farmId == farmId &&
          current?.userId == session.userId &&
          current?.companyId == session.companyId &&
          current?.tenantId == session.tenantId &&
          current?.allows('sync.manage') == true;
    }

    if (!scopeCurrent()) return;
    setState(() => _approvingSend = true);
    try {
      final result = await _promotion.approve(
        companyId: session.companyId,
        tenantId: session.tenantId,
        farmId: farmId,
        entityType: item.entityType,
        entityId: item.entityId,
        isScopeCurrent: scopeCurrent,
        resolveDeviceId: () => _syncCoordinator.registerDevice(
          deviceKey: OfflineDeviceIdentity.key(session.userId),
        ),
      );
      if (!scopeCurrent()) return;
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.alreadyQueued
                ? 'Este registro já estava na fila. Acompanhe pela Central offline.'
                : 'Registro incluído na fila. Acompanhe o envio pela Central offline.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted || !scopeCurrent()) return;
      final reason = error is StateError
          ? error.message.toString()
          : 'Confira a conexão e tente novamente.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nada foi enfileirado. $reason')));
    } finally {
      if (mounted) setState(() => _approvingSend = false);
    }
  }

  Future<void> _saveDecision(
    DairyRemoteReviewEntry entry,
    DairyDecisionChoice choice,
  ) async {
    if (_savingDecision) return;
    final active = AtlasActiveContext.instance;
    final session = active.session;
    final farmId = widget.farm.id;
    if (session == null || farmId == null || active.farmId != farmId) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Salvar preferência para este registro?'),
        content: const Text(
          'A escolha ficará apenas neste aparelho. Nada será enviado agora; '
          'o registro e o servidor precisarão de nova conferência antes de sincronizar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Salvar preferência'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    bool scopeCurrent() {
      final current = active.session;
      return mounted &&
          active.farmId == farmId &&
          current?.userId == session.userId &&
          current?.companyId == session.companyId &&
          current?.tenantId == session.tenantId;
    }

    setState(() => _savingDecision = true);
    try {
      await _decisions.save(
        companyId: session.companyId,
        tenantId: session.tenantId,
        farmId: farmId,
        userId: session.userId,
        entry: entry,
        choice: choice,
        isScopeCurrent: scopeCurrent,
      );
      if (!scopeCurrent()) return;
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preferência salva neste aparelho. Nenhum dado foi enviado.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted || !scopeCurrent()) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A preferência não foi salva. Revise o registro e confira o servidor novamente.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingDecision = false);
    }
  }

  Future<void> _removeDecision(DairyReviewItem item) async {
    final active = AtlasActiveContext.instance;
    final session = active.session;
    final farmId = widget.farm.id;
    if (session == null || farmId == null || active.farmId != farmId) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Retirar preferência?'),
        content: const Text(
          'O registro original e a cópia preparada serão preservados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Retirar'),
          ),
        ],
      ),
    );
    if (!mounted ||
        confirmed != true ||
        active.farmId != farmId ||
        active.session?.userId != session.userId ||
        active.session?.companyId != session.companyId ||
        active.session?.tenantId != session.tenantId) {
      return;
    }
    try {
      await _decisions.remove(
        companyId: session.companyId,
        tenantId: session.tenantId,
        farmId: farmId,
        entityType: item.entityType,
        entityId: item.entityId,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preferência retirada. Os dados de Leite foram preservados.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível retirar a preferência agora.'),
        ),
      );
    }
  }

  Future<void> _showReviewDialog({
    required String title,
    required String summary,
    required List<Widget> details,
  }) {
    final size = MediaQuery.sizeOf(context);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: math.min(640, math.max(240, size.width - 80)),
          height: math.min(520, math.max(220, size.height - 240)),
          child: ListView(
            children: [Text(summary), const SizedBox(height: 12), ...details],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _calculator.summarize(
      _records,
      hectares: widget.farm.area.toDouble(),
      lactatingCows: _snapshot?.lactatingCows,
    );
    final currency = NumberFormat.decimalPattern('pt_BR');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produção diária de leite'),
        actions: [
          IconButton(
            tooltip: 'Estado do lote',
            icon: const Icon(Icons.groups_outlined),
            onPressed: _openSnapshotForm,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _productionReadFailed ? null : _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Registrar ordenha'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
              children: [
                if (_readError != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_readError!),
                          TextButton(
                            onPressed: _load,
                            child: const Text('Tentar leitura novamente'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_stageNotice != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_stageNotice!),
                          if (_hasScopedStage) ...[
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _showLocalReview,
                              icon: const Icon(Icons.list_alt_outlined),
                              label: const Text('Ver registros preparados'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _checkingServer ? null : _checkServer,
                              icon: _checkingServer
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.fact_check_outlined),
                              label: const Text('Conferir no servidor'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                Text(
                  widget.farm.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Dados salvos neste dispositivo e disponíveis sem internet.',
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Metric(
                      label: 'Última ordenha',
                      value: summary.latestLiters == null
                          ? 'Sem dado'
                          : '${currency.format(summary.latestLiters)} L · ${DateFormat('dd/MM').format(summary.latestRecordDate!)}',
                    ),
                    _Metric(
                      label: 'Média diária',
                      value: summary.averageLitersPerDay == null
                          ? 'Registre a produção'
                          : '${currency.format(summary.averageLitersPerDay)} L/dia',
                    ),
                    _Metric(
                      label: 'Litros por hectare',
                      value: summary.averageLitersPerHectare == null
                          ? 'Informe a área'
                          : '${currency.format(summary.averageLitersPerHectare)} L/ha/dia',
                    ),
                    _Metric(
                      label: 'Litros por vaca ordenhada',
                      value: summary.litersPerMilkedCow == null
                          ? 'Registre ordenhas válidas'
                          : '${currency.format(summary.litersPerMilkedCow)} L/vaca/dia',
                    ),
                    _Metric(
                      label: 'Litros por vaca em lactação',
                      value: summary.litersPerLactatingCow == null
                          ? summary.milkedCowsExceedLactatingSnapshot
                                ? 'Confira o lote em lactação'
                                : 'Informe o lote em lactação'
                          : '${currency.format(summary.litersPerLactatingCow)} L/vaca/dia',
                    ),
                    _Metric(
                      label: 'Média de vacas ordenhadas',
                      value: summary.averageMilkedCows == null
                          ? 'Sem ordenhas válidas'
                          : '${summary.averageMilkedCows!.toStringAsFixed(1)} vacas/dia',
                    ),
                    _Metric(
                      label: 'Cobertura dos últimos 30 dias',
                      value:
                          '${summary.coveragePercent.toStringAsFixed(0)}% · ${summary.recordedDays}/${summary.windowDays} dias',
                    ),
                    _Metric(
                      label: 'Dias ainda sem ordenha válida',
                      value: '${summary.missingDays} dia(s)',
                    ),
                    _Metric(
                      label: 'Vacas em lactação',
                      value: _snapshot?.lactatingPercent == null
                          ? 'Registre o lote'
                          : '${_snapshot!.lactatingPercent!.toStringAsFixed(1)}%',
                    ),
                    _Metric(
                      label: 'Vacas secas',
                      value: _snapshot?.dryPercent == null
                          ? 'Registre o lote'
                          : '${_snapshot!.dryPercent!.toStringAsFixed(1)}%',
                    ),
                    _Metric(
                      label: 'Perdas gestacionais',
                      value: _snapshot?.pregnancyLossPercent == null
                          ? 'Informe gestações'
                          : '${_snapshot!.pregnancyLossPercent!.toStringAsFixed(1)}% '
                                '(${_snapshot!.pregnancyLosses}/${_snapshot!.pregnanciesMonitored})',
                    ),
                  ],
                ),
                if (summary.dataQualityAlerts.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Card(
                    color: const Color(0xFFFFF4E5),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Qualidade dos registros',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          for (final alert in summary.dataQualityAlerts)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text('• $alert'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                Text(
                  'Histórico do lote',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                if (_snapshots.isEmpty)
                  const Text('Nenhum estado de lote registrado ainda.'),
                for (final snapshot in _snapshots.take(5))
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.groups_outlined),
                      title: Text(
                        DateFormat('dd/MM/yyyy').format(snapshot.date),
                      ),
                      subtitle: Text(
                        snapshot.pregnancyLossPercent == null
                            ? '${snapshot.lactatingCows} em lactação · '
                                  '${snapshot.dryCows} secas · '
                                  '${snapshot.eligibleCows} elegíveis · '
                                  '${snapshot.pregnancyLosses} perdas'
                            : '${snapshot.lactatingCows} em lactação · '
                                  '${snapshot.dryCows} secas · '
                                  '${snapshot.eligibleCows} elegíveis · '
                                  '${snapshot.pregnancyLosses}/${snapshot.pregnanciesMonitored} perdas '
                                  '(${snapshot.pregnancyLossPercent!.toStringAsFixed(1)}%)',
                      ),
                      trailing: IconButton(
                        tooltip: 'Excluir estado do lote',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final confirmed = await _confirmChange(
                            title: 'Excluir estado do lote?',
                            description:
                                'O registro de ${DateFormat('dd/MM/yyyy').format(snapshot.date)} será removido deste dispositivo.',
                            confirmLabel: 'Excluir',
                          );
                          if (!confirmed) return;
                          await _changeProduction(
                            () => _snapshotStorage.delete(
                              _farmKey,
                              snapshot.date,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 28),
                Text(
                  'Histórico de ordenhas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                if (_records.isEmpty && !_productionReadFailed)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Ainda não há produção registrada. Use “Registrar ordenha” ao fim do dia para começar os cálculos.',
                      ),
                    ),
                  ),
                for (final record in _records)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.water_drop_outlined),
                      title: Text(
                        '${DateFormat('dd/MM/yyyy').format(record.date)} · ${currency.format(record.totalLiters)} L',
                      ),
                      subtitle: Text(
                        'Manhã ${currency.format(record.morningLiters)} L · Tarde ${currency.format(record.afternoonLiters)} L · ${record.cowsMilked} vacas',
                      ),
                      trailing: IconButton(
                        tooltip: 'Excluir registro',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final confirmed = await _confirmChange(
                            title: 'Excluir ordenha?',
                            description:
                                'A ordenha de ${DateFormat('dd/MM/yyyy').format(record.date)} será removida deste dispositivo.',
                            confirmLabel: 'Excluir',
                          );
                          if (!confirmed) return;
                          await _changeProduction(
                            () => _storage.delete(_farmKey, record.date),
                          );
                        },
                      ),
                    ),
                  ),
                if (_receivedRecords.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text(
                    'Recebidos de outros aparelhos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Cópias da fazenda recebidas pela sincronização. São somente leitura: não substituem o histórico local e não entram nos indicadores.',
                  ),
                  const SizedBox(height: 10),
                  for (final received in _receivedRecords)
                    Card(
                      child: ListTile(
                        leading: Icon(
                          received.production == null
                              ? Icons.groups_outlined
                              : Icons.water_drop_outlined,
                        ),
                        title: Text(
                          received.production != null
                              ? '${DateFormat('dd/MM/yyyy').format(received.date)} · ${currency.format(received.production!.totalLiters)} L'
                              : '${DateFormat('dd/MM/yyyy').format(received.date)} · Estado do lote',
                        ),
                        subtitle: Text(
                          '${_receivedDescription(received)}\n'
                          'Versão ${received.version} · recebida em ${DateFormat('dd/MM HH:mm').format(received.receivedAt.toLocal())}',
                        ),
                        isThreeLine: true,
                      ),
                    ),
                ],
              ],
            ),
    );
  }

  Future<void> _openForm() async {
    final result = await showDialog<DairyDailyProductionData>(
      context: context,
      builder: (_) => const _DairyRecordDialog(),
    );
    if (result == null || !mounted) return;
    final existing = _records.any((item) => _sameDay(item.date, result.date));
    if (existing) {
      final confirmed = await _confirmChange(
        title: 'Substituir ordenha existente?',
        description:
            'Já existe uma ordenha em ${DateFormat('dd/MM/yyyy').format(result.date)}. Os valores salvos para esse dia serão substituídos.',
        confirmLabel: 'Substituir',
      );
      if (!confirmed) return;
    }
    await _changeProduction(() => _storage.upsert(_farmKey, result));
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _receivedDescription(DairyReceivedCacheRecord received) {
    final numberFormat = NumberFormat.decimalPattern('pt_BR');
    final production = received.production;
    if (production != null) {
      return 'Manhã ${numberFormat.format(production.morningLiters)} L · '
          'Tarde ${numberFormat.format(production.afternoonLiters)} L · '
          '${production.cowsMilked} vacas ordenhadas';
    }
    final snapshot = received.snapshot!;
    return '${snapshot.lactatingCows} em lactação · ${snapshot.dryCows} secas · '
        '${snapshot.eligibleCows} elegíveis · ${snapshot.pregnancyLosses} perdas';
  }

  Future<bool> _confirmChange({
    required String title,
    required String description,
    required String confirmLabel,
  }) async {
    if (!mounted) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return mounted && confirmed == true;
  }

  Future<void> _changeProduction(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível concluir a alteração. Confira os registros salvos antes de tentar novamente.',
            ),
          ),
        );
      }
    }
    if (mounted) await _load();
  }

  Future<void> _openSnapshotForm() async {
    final result = await showDialog<DairyHerdSnapshotData>(
      context: context,
      builder: (_) => const _HerdSnapshotDialog(),
    );
    if (result == null || !mounted) return;
    final existing = _snapshots.any((item) => _sameDay(item.date, result.date));
    if (existing) {
      final confirmed = await _confirmChange(
        title: 'Substituir estado do lote?',
        description:
            'Já existe um estado do lote em ${DateFormat('dd/MM/yyyy').format(result.date)}. As contagens salvas para esse dia serão substituídas.',
        confirmLabel: 'Substituir',
      );
      if (!confirmed) return;
    }
    await _changeProduction(() => _snapshotStorage.upsert(_farmKey, result));
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DairyRecordDialog extends StatefulWidget {
  const _DairyRecordDialog();
  @override
  State<_DairyRecordDialog> createState() => _DairyRecordDialogState();
}

class _HerdSnapshotDialog extends StatefulWidget {
  const _HerdSnapshotDialog();
  @override
  State<_HerdSnapshotDialog> createState() => _HerdSnapshotDialogState();
}

class _HerdSnapshotDialogState extends State<_HerdSnapshotDialog> {
  final _form = GlobalKey<FormState>();
  final _eligible = TextEditingController();
  final _lactating = TextEditingController();
  final _dry = TextEditingController();
  final _pregnanciesMonitored = TextEditingController(text: '0');
  final _losses = TextEditingController(text: '0');
  DateTime _date = DateTime.now();
  @override
  void dispose() {
    _eligible.dispose();
    _lactating.dispose();
    _dry.dispose();
    _pregnanciesMonitored.dispose();
    _losses.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Estado do lote'),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Data do estado do lote'),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(_date)),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_today_outlined),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDate: _date,
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
          ),
          _field(_eligible, 'Vacas elegíveis'),
          _field(_lactating, 'Em lactação'),
          _field(_dry, 'Secas'),
          _field(_pregnanciesMonitored, 'Gestações acompanhadas'),
          _field(_losses, 'Perdas gestacionais'),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _save, child: const Text('Salvar')),
    ],
  );
  Widget _field(TextEditingController c, String label) => TextFormField(
    controller: c,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label),
    validator: (v) {
      final parsed = int.tryParse(v ?? '');
      return parsed == null || parsed < 0 ? 'Informe zero ou mais' : null;
    },
  );
  void _save() {
    if (!_form.currentState!.validate()) return;
    final eligible = int.parse(_eligible.text);
    final lactating = int.parse(_lactating.text);
    final dry = int.parse(_dry.text);
    final pregnanciesMonitored = int.parse(_pregnanciesMonitored.text);
    final losses = int.parse(_losses.text);
    if (lactating + dry > eligible) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vacas em lactação e secas não podem superar as vacas elegíveis.',
          ),
        ),
      );
      return;
    }
    if (losses > pregnanciesMonitored) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'As perdas gestacionais não podem superar as gestações acompanhadas.',
          ),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      DairyHerdSnapshotData(
        date: _date,
        eligibleCows: eligible,
        lactatingCows: lactating,
        dryCows: dry,
        pregnanciesMonitored: pregnanciesMonitored,
        pregnancyLosses: losses,
      ),
    );
  }
}

class _DairyRecordDialogState extends State<_DairyRecordDialog> {
  final _form = GlobalKey<FormState>();
  final _morning = TextEditingController();
  final _afternoon = TextEditingController();
  final _cows = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  @override
  void dispose() {
    _morning.dispose();
    _afternoon.dispose();
    _cows.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Registrar produção do dia'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_date)),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDate: _date,
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
            ),
            _field(_morning, 'Litros na ordenha da manhã', decimal: true),
            _field(_afternoon, 'Litros na ordenha da tarde', decimal: true),
            _field(_cows, 'Vacas ordenhadas', positiveInteger: true),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(
                labelText: 'Observação opcional',
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _save, child: const Text('Salvar produção')),
    ],
  );
  Widget _field(
    TextEditingController c,
    String label, {
    bool decimal = false,
    bool positiveInteger = false,
  }) => TextFormField(
    controller: c,
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    decoration: InputDecoration(labelText: label),
    validator: (value) {
      final n = double.tryParse((value ?? '').replaceAll(',', '.'));
      if (n == null || !n.isFinite || n < 0) {
        return 'Informe um valor finito e não negativo';
      }
      if (positiveInteger && (n <= 0 || n != n.roundToDouble())) {
        return 'Informe ao menos uma vaca ordenhada';
      }
      return null;
    },
  );
  void _save() {
    if (!_form.currentState!.validate()) return;
    double n(TextEditingController c) =>
        double.parse(c.text.replaceAll(',', '.'));
    if (!(n(_morning) + n(_afternoon)).isFinite) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A soma das ordenhas é inválida.')),
      );
      return;
    }
    Navigator.pop(
      context,
      DairyDailyProductionData(
        date: _date,
        morningLiters: n(_morning),
        afternoonLiters: n(_afternoon),
        cowsMilked: n(_cows).round(),
        notes: _notes.text.trim(),
      ),
    );
  }
}
