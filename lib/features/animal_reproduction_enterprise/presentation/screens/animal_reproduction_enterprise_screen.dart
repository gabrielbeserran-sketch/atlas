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
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;

  @override
  State<AnimalReproductionEnterpriseScreen> createState() =>
      _AnimalReproductionEnterpriseScreenState();
}

class _AnimalReproductionEnterpriseScreenState
    extends State<AnimalReproductionEnterpriseScreen> {
  final AnimalReproductionStorageService storage =
      AnimalReproductionStorageService();

  List<AnimalReproductionData> records = <AnimalReproductionData>[];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() => loading = true);
    }

    final loaded = await storage.loadRecords(
      farmName: widget.farm.name,
      groupName: widget.group.name,
      animalId: widget.animal.id,
    );

    loaded.sort(
      (first, second) => parseEnterpriseDate(
        second.date,
      ).compareTo(parseEnterpriseDate(first.date)),
    );

    if (!mounted) return;

    setState(() {
      records = loaded;
      loading = false;
    });
  }

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
            onPressed: loading ? null : load,
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
                      EnterpriseModuleHeader(
                        title: 'Reprodução de ${widget.animal.displayName}',
                        subtitle:
                            'Protocolos, serviços, diagnósticos, previsão e eficiência reprodutiva.',
                        icon: Icons.favorite_outline,
                      ),
                      const SizedBox(height: 18),
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
