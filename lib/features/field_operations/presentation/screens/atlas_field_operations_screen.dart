import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/session/atlas_session_scope.dart';
import 'package:projeto_atlas/features/field_operations/data/services/atlas_field_operations_service.dart';
import 'package:projeto_atlas/features/field_operations/domain/models/atlas_field_operation.dart';

class AtlasFieldOperationsScreen extends StatefulWidget {
  const AtlasFieldOperationsScreen({super.key});

  @override
  State<AtlasFieldOperationsScreen> createState() =>
      _AtlasFieldOperationsScreenState();
}

class _AtlasFieldOperationsScreenState
    extends State<AtlasFieldOperationsScreen> {
  final _service = AtlasFieldOperationsService();
  final _entityIds = TextEditingController();
  final _notes = TextEditingController();
  final _rfid = TextEditingController();
  final _qrCode = TextEditingController();
  final _photoPath = TextEditingController();
  final _documentPath = TextEditingController();
  final _value = TextEditingController();
  String _template = 'pesagem';
  bool _saving = false;

  static const _templates = <String, String>{
    'pesagem': 'Pesagem rápida',
    'movimentacao': 'Movimentação de lote',
    'sanidade': 'Manejo sanitário',
    'reproducao': 'Evento reprodutivo',
    'nutricao': 'Registro nutricional',
    'inventario': 'Movimentação de estoque',
  };

  @override
  void dispose() {
    for (final controller in [
      _entityIds,
      _notes,
      _rfid,
      _qrCode,
      _photoPath,
      _documentPath,
      _value,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = AtlasSessionScope.of(context);
    final farm = session.activeFarm;
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.flash_on), text: 'Formulário rápido'),
            Tab(icon: Icon(Icons.groups), text: 'Ações em massa'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'RFID e QR'),
            Tab(icon: Icon(Icons.attach_file), text: 'Capturas'),
            Tab(icon: Icon(Icons.health_and_safety), text: 'Diagnóstico'),
          ],
        ),
        body: farm == null
            ? const Center(
                child: Text('Selecione uma fazenda para operar em campo.'),
              )
            : TabBarView(
                children: [
                  _form(context, bulk: false),
                  _form(context, bulk: true),
                  _identification(),
                  _attachments(),
                  _diagnostics(session),
                ],
              ),
      ),
    );
  }

  Widget _form(BuildContext context, {required bool bulk}) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          bulk ? 'Operação em massa' : 'Registro rápido de campo',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _template,
          decoration: const InputDecoration(labelText: 'Tipo de registro'),
          items: _templates.entries
              .map(
                (item) =>
                    DropdownMenuItem(value: item.key, child: Text(item.value)),
              )
              .toList(),
          onChanged: (value) => setState(() => _template = value ?? _template),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _entityIds,
          maxLines: bulk ? 4 : 1,
          decoration: InputDecoration(
            labelText: bulk
                ? 'IDs dos animais, separados por vírgula'
                : 'ID do animal ou entidade',
            helperText: bulk
                ? 'Cada ID gera uma operação idempotente independente.'
                : 'Pode ficar vazio para um novo registro.',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _value,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Valor, quantidade ou peso',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notes,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Observações de campo'),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _saving ? null : () => _save(context, bulk: bulk),
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Salvando...' : 'Salvar na fila offline'),
        ),
      ],
    );
  }

  Widget _identification() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Identificação de campo',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _rfid,
        decoration: const InputDecoration(
          labelText: 'Código RFID',
          prefixIcon: Icon(Icons.sensors),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _qrCode,
        decoration: const InputDecoration(
          labelText: 'QR Code ou código de barras',
          prefixIcon: Icon(Icons.qr_code),
        ),
      ),
      const SizedBox(height: 12),
      const Card(
        child: ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Leitura por equipamento'),
          subtitle: Text(
            'Os campos aceitam dados de leitores RFID, QR e código de barras. '
            'A integração física depende do adaptador homologado do equipamento.',
          ),
        ),
      ),
    ],
  );

  Widget _attachments() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Fotos e documentos',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _photoPath,
        decoration: const InputDecoration(
          labelText: 'Referência local da foto',
          prefixIcon: Icon(Icons.photo_camera_outlined),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _documentPath,
        decoration: const InputDecoration(
          labelText: 'Referência local do documento',
          prefixIcon: Icon(Icons.description_outlined),
        ),
      ),
      const SizedBox(height: 12),
      const Card(
        child: ListTile(
          leading: Icon(Icons.cloud_upload_outlined),
          title: Text('Envio posterior'),
          subtitle: Text(
            'Somente a referência local entra na fila. O arquivo físico será '
            'enviado por um worker quando houver conexão.',
          ),
        ),
      ),
    ],
  );

  Widget _diagnostics(session) {
    final current = session.session!;
    final farm = session.activeFarm!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Diagnóstico da operação',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _diagnosticTile(
          'Usuário',
          current.userName.isEmpty ? current.email : current.userName,
        ),
        _diagnosticTile('Empresa', current.companyId),
        _diagnosticTile('Tenant', current.tenantId),
        _diagnosticTile('Fazenda', farm.name),
        _diagnosticTile('Modo', 'Offline-first com fila idempotente'),
        _diagnosticTile(
          'Segurança',
          'Token fora do SQLite; escopo por empresa e fazenda',
        ),
      ],
    );
  }

  Widget _diagnosticTile(String title, String value) => Card(
    child: ListTile(
      title: Text(title),
      subtitle: Text(value.isEmpty ? 'Não informado' : value),
    ),
  );

  Future<void> _save(BuildContext context, {required bool bulk}) async {
    final ids = _entityIds.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (!bulk && ids.isEmpty) ids.add('');
    if (bulk && ids.isEmpty) {
      _message(context, 'Informe ao menos um ID para a operação em massa.');
      return;
    }
    setState(() => _saving = true);
    try {
      final operation = AtlasFieldOperation(
        operationType: 'create',
        entityType: 'field_$_template',
        entityIds: ids,
        payload: <String, dynamic>{
          'template': _template,
          'value': double.tryParse(_value.text.replaceAll(',', '.')),
          'notes': _notes.text.trim(),
          'rfid': _rfid.text.trim(),
          'qr_code': _qrCode.text.trim(),
          'photo_path': _photoPath.text.trim(),
          'document_path': _documentPath.text.trim(),
        },
      );
      final count = await _service.enqueue(
        AtlasSessionScope.read(context),
        operation,
      );
      if (!context.mounted) return;
      _message(context, '$count operação(ões) adicionada(s) à fila offline.');
      _entityIds.clear();
      _value.clear();
      _notes.clear();
    } catch (error) {
      if (context.mounted) _message(context, error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
