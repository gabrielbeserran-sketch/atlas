import 'package:flutter/material.dart';
import '../../data/services/atlas_consultancy_repository.dart';
import '../../domain/models/atlas_consultancy_record.dart';
import '../../domain/services/atlas_consultancy_engine.dart';

class AtlasConsultancyDashboard extends StatefulWidget {
  const AtlasConsultancyDashboard({super.key});
  @override
  State<AtlasConsultancyDashboard> createState() =>
      _AtlasConsultancyDashboardState();
}

class _AtlasConsultancyDashboardState extends State<AtlasConsultancyDashboard> {
  final _repository = AtlasConsultancyRepository();
  final _engine = const AtlasConsultancyEngine();
  List<AtlasConsultancyRecord> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repository.load();
    items.sort((a, b) => a.nextVisit.compareTo(b.nextVisit));
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _save() => _repository.save(_items);
  String _money(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';
  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _status(AtlasClientStatus s) => switch (s) {
    AtlasClientStatus.active => 'Ativo',
    AtlasClientStatus.attention => 'Atenção',
    AtlasClientStatus.inactive => 'Inativo',
  };
  Color _statusColor(AtlasClientStatus s) => switch (s) {
    AtlasClientStatus.active => Colors.green,
    AtlasClientStatus.attention => Colors.orange,
    AtlasClientStatus.inactive => Colors.grey,
  };

  Future<void> _edit([AtlasConsultancyRecord? current]) async {
    final client = TextEditingController(text: current?.clientName ?? '');
    final property = TextEditingController(text: current?.propertyName ?? '');
    final phone = TextEditingController(text: current?.phone ?? '');
    final city = TextEditingController(text: current?.city ?? '');
    final fee = TextEditingController(
      text: (current?.monthlyFee ?? 0).toStringAsFixed(2),
    );
    final notes = TextEditingController(text: current?.notes ?? '');
    var status = current?.status ?? AtlasClientStatus.active;
    var visit =
        current?.nextVisit ?? DateTime.now().add(const Duration(days: 7));

    final result = await showDialog<AtlasConsultancyRecord>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(current == null ? 'Novo cliente' : 'Editar cliente'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: client,
                    decoration: const InputDecoration(
                      labelText: 'Nome do produtor',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: property,
                    decoration: const InputDecoration(labelText: 'Propriedade'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phone,
                    decoration: const InputDecoration(labelText: 'Telefone'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: city,
                    decoration: const InputDecoration(labelText: 'Cidade/UF'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AtlasClientStatus>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Situação'),
                    items: AtlasClientStatus.values
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(_status(e)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setLocal(() => status = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fee,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Mensalidade',
                      prefixText: 'R\$ ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notes,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observações técnicas',
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Próxima visita'),
                    subtitle: Text(_date(visit)),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: visit,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 1825),
                        ),
                      );
                      if (d != null) setLocal(() => visit = d);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (client.text.trim().isEmpty ||
                    property.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  AtlasConsultancyRecord(
                    id:
                        current?.id ??
                        DateTime.now().microsecondsSinceEpoch.toString(),
                    clientName: client.text.trim(),
                    propertyName: property.text.trim(),
                    phone: phone.text.trim(),
                    city: city.text.trim(),
                    status: status,
                    nextVisit: visit,
                    executiveScore: current?.executiveScore ?? 70,
                    openActions: current?.openActions ?? 0,
                    monthlyFee:
                        double.tryParse(
                          fee.text.replaceAll('.', '').replaceAll(',', '.'),
                        ) ??
                        0,
                    notes: notes.text.trim(),
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    for (final c in [client, property, phone, city, fee, notes]) {
      c.dispose();
    }
    if (result == null || !mounted) return;
    setState(() {
      final i = _items.indexWhere((e) => e.id == result.id);
      if (i < 0) {
        _items = [..._items, result];
      } else {
        final copy = [..._items];
        copy[i] = result;
        _items = copy;
      }
      _items.sort((a, b) => a.nextVisit.compareTo(b.nextVisit));
    });
    await _save();
  }

  Future<void> _delete(AtlasConsultancyRecord item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Excluir cliente'),
        content: Text('Deseja excluir ${item.clientName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() => _items = _items.where((e) => e.id != item.id).toList());
      await _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _engine.summarize(_items);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Central da Consultoria'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Novo cliente'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _Metric('Clientes', '${s.total}', Icons.groups_outlined),
                      _Metric('Ativos', '${s.active}', Icons.verified_outlined),
                      _Metric('Atenção', '${s.attention}', Icons.warning_amber),
                      _Metric(
                        'Visitas em 30 dias',
                        '${s.visitsNext30Days}',
                        Icons.event_outlined,
                      ),
                      _Metric(
                        'Executive Score médio',
                        s.averageScore.toStringAsFixed(1),
                        Icons.speed,
                      ),
                      _Metric(
                        'Receita mensal',
                        _money(s.monthlyRevenue),
                        Icons.payments_outlined,
                      ),
                      _Metric(
                        'Ações abertas',
                        '${s.openActions}',
                        Icons.assignment_late_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Carteira de clientes e propriedades',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_items.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: Center(
                          child: Text('Nenhum cliente cadastrado.'),
                        ),
                      ),
                    ),
                  ..._items.map(
                    (e) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.clientName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        e.propertyName,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Chip(
                                  label: Text(_status(e.status)),
                                  backgroundColor: _statusColor(
                                    e.status,
                                  ).withValues(alpha: .12),
                                  side: BorderSide.none,
                                  labelStyle: TextStyle(
                                    color: _statusColor(e.status),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _edit(e);
                                    if (v == 'delete') _delete(e);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Editar'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Excluir'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                Text(
                                  '📍 ${e.city.isEmpty ? 'Local não informado' : e.city}',
                                ),
                                Text(
                                  '📞 ${e.phone.isEmpty ? 'Não informado' : e.phone}',
                                ),
                                Text(
                                  '📅 Próxima visita: ${_date(e.nextVisit)}',
                                ),
                                Text(
                                  '⭐ Score: ${e.executiveScore.toStringAsFixed(0)}',
                                ),
                                Text('📋 ${e.openActions} ações abertas'),
                                Text('💰 ${_money(e.monthlyFee)}/mês'),
                              ],
                            ),
                            if (e.notes.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                e.notes,
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ],
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

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon);
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 195,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    ),
  );
}
