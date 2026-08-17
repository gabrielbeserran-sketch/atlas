import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/atlas_enterprise_50/data/services/atlas_enterprise_storage_service.dart';
import 'package:projeto_atlas/features/atlas_enterprise_50/domain/models/atlas_enterprise_record.dart';
import 'package:projeto_atlas/features/atlas_enterprise_50/domain/services/atlas_enterprise_analytics_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AtlasEnterprise50Screen extends StatefulWidget {
  const AtlasEnterprise50Screen({
    required this.animal,
    required this.farm,
    required this.group,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;

  @override
  State<AtlasEnterprise50Screen> createState() =>
      _AtlasEnterprise50ScreenState();
}

class _AtlasEnterprise50ScreenState extends State<AtlasEnterprise50Screen> {
  final AtlasEnterpriseStorageService storage = AtlasEnterpriseStorageService();
  final AtlasEnterpriseAnalyticsService analyticsService =
      const AtlasEnterpriseAnalyticsService();

  List<AtlasEnterpriseRecord> records = [];
  int selectedPackageId = 31;
  bool loading = true;

  static const packages = <AtlasEnterprisePackage>[
    AtlasEnterprisePackage(
      id: 31,
      title: 'Inteligência Financeira',
      subtitle: 'Fluxo de caixa, DRE, custos, margem e simulação econômica.',
      capabilities: [
        AtlasEnterpriseCapability(
          id: 1,
          title: 'Fluxo de caixa inteligente',
          description: 'Entradas, saídas, saldo projetado e alertas.',
        ),
        AtlasEnterpriseCapability(
          id: 2,
          title: 'DRE automática',
          description: 'Receitas, despesas, resultado e EBITDA pecuário.',
        ),
        AtlasEnterpriseCapability(
          id: 3,
          title: 'Centro de custos',
          description: 'Custos por lote, animal, categoria e atividade.',
        ),
        AtlasEnterpriseCapability(
          id: 4,
          title: 'Margem por animal',
          description: 'Custo, receita, lucro e retorno individual.',
        ),
        AtlasEnterpriseCapability(
          id: 5,
          title: 'Simulador econômico',
          description: 'Cenários de desempenho e impacto financeiro.',
        ),
      ],
    ),
    AtlasEnterprisePackage(
      id: 32,
      title: 'Reprodução Enterprise',
      subtitle: 'IATF, protocolos, diagnósticos, indicadores e calendário.',
      capabilities: [
        AtlasEnterpriseCapability(
          id: 6,
          title: 'IATF completa',
          description: 'Planejamento, execução, sêmen, técnico e resultado.',
        ),
        AtlasEnterpriseCapability(
          id: 7,
          title: 'Protocolos hormonais',
          description: 'Etapas, produtos, doses, horários e custos.',
        ),
        AtlasEnterpriseCapability(
          id: 8,
          title: 'Diagnóstico de gestação',
          description: 'Resultados, idade gestacional e perdas.',
        ),
        AtlasEnterpriseCapability(
          id: 9,
          title: 'Taxa de prenhez automática',
          description: 'Prenhez, concepção e serviço por concepção.',
        ),
        AtlasEnterpriseCapability(
          id: 10,
          title: 'Calendário reprodutivo inteligente',
          description: 'Próximos manejos, partos e revisões.',
        ),
      ],
    ),
    AtlasEnterprisePackage(
      id: 33,
      title: 'Sanidade Enterprise',
      subtitle:
          'Calendário, vacinação, medicamentos, carência e mapa sanitário.',
      capabilities: [
        AtlasEnterpriseCapability(
          id: 11,
          title: 'Calendário sanitário',
          description: 'Protocolos preventivos por categoria e lote.',
        ),
        AtlasEnterpriseCapability(
          id: 12,
          title: 'Vacinação automática',
          description: 'Campanhas, reforços, responsáveis e cobertura.',
        ),
        AtlasEnterpriseCapability(
          id: 13,
          title: 'Controle de medicamentos',
          description: 'Produto, dose, estoque, lote e validade.',
        ),
        AtlasEnterpriseCapability(
          id: 14,
          title: 'Carência automática',
          description: 'Bloqueio sanitário para leite, carne e venda.',
        ),
        AtlasEnterpriseCapability(
          id: 15,
          title: 'Mapa sanitário da fazenda',
          description: 'Ocorrências, risco e distribuição por lote.',
        ),
      ],
    ),
    AtlasEnterprisePackage(
      id: 34,
      title: 'Nutrição Enterprise',
      subtitle:
          'Dietas, consumo, conversão, comparação e inteligência nutricional.',
      capabilities: [
        AtlasEnterpriseCapability(
          id: 16,
          title: 'Formulação de dietas',
          description: 'Ingredientes, matéria seca, nutrientes e custo.',
        ),
        AtlasEnterpriseCapability(
          id: 17,
          title: 'Consumo diário',
          description: 'Previsto, realizado, sobras e desvios.',
        ),
        AtlasEnterpriseCapability(
          id: 18,
          title: 'Conversão alimentar',
          description: 'Consumo por unidade de ganho e eficiência.',
        ),
        AtlasEnterpriseCapability(
          id: 19,
          title: 'Comparador de dietas',
          description: 'Custo, desempenho e retorno entre estratégias.',
        ),
        AtlasEnterpriseCapability(
          id: 20,
          title: 'IA nutricional',
          description: 'Recomendações por categoria, peso e objetivo.',
        ),
      ],
    ),
    AtlasEnterprisePackage(
      id: 35,
      title: 'Consultoria Enterprise',
      subtitle:
          'Diagnóstico, plano de ação, prioridade, riscos e consultor IA.',
      capabilities: [
        AtlasEnterpriseCapability(
          id: 21,
          title: 'Diagnóstico completo da fazenda',
          description: 'Avaliação técnica, econômica e operacional.',
        ),
        AtlasEnterpriseCapability(
          id: 22,
          title: 'Plano de ação automático',
          description: 'Ações, responsáveis, prazos e evidências.',
        ),
        AtlasEnterpriseCapability(
          id: 23,
          title: 'Priorização econômica',
          description: 'Impacto, urgência, esforço e retorno.',
        ),
        AtlasEnterpriseCapability(
          id: 24,
          title: 'Radar de riscos',
          description: 'Riscos sanitários, produtivos e financeiros.',
        ),
        AtlasEnterpriseCapability(
          id: 25,
          title: 'Consultor IA',
          description: 'Orientação explicável baseada nos dados disponíveis.',
        ),
      ],
    ),
    AtlasEnterprisePackage(
      id: 36,
      title: 'Business Intelligence',
      subtitle: 'Dashboard, KPIs, comparações, benchmark e metas.',
      capabilities: [
        AtlasEnterpriseCapability(
          id: 26,
          title: 'Dashboard executivo',
          description: 'Visão integrada de desempenho e risco.',
        ),
        AtlasEnterpriseCapability(
          id: 27,
          title: 'KPIs personalizados',
          description: 'Indicadores configuráveis por objetivo.',
        ),
        AtlasEnterpriseCapability(
          id: 28,
          title: 'Comparação entre fazendas',
          description: 'Resultados, eficiência e evolução.',
        ),
        AtlasEnterpriseCapability(
          id: 29,
          title: 'Benchmark nacional',
          description: 'Referências por sistema, região e categoria.',
        ),
        AtlasEnterpriseCapability(
          id: 30,
          title: 'Metas inteligentes',
          description: 'Metas, tolerâncias e acompanhamento automático.',
        ),
      ],
    ),
    AtlasEnterprisePackage(
      id: 37,
      title: 'Gestão de Pessoas',
      subtitle: 'Equipe, escalas, treinamento, produtividade e custos.',
      capabilities: [
        AtlasEnterpriseCapability(
          id: 31,
          title: 'Funcionários',
          description: 'Cadastro, função, contato e situação.',
        ),
        AtlasEnterpriseCapability(
          id: 32,
          title: 'Escalas',
          description: 'Jornadas, turnos, folgas e cobertura.',
        ),
        AtlasEnterpriseCapability(
          id: 33,
          title: 'Treinamentos',
          description: 'Capacitações, validade e evidências.',
        ),
        AtlasEnterpriseCapability(
          id: 34,
          title: 'Produtividade',
          description: 'Entregas, qualidade, tempo e retrabalho.',
        ),
        AtlasEnterpriseCapability(
          id: 35,
          title: 'Custos de mão de obra',
          description: 'Custo por atividade, lote e resultado.',
        ),
      ],
    ),
    AtlasEnterprisePackage(
      id: 38,
      title: 'Máquinas e Infraestrutura',
      subtitle: 'Ativos, manutenção, combustível, implementos e custos.',
      capabilities: [
        AtlasEnterpriseCapability(
          id: 36,
          title: 'Máquinas',
          description: 'Cadastro, horas, situação e responsável.',
        ),
        AtlasEnterpriseCapability(
          id: 37,
          title: 'Manutenção preventiva',
          description: 'Planos, vencimentos, peças e execução.',
        ),
        AtlasEnterpriseCapability(
          id: 38,
          title: 'Combustível',
          description: 'Abastecimentos, consumo e eficiência.',
        ),
        AtlasEnterpriseCapability(
          id: 39,
          title: 'Implementos',
          description: 'Vínculos, disponibilidade e histórico.',
        ),
        AtlasEnterpriseCapability(
          id: 40,
          title: 'Custos operacionais',
          description: 'Custo por hora, atividade e equipamento.',
        ),
      ],
    ),
    AtlasEnterprisePackage(
      id: 39,
      title: 'Inteligência Artificial Avançada',
      subtitle:
          'Assistência veterinária, diagnóstico, planejamento e estratégia.',
      capabilities: [
        AtlasEnterpriseCapability(
          id: 41,
          title: 'Atlas GPT Veterinário',
          description: 'Copiloto técnico com respostas contextualizadas.',
        ),
        AtlasEnterpriseCapability(
          id: 42,
          title: 'IA de diagnóstico',
          description: 'Sinais, hipóteses, evidências e próximos exames.',
        ),
        AtlasEnterpriseCapability(
          id: 43,
          title: 'IA de planejamento',
          description: 'Planos anuais, mensais e semanais.',
        ),
        AtlasEnterpriseCapability(
          id: 44,
          title: 'IA econômica',
          description: 'Cenários, impacto, retorno e sensibilidade.',
        ),
        AtlasEnterpriseCapability(
          id: 45,
          title: 'IA estratégica',
          description: 'Prioridades, conflitos e decisões integradas.',
        ),
      ],
    ),
    AtlasEnterprisePackage(
      id: 40,
      title: 'Plataforma Enterprise',
      subtitle:
          'Offline, sincronização, multiusuário, portal web e Central 360.',
      capabilities: [
        AtlasEnterpriseCapability(
          id: 46,
          title: 'Aplicativo offline completo',
          description: 'Operação sem internet e fila local.',
        ),
        AtlasEnterpriseCapability(
          id: 47,
          title: 'Sincronização automática',
          description: 'Push, pull, conflito, versão e auditoria.',
        ),
        AtlasEnterpriseCapability(
          id: 48,
          title: 'Multiusuário em tempo real',
          description: 'Presença, alterações e permissões.',
        ),
        AtlasEnterpriseCapability(
          id: 49,
          title: 'Portal web do produtor',
          description: 'Acesso responsivo para gestão e relatórios.',
        ),
        AtlasEnterpriseCapability(
          id: 50,
          title: 'Central Atlas 360',
          description: 'Painel único de toda a operação pecuária.',
        ),
      ],
    ),
  ];

  AtlasEnterprisePackage get selectedPackage =>
      packages.firstWhere((item) => item.id == selectedPackageId);

  List<AtlasEnterpriseRecord> get selectedRecords =>
      records.where((record) => record.packageId == selectedPackageId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  AtlasEnterpriseAnalytics get selectedAnalytics => analyticsService.analyze(
    records: selectedRecords,
    totalCapabilities: selectedPackage.capabilities.length,
  );

  AtlasEnterpriseAnalytics get globalAnalytics =>
      analyticsService.analyze(records: records, totalCapabilities: 50);

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() => loading = true);
    }
    final loaded = await storage.load(
      farmName: widget.farm.name,
      animalId: widget.animal.id,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      records = loaded;
      loading = false;
    });
  }

  Future<void> save() async {
    await storage.save(
      farmName: widget.farm.name,
      animalId: widget.animal.id,
      records: records,
    );
  }

  Future<void> addRecord([AtlasEnterpriseCapability? capability]) async {
    final result = await showDialog<AtlasEnterpriseRecord>(
      context: context,
      builder: (context) => _EnterpriseRecordDialog(
        package: selectedPackage,
        capability: capability,
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() => records.add(result));
    await save();
  }

  Future<void> editRecord(AtlasEnterpriseRecord record) async {
    final result = await showDialog<AtlasEnterpriseRecord>(
      context: context,
      builder: (context) =>
          _EnterpriseRecordDialog(package: selectedPackage, existing: record),
    );
    if (result == null || !mounted) {
      return;
    }
    final index = records.indexWhere((item) => item.id == record.id);
    if (index < 0) {
      return;
    }
    setState(() => records[index] = result);
    await save();
  }

  Future<void> deleteRecord(AtlasEnterpriseRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir registro'),
        content: Text('Deseja excluir “${record.title}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => records.removeWhere((item) => item.id == record.id));
    await save();
  }

  Future<Directory> _downloadsDirectory() async {
    final home =
        Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        Directory.current.path;
    final downloads = Directory('$home${Platform.pathSeparator}Downloads');
    if (!downloads.existsSync()) {
      await downloads.create(recursive: true);
    }
    return downloads;
  }

  Future<void> exportCsv() async {
    final directory = await _downloadsDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}atlas_enterprise_50.csv',
    );
    final buffer = StringBuffer(
      'pacote;passo;titulo;data;quantidade;valor_unitario;valor_total;status;observacoes\n',
    );
    for (final record in records) {
      String clean(String value) =>
          value.replaceAll(';', ',').replaceAll('\n', ' ');
      buffer.writeln(
        '${record.packageId};${record.stepId};${clean(record.title)};${record.date};${record.quantity};${record.unitValue};${record.totalValue};${record.status};${clean(record.notes)}',
      );
    }
    await file.writeAsString(buffer.toString(), encoding: utf8);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('CSV salvo em ${file.path}')));
  }

  Future<void> backupJson() async {
    final directory = await _downloadsDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}atlas_enterprise_50_backup.json',
    );
    final payload = {
      'generatedAt': DateTime.now().toIso8601String(),
      'farm': widget.farm.name,
      'animalId': widget.animal.id,
      'animal': widget.animal.displayName,
      'records': records.map((record) => record.toMap()).toList(),
    };
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Backup salvo em ${file.path}')));
  }

  @override
  Widget build(BuildContext context) {
    final global = globalAnalytics;
    final current = selectedAnalytics;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlas Enterprise — Passos 1 a 50'),
        actions: [
          IconButton(
            onPressed: exportCsv,
            tooltip: 'Exportar CSV',
            icon: const Icon(Icons.table_view_outlined),
          ),
          IconButton(
            onPressed: backupJson,
            tooltip: 'Backup JSON',
            icon: const Icon(Icons.backup_outlined),
          ),
          IconButton(
            onPressed: load,
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: loading ? null : () => addRecord(),
        icon: const Icon(Icons.add),
        label: const Text('Novo registro'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      EnterpriseModuleHeader(
                        title: 'Central Atlas Enterprise 50',
                        subtitle:
                            '${widget.farm.name} • ${widget.animal.displayName} • 10 pacotes e 50 funcionalidades',
                        icon: Icons.hub_outlined,
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          EnterpriseMetricCard(
                            title: 'Cobertura global',
                            value:
                                '${global.progressPercent.toStringAsFixed(0)}%',
                            subtitle: 'Passos com registros',
                            icon: Icons.donut_large_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Score global',
                            value: '${global.score}/100',
                            subtitle: 'Cobertura, conclusão e alertas',
                            icon: Icons.workspace_premium_outlined,
                            warning: global.score < 50,
                          ),
                          EnterpriseMetricCard(
                            title: 'Registros',
                            value: '${global.totalRecords}',
                            subtitle: 'Base operacional integrada',
                            icon: Icons.storage_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Alertas',
                            value: '${global.alertRecords}',
                            subtitle: 'Atenção e críticos',
                            icon: Icons.warning_amber_outlined,
                            warning: global.alertRecords > 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Valor movimentado',
                            value: _money(global.totalValue),
                            subtitle: 'Soma dos registros',
                            icon: Icons.payments_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _PackageSelector(
                        packages: packages,
                        selectedId: selectedPackageId,
                        onSelected: (id) =>
                            setState(() => selectedPackageId = id),
                      ),
                      const SizedBox(height: 22),
                      EnterpriseModuleHeader(
                        title:
                            'Pacote ${selectedPackage.id} — ${selectedPackage.title}',
                        subtitle: selectedPackage.subtitle,
                        icon: _packageIcon(selectedPackage.id),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          EnterpriseMetricCard(
                            title: 'Progresso',
                            value:
                                '${current.progressPercent.toStringAsFixed(0)}%',
                            subtitle: 'Cobertura das 5 funcionalidades',
                            icon: Icons.track_changes_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Concluídos',
                            value: '${current.completedRecords}',
                            subtitle: 'Registros finalizados',
                            icon: Icons.task_alt_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Alertas',
                            value: '${current.alertRecords}',
                            subtitle: 'Registros que exigem atenção',
                            icon: Icons.priority_high_outlined,
                            warning: current.alertRecords > 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Valor',
                            value: _money(current.totalValue),
                            subtitle: 'Impacto econômico registrado',
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      EnterpriseInsightCard(
                        title: 'Inteligência do pacote',
                        icon: Icons.psychology_outlined,
                        items: current.recommendations,
                      ),
                      const SizedBox(height: 22),
                      const EnterpriseSectionTitle(
                        'Funcionalidades',
                        'Cada passo aceita registros, status, quantidade, valor e evidências.',
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 1000
                              ? 3
                              : constraints.maxWidth >= 650
                              ? 2
                              : 1;
                          return GridView.count(
                            crossAxisCount: columns,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: columns == 1 ? 3.1 : 1.5,
                            children: selectedPackage.capabilities.map((
                              capability,
                            ) {
                              final count = selectedRecords
                                  .where(
                                    (record) => record.stepId == capability.id,
                                  )
                                  .length;
                              return Card(
                                child: InkWell(
                                  onTap: () => addRecord(capability),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              child: Text('${capability.id}'),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                capability.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Chip(label: Text('$count')),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Expanded(
                                          child: Text(
                                            capability.description,
                                            style: const TextStyle(
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                        const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Icon(
                                              Icons.add_circle_outline,
                                              size: 18,
                                            ),
                                            SizedBox(width: 5),
                                            Text('Adicionar registro'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      EnterpriseSectionTitle(
                        'Histórico do Pacote ${selectedPackage.id}',
                        '${selectedRecords.length} registro(s) cadastrados.',
                      ),
                      const SizedBox(height: 12),
                      if (selectedRecords.isEmpty)
                        const Card(
                          child: ListTile(
                            title: Text('Nenhum registro neste pacote.'),
                            subtitle: Text(
                              'Clique em uma funcionalidade para iniciar.',
                            ),
                          ),
                        )
                      else
                        ...selectedRecords.map(
                          (record) => _RecordCard(
                            record: record,
                            onEdit: () => editRecord(record),
                            onDelete: () => deleteRecord(record),
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

  String _money(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

class _PackageSelector extends StatelessWidget {
  const _PackageSelector({
    required this.packages,
    required this.selectedId,
    required this.onSelected,
  });
  final List<AtlasEnterprisePackage> packages;
  final int selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 3.8,
          children: packages.map((package) {
            final selected = package.id == selectedId;
            return FilledButton.tonalIcon(
              onPressed: () => onSelected(package.id),
              icon: Icon(_packageIcon(package.id), size: 17),
              label: Text(
                '${package.id} • ${package.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: selected ? const Color(0xFF1B5E20) : null,
                foregroundColor: selected ? Colors.white : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });
  final AtlasEnterpriseRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = record.isAlert
        ? Colors.orange.shade800
        : record.isCompleted
        ? Colors.green.shade800
        : Colors.blueGrey;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Text('${record.stepId}', style: TextStyle(color: color)),
        ),
        title: Text(record.title),
        subtitle: Text(
          '${record.date} • ${record.status} • Qtd. ${record.quantity.toStringAsFixed(2)} • Valor R\$ ${record.totalValue.toStringAsFixed(2)}${record.notes.isEmpty ? '' : '\n${record.notes}'}',
        ),
        isThreeLine: record.notes.isNotEmpty,
        trailing: PopupMenuButton<String>(
          onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Excluir')),
          ],
        ),
      ),
    );
  }
}

class _EnterpriseRecordDialog extends StatefulWidget {
  const _EnterpriseRecordDialog({
    required this.package,
    this.capability,
    this.existing,
  });
  final AtlasEnterprisePackage package;
  final AtlasEnterpriseCapability? capability;
  final AtlasEnterpriseRecord? existing;

  @override
  State<_EnterpriseRecordDialog> createState() =>
      _EnterpriseRecordDialogState();
}

class _EnterpriseRecordDialogState extends State<_EnterpriseRecordDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController title;
  late final TextEditingController date;
  late final TextEditingController quantity;
  late final TextEditingController unitValue;
  late final TextEditingController notes;
  late int stepId;
  late String status;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    stepId =
        existing?.stepId ??
        widget.capability?.id ??
        widget.package.capabilities.first.id;
    status = existing?.status ?? 'Planejado';
    title = TextEditingController(
      text: existing?.title ?? widget.capability?.title ?? '',
    );
    date = TextEditingController(text: existing?.date ?? _today());
    quantity = TextEditingController(
      text: existing == null ? '1' : existing.quantity.toString(),
    );
    unitValue = TextEditingController(
      text: existing == null ? '0' : existing.unitValue.toString(),
    );
    notes = TextEditingController(text: existing?.notes ?? '');
  }

  @override
  void dispose() {
    title.dispose();
    date.dispose();
    quantity.dispose();
    unitValue.dispose();
    notes.dispose();
    super.dispose();
  }

  double _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;

  void submit() {
    if (!formKey.currentState!.validate()) {
      return;
    }
    final now = DateTime.now().toIso8601String();
    Navigator.pop(
      context,
      AtlasEnterpriseRecord(
        id:
            widget.existing?.id ??
            'enterprise_${DateTime.now().microsecondsSinceEpoch}',
        packageId: widget.package.id,
        stepId: stepId,
        title: title.text.trim(),
        date: date.text.trim(),
        quantity: _number(quantity),
        unitValue: _number(unitValue),
        status: status,
        notes: notes.text.trim(),
        createdAt: widget.existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? 'Novo registro — Pacote ${widget.package.id}'
            : 'Editar registro',
      ),
      content: SizedBox(
        width: 620,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  initialValue: stepId,
                  decoration: const InputDecoration(
                    labelText: 'Funcionalidade',
                  ),
                  items: widget.package.capabilities
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text('${item.id} • ${item.title}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      stepId = value;
                      if (title.text.trim().isEmpty) {
                        title.text = widget.package.capabilities
                            .firstWhere((item) => item.id == value)
                            .title;
                      }
                    });
                  },
                ),
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Informe o título.'
                      : null,
                ),
                TextFormField(
                  controller: date,
                  decoration: const InputDecoration(
                    labelText: 'Data (dd/mm/aaaa)',
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: quantity,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Quantidade',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: unitValue,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Valor unitário (R\$)',
                        ),
                      ),
                    ),
                  ],
                ),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items:
                      const [
                            'Planejado',
                            'Em andamento',
                            'Concluído',
                            'Atenção',
                            'Crítico',
                          ]
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => status = value);
                    }
                  },
                ),
                TextFormField(
                  controller: notes,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Observações e evidências',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: submit, child: const Text('Salvar')),
      ],
    );
  }

  String _today() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }
}

IconData _packageIcon(int id) {
  return switch (id) {
    31 => Icons.account_balance_wallet_outlined,
    32 => Icons.favorite_outline,
    33 => Icons.health_and_safety_outlined,
    34 => Icons.restaurant_outlined,
    35 => Icons.support_agent_outlined,
    36 => Icons.analytics_outlined,
    37 => Icons.groups_outlined,
    38 => Icons.agriculture_outlined,
    39 => Icons.psychology_outlined,
    _ => Icons.cloud_sync_outlined,
  };
}
