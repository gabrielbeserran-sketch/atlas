import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/animal_health/data/services/animal_health_storage_service.dart';
import 'package:projeto_atlas/features/animal_health/domain/models/animal_health_data.dart';
import 'package:projeto_atlas/features/animal_health/presentation/screens/animal_health_list_screen.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AnimalHealthEnterpriseScreen extends StatefulWidget {
  const AnimalHealthEnterpriseScreen({
    required this.animal,
    required this.farm,
    required this.group,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;

  @override
  State<AnimalHealthEnterpriseScreen> createState() =>
      _AnimalHealthEnterpriseScreenState();
}

class _AnimalHealthEnterpriseScreenState
    extends State<AnimalHealthEnterpriseScreen> {
  final AnimalHealthStorageService storage =
      AnimalHealthStorageService();

  List<AnimalHealthData> records = <AnimalHealthData>[];
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

  int get scheduled {
    final limit = DateTime.now().subtract(const Duration(days: 1));
    return records.where((record) {
      return record.hasScheduledReturn &&
          parseEnterpriseDate(record.nextDate).isAfter(limit);
    }).length;
  }

  int get quarantine =>
      records.where((record) => record.isQuarantine).length;

  double get cost => records.fold<double>(
        0,
        (total, record) => total + record.treatmentCost,
      );

  int get exams => records.where((record) {
        return record.type.toLowerCase().contains('exame');
      }).length;

  int get risk {
    var value = 0;

    if (quarantine > 0) value += 35;
    if (records.any(
      (record) => record.severity.toLowerCase().contains('grave'),
    )) {
      value += 30;
    }
    if (records.any((record) => record.isMortality)) {
      value += 35;
    }

    return value.clamp(0, 100).toInt();
  }

  Future<void> manage() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => AnimalHealthListScreen(
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sanidade inteligente Enterprise'),
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
        icon: const Icon(Icons.medical_services_outlined),
        label: const Text('Gerenciar sanidade'),
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
                        title:
                            'Sanidade de ${widget.animal.displayName}',
                        subtitle:
                            'Calendário, risco, custos e retornos sanitários consolidados.',
                        icon: Icons.health_and_safety_outlined,
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          EnterpriseMetricCard(
                            title: 'Registros',
                            value: '${records.length}',
                            subtitle: 'Histórico sanitário',
                            icon: Icons.fact_check_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Retornos programados',
                            value: '$scheduled',
                            subtitle:
                                'Próximas aplicações e avaliações',
                            icon: Icons.event_available_outlined,
                            warning: scheduled > 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Risco sanitário',
                            value: '$risk/100',
                            subtitle: risk >= 50
                                ? 'Requer atenção prioritária'
                                : 'Risco controlado',
                            icon: Icons.shield_outlined,
                            warning: risk >= 50,
                          ),
                          EnterpriseMetricCard(
                            title: 'Custo sanitário',
                            value: _money(cost),
                            subtitle: 'Tratamentos registrados',
                            icon: Icons.payments_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Exames',
                            value: '$exams',
                            subtitle: 'Diagnósticos e laboratoriais',
                            icon: Icons.biotech_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Quarentena',
                            value: '$quarantine',
                            subtitle: 'Ocorrências sinalizadas',
                            icon: Icons.lock_outline,
                            warning: quarantine > 0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      EnterpriseInsightCard(
                        title: 'Recomendações sanitárias',
                        items: [
                          if (records.isEmpty)
                            'Cadastre o histórico sanitário para construir o calendário preventivo.',
                          if (scheduled > 0)
                            'Existem $scheduled retornos sanitários programados; confirme produtos e estoque.',
                          if (quarantine > 0)
                            'Há registro de quarentena. Mantenha isolamento, identificação e reavaliação clínica.',
                          if (risk < 50 && records.isNotEmpty)
                            'O risco sanitário atual está controlado; mantenha o calendário e a rastreabilidade.',
                          if (cost > 0)
                            'O custo sanitário acumulado é ${_money(cost)}; compare com o desempenho produtivo.',
                        ],
                      ),
                      const SizedBox(height: 22),
                      const EnterpriseSectionTitle(
                        'Últimos manejos',
                        'Registros sanitários mais recentes.',
                      ),
                      const SizedBox(height: 12),
                      if (records.isEmpty)
                        const Card(
                          child: ListTile(
                            title: Text(
                              'Nenhum manejo sanitário cadastrado.',
                            ),
                          ),
                        )
                      else
                        ...records.take(8).map(
                              (record) => Card(
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(
                                      Icons.medical_services_outlined,
                                    ),
                                  ),
                                  title: Text(
                                    record.product.isEmpty
                                        ? record.type
                                        : record.product,
                                  ),
                                  subtitle: Text(
                                    _healthSubtitle(record),
                                  ),
                                  trailing: record.isQuarantine
                                      ? const Icon(
                                          Icons.warning_amber,
                                          color: Colors.orange,
                                        )
                                      : null,
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

  String _healthSubtitle(AnimalHealthData record) {
    final parts = <String>[record.date, record.type];

    if (record.nextDate.isNotEmpty) {
      parts.add('Retorno: ${record.nextDate}');
    }

    return parts.join(' • ');
  }

  String _money(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}
