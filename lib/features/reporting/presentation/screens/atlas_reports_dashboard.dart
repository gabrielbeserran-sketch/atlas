import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/services/atlas_report_repository.dart';
import '../../domain/models/atlas_report.dart';
import '../../domain/services/atlas_report_engine.dart';

class AtlasReportsDashboard extends StatefulWidget {
  const AtlasReportsDashboard({super.key, this.farmId});

  final String? farmId;

  @override
  State<AtlasReportsDashboard> createState() => _AtlasReportsDashboardState();
}

class _AtlasReportsDashboardState extends State<AtlasReportsDashboard> {
  final AtlasReportRepository _repository = AtlasReportRepository();
  final AtlasReportEngine _engine = const AtlasReportEngine();

  List<AtlasReport> _reports = <AtlasReport>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<AtlasReport> reports = await _repository.load(
      farmId: widget.farmId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _reports = reports;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _repository.save(_reports);
  }

  String _typeLabel(AtlasReportType type) {
    switch (type) {
      case AtlasReportType.technicalVisit:
        return 'Visita técnica';
      case AtlasReportType.executive:
        return 'Executivo';
      case AtlasReportType.reproductive:
        return 'Reprodutivo';
      case AtlasReportType.productive:
        return 'Produtivo';
      case AtlasReportType.financial:
        return 'Financeiro';
      case AtlasReportType.sanitary:
        return 'Sanitário';
      case AtlasReportType.investment:
        return 'Investimentos';
      case AtlasReportType.actionPlan:
        return 'Plano de ação';
    }
  }

  String _statusLabel(AtlasReportStatus status) {
    switch (status) {
      case AtlasReportStatus.draft:
        return 'Rascunho';
      case AtlasReportStatus.ready:
        return 'Pronto';
      case AtlasReportStatus.archived:
        return 'Arquivado';
    }
  }

  Color _statusColor(AtlasReportStatus status) {
    switch (status) {
      case AtlasReportStatus.draft:
        return Colors.orange;
      case AtlasReportStatus.ready:
        return Colors.green;
      case AtlasReportStatus.archived:
        return Colors.grey;
    }
  }

  String _date(DateTime value) {
    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  Future<void> _edit([AtlasReport? current]) async {
    final TextEditingController titleController = TextEditingController(
      text: current?.title ?? '',
    );
    final TextEditingController propertyController = TextEditingController(
      text: current?.propertyName ?? '',
    );
    final TextEditingController clientController = TextEditingController(
      text: current?.clientName ?? '',
    );
    final TextEditingController periodController = TextEditingController(
      text: current?.periodLabel ?? 'Últimos 30 dias',
    );
    final TextEditingController summaryController = TextEditingController(
      text: current?.executiveSummary ?? '',
    );
    final TextEditingController recommendationsController =
        TextEditingController(text: current?.recommendations.join('\n') ?? '');

    AtlasReportType type = current?.type ?? AtlasReportType.technicalVisit;
    AtlasReportStatus status = current?.status ?? AtlasReportStatus.draft;

    final AtlasReport? result = await showDialog<AtlasReport>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setLocalState) {
            return AlertDialog(
              title: Text(
                current == null ? 'Novo relatório' : 'Editar relatório',
              ),
              content: SizedBox(
                width: 620,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Título'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: propertyController,
                        decoration: const InputDecoration(
                          labelText: 'Propriedade',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: clientController,
                        decoration: const InputDecoration(labelText: 'Cliente'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AtlasReportType>(
                        initialValue: type,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de relatório',
                        ),
                        items: AtlasReportType.values
                            .map(
                              (AtlasReportType item) =>
                                  DropdownMenuItem<AtlasReportType>(
                                    value: item,
                                    child: Text(_typeLabel(item)),
                                  ),
                            )
                            .toList(),
                        onChanged: (AtlasReportType? value) {
                          if (value != null) {
                            setLocalState(() {
                              type = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AtlasReportStatus>(
                        initialValue: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: AtlasReportStatus.values
                            .map(
                              (AtlasReportStatus item) =>
                                  DropdownMenuItem<AtlasReportStatus>(
                                    value: item,
                                    child: Text(_statusLabel(item)),
                                  ),
                            )
                            .toList(),
                        onChanged: (AtlasReportStatus? value) {
                          if (value != null) {
                            setLocalState(() {
                              status = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: periodController,
                        decoration: const InputDecoration(labelText: 'Período'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: summaryController,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Resumo executivo',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: recommendationsController,
                        minLines: 3,
                        maxLines: 7,
                        decoration: const InputDecoration(
                          labelText: 'Recomendações',
                          helperText: 'Digite uma recomendação por linha.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty ||
                        propertyController.text.trim().isEmpty) {
                      return;
                    }

                    final DateTime now = DateTime.now();
                    Navigator.of(dialogContext).pop(
                      AtlasReport(
                        id:
                            current?.id ??
                            now.microsecondsSinceEpoch.toString(),
                        farmId: widget.farmId,
                        title: titleController.text.trim(),
                        propertyName: propertyController.text.trim(),
                        clientName: clientController.text.trim(),
                        type: type,
                        status: status,
                        createdAt: current?.createdAt ?? now,
                        updatedAt: now,
                        periodLabel: periodController.text.trim(),
                        executiveSummary: summaryController.text.trim(),
                        recommendations: recommendationsController.text
                            .split('\n')
                            .map((String item) => item.trim())
                            .where((String item) => item.isNotEmpty)
                            .toList(),
                        kpis: current?.kpis ?? const <String, double>{},
                      ),
                    );
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    propertyController.dispose();
    clientController.dispose();
    periodController.dispose();
    summaryController.dispose();
    recommendationsController.dispose();

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      final int index = _reports.indexWhere(
        (AtlasReport item) => item.id == result.id,
      );
      if (index < 0) {
        _reports = <AtlasReport>[result, ..._reports];
      } else {
        final List<AtlasReport> copy = <AtlasReport>[..._reports];
        copy[index] = result;
        _reports = copy;
      }
    });
    await _save();
  }

  Future<void> _delete(AtlasReport report) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Excluir relatório'),
        content: Text('Deseja excluir “${report.title}”?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _reports = _reports
          .where((AtlasReport item) => item.id != report.id)
          .toList();
    });
    await _save();
  }

  Future<void> _preview(AtlasReport report) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
          child: Column(
            children: <Widget>[
              AppBar(
                automaticallyImplyLeading: false,
                title: const Text('Pré-visualização do relatório'),
                actions: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: _ReportPreview(report: report),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyReport(AtlasReport report) async {
    await Clipboard.setData(
      ClipboardData(text: _engine.buildPlainText(report)),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Conteúdo do relatório copiado para a área de transferência.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AtlasReportSummary summary = _engine.summarize(_reports);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Relatórios e Documentos'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Novo relatório'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      _MetricCard(
                        label: 'Documentos',
                        value: '${summary.total}',
                        icon: Icons.description_outlined,
                      ),
                      _MetricCard(
                        label: 'Prontos',
                        value: '${summary.ready}',
                        icon: Icons.task_alt_outlined,
                      ),
                      _MetricCard(
                        label: 'Rascunhos',
                        value: '${summary.drafts}',
                        icon: Icons.edit_note_outlined,
                      ),
                      _MetricCard(
                        label: 'Arquivados',
                        value: '${summary.archived}',
                        icon: Icons.inventory_2_outlined,
                      ),
                      _MetricCard(
                        label: 'Média dos KPIs',
                        value: summary.averageKpi.toStringAsFixed(1),
                        icon: Icons.analytics_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Biblioteca de relatórios',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Crie, revise e prepare documentos técnicos da Beserra Consultoria Veterinária.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 14),
                  if (_reports.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(
                          child: Text('Nenhum relatório cadastrado.'),
                        ),
                      ),
                    )
                  else
                    ..._reports.map(
                      (AtlasReport report) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          report.title,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${report.propertyName} • ${_typeLabel(report.type)}',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Chip(
                                    label: Text(_statusLabel(report.status)),
                                    side: BorderSide.none,
                                    backgroundColor: _statusColor(
                                      report.status,
                                    ).withValues(alpha: 0.12),
                                    labelStyle: TextStyle(
                                      color: _statusColor(report.status),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (String value) {
                                      if (value == 'edit') {
                                        _edit(report);
                                      } else if (value == 'delete') {
                                        _delete(report);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) =>
                                        const <PopupMenuEntry<String>>[
                                          PopupMenuItem<String>(
                                            value: 'edit',
                                            child: Text('Editar'),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Text('Excluir'),
                                          ),
                                        ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: <Widget>[
                                  Text('Período: ${report.periodLabel}'),
                                  Text(
                                    'Atualizado em ${_date(report.updatedAt)}',
                                  ),
                                  Text(
                                    '${report.recommendations.length} recomendações',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: <Widget>[
                                  OutlinedButton.icon(
                                    onPressed: () => _preview(report),
                                    icon: const Icon(Icons.visibility_outlined),
                                    label: const Text('Pré-visualizar'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _copyReport(report),
                                    icon: const Icon(Icons.copy_outlined),
                                    label: const Text('Copiar conteúdo'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Documento preparado. A geração real em PDF será conectada na próxima etapa.',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.picture_as_pdf_outlined,
                                    ),
                                    label: const Text('Preparar PDF'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(label, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportPreview extends StatelessWidget {
  const _ReportPreview({required this.report});

  final AtlasReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'BESERRA CONSULTORIA VETERINÁRIA',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const Divider(height: 28),
        Text(
          report.title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        Text('Propriedade: ${report.propertyName}'),
        Text(
          'Cliente: ${report.clientName.isEmpty ? 'Não informado' : report.clientName}',
        ),
        Text('Período: ${report.periodLabel}'),
        const SizedBox(height: 24),
        const Text(
          'Resumo executivo',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          report.executiveSummary.isEmpty
              ? 'Nenhum resumo informado.'
              : report.executiveSummary,
          style: const TextStyle(height: 1.5),
        ),
        const SizedBox(height: 24),
        const Text(
          'Indicadores',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (report.kpis.isEmpty)
          const Text('Nenhum indicador vinculado.')
        else
          ...report.kpis.entries.map(
            (MapEntry<String, double> entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(entry.key),
              trailing: Text(
                entry.value.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        const SizedBox(height: 18),
        const Text(
          'Recomendações',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (report.recommendations.isEmpty)
          const Text('Nenhuma recomendação registrada.')
        else
          ...report.recommendations.asMap().entries.map(
            (MapEntry<int, String> entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${entry.key + 1}. ${entry.value}'),
            ),
          ),
        const SizedBox(height: 30),
        const Divider(),
        const Text(
          'Documento preparado pelo Atlas para a Beserra Consultoria Veterinária.',
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}
