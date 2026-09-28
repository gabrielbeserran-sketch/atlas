import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/animal_reproduction/data/services/animal_reproduction_storage_service.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/presentation/screens/animal_reproduction_list_screen.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AnimalReproductionEnterpriseScreen extends StatefulWidget {
  const AnimalReproductionEnterpriseScreen({
    required this.animal,
    required this.farm,
    required this.group,
    this.storage,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final AnimalReproductionStorageService? storage;

  @override
  State<AnimalReproductionEnterpriseScreen> createState() =>
      _AnimalReproductionEnterpriseScreenState();
}

class _AnimalReproductionEnterpriseScreenState
    extends State<AnimalReproductionEnterpriseScreen> {
  late final AnimalReproductionStorageService storage =
      widget.storage ?? AnimalReproductionStorageService();

  List<AnimalReproductionData> records = <AnimalReproductionData>[];
  bool loading = true;
  bool refreshing = false;
  bool snapshotAvailable = false;
  String? loadNotice;
  int _loadRevision = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final revision = ++_loadRevision;
    final farmId = widget.farm.id ?? '';
    ReproductionLocalSnapshot snapshot;
    try {
      snapshot = await storage.loadCachedSnapshot(
        farmId: farmId,
        animalId: widget.animal.id,
      );
    } catch (_) {
      if (mounted && revision == _loadRevision) {
        setState(() {
          loading = false;
          refreshing = false;
          snapshotAvailable = false;
          loadNotice = 'Sessão ou fazenda não autorizada para este histórico.';
        });
      }
      return;
    }
    if (!mounted || revision != _loadRevision) return;
    setState(() {
      records = _sorted(snapshot.records);
      snapshotAvailable = snapshot.available;
      loading = false;
      refreshing = true;
      loadNotice = null;
    });
    try {
      final fresh = await storage.refreshRecords(
        farmId: farmId,
        animalId: widget.animal.id,
      );
      if (!mounted || revision != _loadRevision) return;
      setState(() {
        records = _sorted(fresh);
        snapshotAvailable = true;
        loadNotice = null;
      });
    } catch (_) {
      if (!mounted || revision != _loadRevision) return;
      setState(() {
        loadNotice = !snapshot.available
            ? 'Sem conexão e sem cópia confirmada neste dispositivo.'
            : snapshot.records.isEmpty
            ? 'Sem conexão. A última leitura confirmou histórico vazio.'
            : 'Sem conexão. Exibindo a última cópia salva neste dispositivo.';
      });
    } finally {
      if (mounted && revision == _loadRevision) {
        setState(() => refreshing = false);
      }
    }
  }

  List<AnimalReproductionData> _sorted(List<AnimalReproductionData> values) =>
      [...values]..sort(
        (first, second) => parseEnterpriseDate(
          second.date,
        ).compareTo(parseEnterpriseDate(first.date)),
      );

  int get services => records.where((record) => record.isInsemination).length;

  int get positive =>
      records.where((record) => record.isPositivePregnancyDiagnosis).length;

  int get diagnoses => records.where((record) {
    return record.type == 'Diagnóstico de gestação';
  }).length;

  double get conception => diagnoses == 0 ? 0 : positive * 100 / diagnoses;

  AnimalReproductionData? get last => records.isEmpty ? null : records.first;

  String get status {
    if (records.any((record) => record.isPositivePregnancyDiagnosis)) {
      return 'Prenhe';
    }

    final current = last?.reproductiveStatus.trim() ?? '';
    return current.isEmpty ? 'Sem diagnóstico' : current;
  }

  Future<void> manage() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => AnimalReproductionListScreen(
          animal: widget.animal,
          farm: widget.farm,
          group: widget.group,
        ),
      ),
    );

    await load();
  }

  @override
  Widget build(BuildContext context) {
    final latest = last;
    final nextDate = latest?.expectedDate.trim() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reprodução Enterprise'),
        actions: [
          IconButton(
            onPressed: loading || refreshing ? null : load,
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: loading ? null : manage,
        icon: const Icon(Icons.favorite_outline),
        label: const Text('Gerenciar reprodução'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                refreshing
                                    ? Icons.cloud_sync_outlined
                                    : loadNotice == null
                                    ? Icons.cloud_done_outlined
                                    : Icons.cloud_off_outlined,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  loadNotice ??
                                      (refreshing
                                          ? snapshotAvailable
                                                ? 'Histórico local aberto. Atualizando em segundo plano…'
                                                : 'Buscando histórico em segundo plano…'
                                          : 'Histórico atualizado com o servidor.'),
                                ),
                              ),
                              if (refreshing)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      EnterpriseModuleHeader(
                        title: 'Reprodução de ${widget.animal.displayName}',
                        subtitle:
                            'Protocolos, serviços, diagnósticos, previsão e eficiência reprodutiva.',
                        icon: Icons.favorite_outline,
                      ),
                      const SizedBox(height: 18),
                      if (!snapshotAvailable)
                        Card(
                          child: ListTile(
                            title: Text(
                              refreshing
                                  ? 'Aguardando a primeira leitura confirmada.'
                                  : 'Sem base reprodutiva confirmada neste dispositivo.',
                            ),
                            subtitle: const Text(
                              'Abra o histórico conectado para obter a primeira cópia.',
                            ),
                          ),
                        ),
                      if (snapshotAvailable) ...[
                        Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            EnterpriseMetricCard(
                              title: 'Situação atual',
                              value: status,
                              subtitle: 'Último estado reprodutivo',
                              icon: Icons.monitor_heart_outlined,
                            ),
                            EnterpriseMetricCard(
                              title: 'Serviços',
                              value: '$services',
                              subtitle: 'IA e IATF registradas',
                              icon: Icons.science_outlined,
                            ),
                            EnterpriseMetricCard(
                              title: 'Diagnósticos',
                              value: '$diagnoses',
                              subtitle: 'Avaliações de gestação',
                              icon: Icons.biotech_outlined,
                            ),
                            EnterpriseMetricCard(
                              title: 'Concepção observada',
                              value:
                                  '${conception.toStringAsFixed(1).replaceAll('.', ',')}%',
                              subtitle: 'Diagnósticos positivos / diagnósticos',
                              icon: Icons.analytics_outlined,
                            ),
                            EnterpriseMetricCard(
                              title: 'Protocolos',
                              value:
                                  '${records.where((record) => record.protocolName.isNotEmpty).length}',
                              subtitle: 'Protocolos identificados',
                              icon: Icons.assignment_outlined,
                            ),
                            EnterpriseMetricCard(
                              title: 'Próxima data',
                              value: nextDate.isEmpty
                                  ? 'Não calculada'
                                  : nextDate,
                              subtitle: 'Previsão informada no manejo',
                              icon: Icons.event_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        EnterpriseInsightCard(
                          title: 'Inteligência reprodutiva',
                          items: [
                            if (records.isEmpty)
                              'Cadastre cio, serviço e diagnóstico para construir a inteligência reprodutiva.',
                            if (services > 0 && diagnoses == 0)
                              'Há serviços sem diagnóstico registrado. Programe o diagnóstico de gestação.',
                            if (diagnoses > 0 && conception < 50)
                              'A concepção observada está abaixo de 50%; revise escore corporal, protocolo, sêmen e execução.',
                            if (status == 'Prenhe')
                              'Animal identificado como prenhe. Confirme previsão de parto e calendário pré-parto.',
                            if (records.length >= 3)
                              'A base histórica já permite comparar tentativas, protocolos e resultados.',
                          ],
                        ),
                        const SizedBox(height: 22),
                        const EnterpriseSectionTitle(
                          'Histórico reprodutivo',
                          'Eventos mais recentes.',
                        ),
                        const SizedBox(height: 12),
                        if (records.isEmpty)
                          const Card(
                            child: ListTile(
                              title: Text('Nenhum registro reprodutivo.'),
                            ),
                          )
                        else
                          ...records
                              .take(10)
                              .map(
                                (record) => Card(
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      child: Icon(Icons.favorite_outline),
                                    ),
                                    title: Text(record.type),
                                    subtitle: Text(_recordSubtitle(record)),
                                  ),
                                ),
                              ),
                      ],
                      const SizedBox(height: 90),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String _recordSubtitle(AnimalReproductionData record) {
    final parts = <String>[record.date];

    if (record.result.isNotEmpty) {
      parts.add(record.result);
    }
    if (record.bullOrSemen.isNotEmpty) {
      parts.add(record.bullOrSemen);
    }

    return parts.join(' • ');
  }
}
