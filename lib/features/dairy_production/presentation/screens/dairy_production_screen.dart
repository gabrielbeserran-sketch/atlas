import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_production_storage_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_herd_snapshot_storage_service.dart';
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
  final _calculator = const DairyIndicatorCalculator();
  List<DairyDailyProductionData> _records = const [];
  DairyHerdSnapshotData? _snapshot;
  bool _loading = true;

  String get _farmKey => widget.farm.id ?? widget.farm.name;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await _storage.load(_farmKey);
    final snapshots = await _snapshotStorage.load(_farmKey);
    if (mounted) {
      setState(() {
        _records = values;
        _snapshot = snapshots.isEmpty ? null : snapshots.first;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _calculator.summarize(_records, hectares: widget.farm.area);
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
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Registrar ordenha'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
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
                          : '${currency.format(summary.latestLiters)} L',
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
                      label: 'Dias com registro',
                      value: '${summary.recordedDays} nos últimos 30 dias',
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
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Histórico de ordenhas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                if (_records.isEmpty)
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
                          await _storage.delete(_farmKey, record.date);
                          await _load();
                        },
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _openForm() async {
    final result = await showDialog<DairyDailyProductionData>(
      context: context,
      builder: (_) => const _DairyRecordDialog(),
    );
    if (result == null) return;
    await _storage.upsert(_farmKey, result);
    await _load();
  }

  Future<void> _openSnapshotForm() async {
    final result = await showDialog<DairyHerdSnapshotData>(
      context: context,
      builder: (_) => const _HerdSnapshotDialog(),
    );
    if (result == null) return;
    await _snapshotStorage.upsert(_farmKey, result);
    await _load();
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
  @override
  void dispose() {
    _eligible.dispose();
    _lactating.dispose();
    _dry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Estado do lote hoje'),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _field(_eligible, 'Vacas elegíveis'),
          _field(_lactating, 'Em lactação'),
          _field(_dry, 'Secas'),
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
    validator: (v) =>
        int.tryParse(v ?? '') == null ? 'Informe um número' : null,
  );
  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
      context,
      DairyHerdSnapshotData(
        date: DateTime.now(),
        eligibleCows: int.parse(_eligible.text),
        lactatingCows: int.parse(_lactating.text),
        dryCows: int.parse(_dry.text),
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
            _field(_cows, 'Vacas ordenhadas'),
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
  }) => TextFormField(
    controller: c,
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    decoration: InputDecoration(labelText: label),
    validator: (value) {
      final n = double.tryParse((value ?? '').replaceAll(',', '.'));
      return n == null || n < 0 ? 'Informe um valor válido' : null;
    },
  );
  void _save() {
    if (!_form.currentState!.validate()) return;
    double n(TextEditingController c) =>
        double.parse(c.text.replaceAll(',', '.'));
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
