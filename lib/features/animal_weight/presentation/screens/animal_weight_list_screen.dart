import 'dart:async';

import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/auth/atlas_active_context.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_enterprise_service.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_outbox_service.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_storage_service.dart';
import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';
import 'package:projeto_atlas/features/animal_weight/domain/services/animal_weight_event_service.dart';
import 'package:projeto_atlas/features/animal_weight/presentation/screens/animal_weight_form_screen.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AnimalWeightListScreen extends StatefulWidget {
  const AnimalWeightListScreen({
    required this.animal,
    required this.farm,
    required this.group,
    this.autoOpenCreate = false,
    this.weightStorage,
    this.weightEnterprise,
    this.weightOutbox,
    this.companyId,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final bool autoOpenCreate;
  final AnimalWeightStorageService? weightStorage;
  final AnimalWeightEnterpriseService? weightEnterprise;
  final AnimalWeightOutboxService? weightOutbox;
  final String? companyId;

  @override
  State<AnimalWeightListScreen> createState() => _AnimalWeightListScreenState();
}

class _AnimalWeightListScreenState extends State<AnimalWeightListScreen> {
  late final AnimalWeightStorageService storage;
  late final AnimalWeightEnterpriseService enterprise;
  late final AnimalWeightOutboxService outbox;

  final AnimalWeightEventService eventService =
      const AnimalWeightEventService();

  List<AnimalWeightData> weights = [];
  List<PendingAnimalWeight> pendingWeights = [];
  bool isLoading = true;
  bool isSyncing = false;
  String syncNotice = '';

  String get companyId =>
      widget.companyId ?? AtlasActiveContext.instance.companyId ?? '';
  String get farmId => widget.farm.id?.trim() ?? '';
  String get animalId => widget.animal.id.trim();
  bool get hasSyncScope =>
      companyId.trim().isNotEmpty && farmId.isNotEmpty && animalId.isNotEmpty;

  @override
  void initState() {
    super.initState();
    storage =
        widget.weightStorage ??
        AnimalWeightStorageService(companyId: companyId, farmId: farmId);
    enterprise = widget.weightEnterprise ?? AnimalWeightEnterpriseService();
    outbox = widget.weightOutbox ?? AnimalWeightOutboxService();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    if (!widget.autoOpenCreate) {
      await loadWeights();
      return;
    }
    await loadWeights(preferRemote: false);
    if (!mounted) return;
    await openWeightForm();
    if (mounted && pendingWeights.isEmpty) unawaited(loadWeights());
  }

  double get currentWeight {
    if (weights.isEmpty) {
      return widget.animal.weight;
    }

    return weights.first.weight;
  }

  double get minimumWeight {
    if (weights.isEmpty) {
      return widget.animal.weight;
    }

    return weights.map((record) => record.weight).reduce((first, second) {
      return first < second ? first : second;
    });
  }

  double get maximumWeight {
    if (weights.isEmpty) {
      return widget.animal.weight;
    }

    return weights.map((record) => record.weight).reduce((first, second) {
      return first > second ? first : second;
    });
  }

  double? get latestVariation {
    if (weights.length < 2) {
      return null;
    }

    return weights[0].weight - weights[1].weight;
  }

  Future<void> loadWeights({bool preferRemote = true}) async {
    if (isSyncing) return;
    isSyncing = true;
    try {
      var queued = hasSyncScope
          ? await outbox.load(
              companyId: companyId,
              farmId: farmId,
              animalId: animalId,
            )
          : <PendingAnimalWeight>[];
      List<AnimalWeightData> loaded;
      var nextNotice = '';
      if (preferRemote && hasSyncScope) {
        try {
          loaded = (await enterprise.listWeights(animalId: animalId)).toList();
          // A API antiga pode aceitar o POST e ignorar a chave. Só repetimos
          // operações quando o servidor afirma oferecer idempotência.
          bool supportsSafeRetry = false;
          try {
            supportsSafeRetry = await enterprise.supportsIdempotentSync();
          } catch (_) {
            // Sem confirmação, conserva a fila sem tentar POST.
          }
          if (supportsSafeRetry) {
            for (final item in queued.toList()) {
              final operationId = item.record.clientOperationId;
              final matchingRemote = loaded.where(
                (record) =>
                    record.clientOperationId.isNotEmpty &&
                    record.clientOperationId == operationId,
              );
              if (matchingRemote.isNotEmpty) {
                if (item.record.sameMeasurementAs(matchingRemote.first)) {
                  await outbox.remove(
                    companyId: companyId,
                    farmId: farmId,
                    animalId: animalId,
                    operationId: operationId,
                  );
                } else {
                  await outbox.upsert(
                    companyId: companyId,
                    farmId: farmId,
                    animalId: animalId,
                    entry: PendingAnimalWeight(
                      record: item.record,
                      needsReview: true,
                    ),
                  );
                }
                continue;
              }
              if (item.needsReview) continue;
              try {
                final created = await enterprise.createWeight(
                  animalId: animalId,
                  weight: item.record,
                );
                if (created.clientOperationId == operationId) {
                  loaded.add(created);
                  await outbox.remove(
                    companyId: companyId,
                    farmId: farmId,
                    animalId: animalId,
                    operationId: operationId,
                  );
                } else {
                  await outbox.upsert(
                    companyId: companyId,
                    farmId: farmId,
                    animalId: animalId,
                    entry: PendingAnimalWeight(
                      record: item.record,
                      needsReview: true,
                    ),
                  );
                }
              } on AtlasEnterpriseApiException catch (error) {
                if (error.statusCode == 409 ||
                    (error.statusCode != null &&
                        error.statusCode! >= 400 &&
                        error.statusCode! < 500 &&
                        error.statusCode != 401 &&
                        error.statusCode != 408 &&
                        error.statusCode != 429)) {
                  await outbox.upsert(
                    companyId: companyId,
                    farmId: farmId,
                    animalId: animalId,
                    entry: PendingAnimalWeight(
                      record: item.record,
                      needsReview: true,
                    ),
                  );
                }
              } catch (_) {
                // Falha incerta: mantém o mesmo ID para conciliar no GET.
              }
            }
            queued = await outbox.load(
              companyId: companyId,
              farmId: farmId,
              animalId: animalId,
            );
          } else {
            nextNotice =
                'O servidor ainda não confirmou envio seguro. Os dados permanecem no dispositivo.';
          }
          await storage.saveWeights(
            farmName: widget.farm.name,
            farmId: farmId,
            groupName: widget.group.name,
            animalId: animalId,
            weights: loaded,
          );
        } catch (_) {
          nextNotice = 'Sem conexão no momento. Tente sincronizar mais tarde.';
          loaded = await storage.loadWeights(
            farmName: widget.farm.name,
            farmId: farmId,
            groupName: widget.group.name,
            animalId: animalId,
            preferRemote: false,
          );
        }
      } else {
        loaded = await storage.loadWeights(
          farmName: widget.farm.name,
          farmId: farmId,
          groupName: widget.group.name,
          animalId: animalId,
          preferRemote: false,
        );
      }
      final knownOperations = loaded
          .map((item) => item.clientOperationId)
          .where((id) => id.isNotEmpty)
          .toSet();
      loaded.addAll(
        queued
            .where(
              (item) =>
                  item.needsReview ||
                  !knownOperations.contains(item.record.clientOperationId),
            )
            .map((item) => item.record),
      );
      if (!mounted) return;
      setState(() {
        weights = loaded;
        pendingWeights = queued;
        syncNotice = nextNotice;
        sortWeights();
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível ler as pesagens salvas neste dispositivo. Nenhum dado foi apagado.',
          ),
        ),
      );
    } finally {
      isSyncing = false;
    }
  }

  Future<void> saveWeights() async {
    await storage.saveWeights(
      farmName: widget.farm.name,
      farmId: farmId,
      groupName: widget.group.name,
      animalId: widget.animal.id,
      weights: weights,
    );
  }

  void sortWeights() {
    weights.sort((first, second) {
      final firstDate = parseDate(first.date);
      final secondDate = parseDate(second.date);

      return secondDate.compareTo(firstDate);
    });
  }

  DateTime parseDate(String value) {
    final parts = value.split('/');

    if (parts.length != 3) {
      return DateTime(1900);
    }

    final day = int.tryParse(parts[0]) ?? 1;
    final month = int.tryParse(parts[1]) ?? 1;
    final year = int.tryParse(parts[2]) ?? 1900;

    return DateTime(year, month, day);
  }

  Future<void> openWeightForm() async {
    if (!hasSyncScope) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione uma empresa, fazenda e animal antes de registrar a pesagem.',
          ),
        ),
      );
      return;
    }
    final newWeight = await Navigator.push<AnimalWeightData>(
      context,
      MaterialPageRoute<AnimalWeightData>(
        builder: (context) {
          return const AnimalWeightFormScreen();
        },
      ),
    );

    if (newWeight == null || !mounted) {
      return;
    }

    try {
      await outbox.upsert(
        companyId: companyId,
        farmId: farmId,
        animalId: animalId,
        entry: PendingAnimalWeight(record: newWeight),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A pesagem não pôde ser salva neste dispositivo. Tente novamente.',
          ),
        ),
      );
      return;
    }
    setState(() {
      pendingWeights.add(PendingAnimalWeight(record: newWeight));
      weights.add(newWeight);
      sortWeights();
    });
    await loadWeights(preferRemote: false);

    await eventService.publishWeightRecorded(
      farmName: widget.farm.name,
      animalId: widget.animal.id,
      animalName: widget.animal.displayName,
      weight: newWeight,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Pesagem salva neste dispositivo. O envio ao servidor está pendente.',
        ),
      ),
    );
    unawaited(loadWeights());
  }

  Future<void> editWeight(AnimalWeightData weightRecord) async {
    if (pendingWeights.any(
      (item) => item.record.clientOperationId == weightRecord.clientOperationId,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aguarde a confirmação do envio antes de alterar esta pesagem.',
          ),
        ),
      );
      return;
    }
    if (weightRecord.isRemote) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pesagens sincronizadas não podem ser editadas. Registre uma nova pesagem para preservar o histórico.',
          ),
        ),
      );
      return;
    }
    final editedWeight = await Navigator.push<AnimalWeightData>(
      context,
      MaterialPageRoute<AnimalWeightData>(
        builder: (context) {
          return AnimalWeightFormScreen(weightRecord: weightRecord);
        },
      ),
    );

    if (editedWeight == null || !mounted) {
      return;
    }

    final recordIndex = weights.indexWhere(
      (item) => item.id == weightRecord.id,
    );

    if (recordIndex == -1) {
      return;
    }

    setState(() {
      weights[recordIndex] = editedWeight;
      sortWeights();
    });

    await saveWeights();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pesagem atualizada com sucesso.')),
    );
  }

  Future<void> deleteWeight(AnimalWeightData weightRecord) async {
    if (pendingWeights.any(
      (item) => item.record.clientOperationId == weightRecord.clientOperationId,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta pesagem pode já ter sido recebida pelo servidor. Aguarde a conciliação antes de excluí-la.',
          ),
        ),
      );
      return;
    }
    if (weightRecord.isRemote) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pesagens sincronizadas não podem ser excluídas. O histórico oficial é imutável.',
          ),
        ),
      );
      return;
    }
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir pesagem'),
          content: Text(
            'Deseja excluir a pesagem registrada em '
            '${weightRecord.date}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() {
      weights.removeWhere((item) => item.id == weightRecord.id);
    });

    await saveWeights();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pesagem excluída com sucesso.')),
    );
  }

  Future<void> reviewPendingWeight(AnimalWeightData record) async {
    if (isSyncing || !hasSyncScope) return;
    final pending = pendingWeights.where(
      (item) => item.record.id == record.id && item.needsReview,
    );
    if (pending.isEmpty) return;
    final remote = weights.where(
      (item) =>
          item.isRemote && item.clientOperationId == record.clientOperationId,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revisar pesagem pendente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'O envio foi recusado ou o servidor retornou dados diferentes. '
                'O Atlas não repetirá esta operação automaticamente.',
              ),
              const SizedBox(height: 12),
              Text(
                'Neste dispositivo: ${formatWeight(record.weight)} kg em ${record.date}',
              ),
              if (record.notes.isNotEmpty) Text('Observação: ${record.notes}'),
              if (remote.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'No servidor: ${formatWeight(remote.first.weight)} kg em ${remote.first.date}',
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Confira o histórico e os dados da fazenda antes de decidir. '
                'Remover a pendência apaga apenas a cópia deste dispositivo; '
                'não altera o servidor.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Manter pendente'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remover cópia local'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final remove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar remoção local'),
        content: const Text(
          'Esta pesagem pode existir somente neste dispositivo. '
          'Se remover a pendência, os dados locais não poderão ser recuperados pelo Atlas. '
          'Confirme apenas após conferir o histórico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar remoção local'),
          ),
        ],
      ),
    );
    if (remove != true || !mounted) return;
    final remaining = weights
        .where((item) => item.isRemote || item.id != record.id)
        .toList();
    try {
      await storage.saveWeights(
        farmName: widget.farm.name,
        farmId: farmId,
        groupName: widget.group.name,
        animalId: animalId,
        weights: remaining,
      );
      await outbox.remove(
        companyId: companyId,
        farmId: farmId,
        animalId: animalId,
        operationId: record.clientOperationId,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível remover a pendência local. Nenhum envio foi repetido.',
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      weights = remaining;
      pendingWeights.removeWhere(
        (item) => item.record.clientOperationId == record.clientOperationId,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Pendência local removida. O histórico do servidor não foi alterado.',
        ),
      ),
    );
  }

  double? calculateVariation(int index) {
    if (index >= weights.length - 1) {
      return null;
    }

    return weights[index].weight - weights[index + 1].weight;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesagens')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading ? null : openWeightForm,
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova pesagem'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        widget.animal.displayName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Brinco ${widget.animal.tag} · '
                        '${widget.farm.name}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 24),
                      if (pendingWeights.isNotEmpty) ...[
                        Card(
                          color: const Color(0xFFFFF5E8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                Text(
                                  '${pendingWeights.length} pesagem(ns) salva(s) neste dispositivo, aguardando confirmação. '
                                  '${pendingWeights.where((item) => item.needsReview).length} requer(em) revisão.'
                                  '${syncNotice.isEmpty ? '' : '\n$syncNotice'}'
                                  '${pendingWeights.any((item) => item.needsReview) ? '\nConfira o histórico antes de registrar novamente uma pesagem em revisão.' : ''}',
                                ),
                                TextButton.icon(
                                  onPressed: isSyncing ? null : loadWeights,
                                  icon: const Icon(Icons.sync),
                                  label: const Text('Tentar sincronizar'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          WeightSummaryCard(
                            title: 'Peso atual',
                            value: '${formatWeight(currentWeight)} kg',
                            icon: Icons.monitor_weight_outlined,
                          ),
                          WeightSummaryCard(
                            title: 'Menor peso',
                            value: '${formatWeight(minimumWeight)} kg',
                            icon: Icons.south_east_outlined,
                          ),
                          WeightSummaryCard(
                            title: 'Maior peso',
                            value: '${formatWeight(maximumWeight)} kg',
                            icon: Icons.north_east_outlined,
                          ),
                          WeightSummaryCard(
                            title: 'Última variação',
                            value: latestVariation == null
                                ? '—'
                                : formatVariation(latestVariation!),
                            icon: latestVariation == null
                                ? Icons.horizontal_rule
                                : latestVariation! >= 0
                                ? Icons.trending_up_outlined
                                : Icons.trending_down_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Histórico de pesagens',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Acompanhe a evolução do peso ao longo do tempo.',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      if (weights.isEmpty)
                        const EmptyWeightsMessage()
                      else
                        ...List.generate(weights.length, (index) {
                          final record = weights[index];
                          final variation = calculateVariation(index);
                          final pending = record.isRemote
                              ? <PendingAnimalWeight>[]
                              : pendingWeights
                                    .where(
                                      (item) =>
                                          item
                                              .record
                                              .clientOperationId
                                              .isNotEmpty &&
                                          item.record.clientOperationId ==
                                              record.clientOperationId,
                                    )
                                    .toList();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: WeightRecordCard(
                              record: record,
                              variation: variation,
                              isPending: pending.isNotEmpty,
                              needsReview:
                                  pending.isNotEmpty &&
                                  pending.first.needsReview,
                              onEdit: () {
                                editWeight(record);
                              },
                              onDelete: () {
                                deleteWeight(record);
                              },
                              onReview: () => reviewPendingWeight(record),
                            ),
                          );
                        }),
                      const SizedBox(height: 80),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class WeightSummaryCard extends StatelessWidget {
  const WeightSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 215,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 27, color: const Color(0xFF1B5E20)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(title, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WeightRecordCard extends StatelessWidget {
  const WeightRecordCard({
    required this.record,
    required this.variation,
    this.isPending = false,
    this.needsReview = false,
    required this.onEdit,
    required this.onDelete,
    this.onReview,
    super.key,
  });

  final AnimalWeightData record;
  final double? variation;
  final bool isPending;
  final bool needsReview;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final bool isPositive = (variation ?? 0) >= 0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: needsReview
            ? onReview
            : isPending
            ? null
            : onEdit,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.monitor_weight_outlined,
                  color: Color(0xFF1B5E20),
                  size: 30,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${formatWeight(record.weight)} kg',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isPending) ...[
                      const SizedBox(height: 5),
                      Text(
                        needsReview
                            ? 'Envio requer revisão'
                            : 'Salva no dispositivo · envio pendente',
                        style: TextStyle(
                          color: needsReview
                              ? Colors.red.shade700
                              : const Color(0xFF8A5900),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (needsReview && onReview != null)
                        TextButton.icon(
                          onPressed: onReview,
                          icon: const Icon(Icons.rule),
                          label: const Text('Revisar pesagem'),
                        ),
                    ],
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 17,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          record.date,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                    if (record.bodyConditionScore > 0 ||
                        record.source.isNotEmpty ||
                        record.equipment.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        [
                          if (record.bodyConditionScore > 0)
                            'ECC ${formatWeight(record.bodyConditionScore)}',
                          if (record.source.isNotEmpty) record.source,
                          if (record.equipment.isNotEmpty) record.equipment,
                        ].join(' · '),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                    if (record.notes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(record.notes, style: const TextStyle(height: 1.4)),
                    ],
                  ],
                ),
              ),
              if (variation != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                        color: isPositive
                            ? const Color(0xFF1B5E20)
                            : Colors.red.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatVariation(variation!),
                        style: TextStyle(
                          color: isPositive
                              ? const Color(0xFF1B5E20)
                              : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (!isPending)
                PopupMenuButton<String>(
                  tooltip: 'Opções',
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    }

                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) {
                    return const [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, color: Color(0xFF1B5E20)),
                            SizedBox(width: 10),
                            Text('Editar pesagem'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 10),
                            Text('Excluir pesagem'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyWeightsMessage extends StatelessWidget {
  const EmptyWeightsMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(36),
        child: Column(
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              size: 60,
              color: Color(0xFF1B5E20),
            ),
            SizedBox(height: 16),
            Text(
              'Nenhuma pesagem registrada.',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Registre a primeira pesagem deste animal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

String formatWeight(double weight) {
  if (weight == weight.roundToDouble()) {
    return weight.toInt().toString();
  }

  return weight.toStringAsFixed(1).replaceAll('.', ',');
}

String formatVariation(double variation) {
  final String symbol = variation > 0 ? '+' : '';

  return '$symbol${formatWeight(variation)} kg';
}
