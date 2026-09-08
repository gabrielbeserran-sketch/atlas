import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/features/dr_beserra/data/services/dr_beserra_voice_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/operational_notes/data/services/operational_note_remote_service.dart';
import 'package:projeto_atlas/features/operational_notes/domain/models/operational_note.dart';

class OperationalNotesScreen extends StatefulWidget {
  const OperationalNotesScreen({required this.farm, this.embedded = false, super.key});

  final FarmData farm;
  final bool embedded;

  @override
  State<OperationalNotesScreen> createState() => _OperationalNotesScreenState();
}

class _OperationalNotesScreenState extends State<OperationalNotesScreen> {
  final _service = OperationalNoteRemoteService();
  final _voice = DrBeserraVoiceService.instance;
  final _content = TextEditingController();
  List<OperationalNote> _notes = const [];
  bool _loading = true;
  bool _saving = false;
  bool _voiceDraft = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _voice.state.addListener(_receiveVoiceTranscript);
    _load();
  }

  @override
  void dispose() {
    _voice.state.removeListener(_receiveVoiceTranscript);
    _content.dispose();
    super.dispose();
  }

  void _receiveVoiceTranscript() {
    final state = _voice.state.value;
    if (!state.finalResult || state.transcript.trim().isEmpty) return;
    final transcript = state.transcript.trim();
    _content.value = TextEditingValue(
      text: transcript,
      selection: TextSelection.collapsed(offset: transcript.length),
    );
    if (mounted) setState(() => _voiceDraft = true);
    _voice.clearFinalResult();
  }

  Future<void> _load() async {
    if (mounted) setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notes = await _service.list(widget.farm.id);
      if (mounted) setState(() => _notes = notes);
    } catch (_) {
      if (mounted) setState(() => _error = 'Não foi possível carregar as anotações.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleVoice() async {
    final state = _voice.state.value;
    if (state.listening) {
      await _voice.stopListening();
      return;
    }
    final available = await _voice.startListening();
    if (!available && mounted) {
      _message('O reconhecimento de voz não está disponível neste dispositivo.');
    }
  }

  Future<void> _save() async {
    final content = _content.text.trim();
    if (content.isEmpty) {
      _message('Escreva ou dite uma anotação antes de salvar.');
      return;
    }
    setState(() => _saving = true);
    try {
      final note = await _service.create(
        farmId: widget.farm.id,
        content: content,
        cameFromVoice: _voiceDraft,
      );
      if (!mounted) return;
      setState(() {
        _notes = [note, ..._notes];
        _content.clear();
        _voiceDraft = false;
      });
      _message('Anotação salva para ${widget.farm.name}.');
    } catch (_) {
      if (mounted) _message('Não foi possível salvar a anotação. Tente novamente.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _promote(OperationalNote note) async {
    final draft = await showDialog<_TaskDraft>(
      context: context,
      builder: (_) => _CreateAgendaTaskDialog(initialTitle: _titleFrom(note.content)),
    );
    if (draft == null || !mounted) return;
    try {
      final created = await _service.createAgendaTask(
        noteId: note.id,
        title: draft.title,
        priority: draft.priority,
      );
      if (!mounted) return;
      _message(created
          ? 'Compromisso criado na Agenda.'
          : 'Esta anotação já possui um compromisso na Agenda.');
    } catch (_) {
      if (mounted) _message('Não foi possível criar o compromisso. Tente novamente.');
    }
  }

  String _titleFrom(String value) {
    final firstLine = value.split(RegExp(r'\r?\n')).first.trim();
    return firstLine.length > 80 ? '${firstLine.substring(0, 80)}…' : firstLine;
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Anotações')),
      body: content,
    );
  }

  Widget _buildContent(BuildContext context) => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Anotações da operação', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text('${widget.farm.name} · texto ou voz transcrita, sempre vinculada à fazenda.'),
        const SizedBox(height: 16),
        _Composer(
          controller: _content,
          saving: _saving,
          voiceDraft: _voiceDraft,
          voice: _voice,
          onRecord: _toggleVoice,
          onSave: _save,
        ),
        const SizedBox(height: 20),
        if (_error != null)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: ListTile(
              leading: const Icon(Icons.cloud_off_outlined),
              title: Text(_error!),
              trailing: TextButton(onPressed: _load, child: const Text('Tentar novamente')),
            ),
          ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_notes.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Ainda não há anotações nesta fazenda.'),
            ),
          )
        else
          ..._notes.map(
            (note) => Card(
              child: ListTile(
                leading: Icon(note.cameFromVoice ? Icons.mic_outlined : Icons.sticky_note_2_outlined),
                title: Text(note.content, maxLines: 3, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${note.cameFromVoice ? 'Voz transcrita' : 'Texto'} · ${_date(note.createdAt)}',
                ),
                trailing: IconButton(
                  tooltip: 'Criar compromisso na Agenda',
                  onPressed: () => _promote(note),
                  icon: const Icon(Icons.event_available_outlined),
                ),
              ),
            ),
          ),
        const SizedBox(height: 48),
      ],
    ),
  );

  String _date(DateTime? value) => value == null
      ? 'Data não disponível'
      : DateFormat("dd/MM 'às' HH:mm", 'pt_BR').format(value);
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.saving,
    required this.voiceDraft,
    required this.voice,
    required this.onRecord,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool saving;
  final bool voiceDraft;
  final DrBeserraVoiceService voice;
  final VoidCallback onRecord;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: ValueListenableBuilder<DrBeserraVoiceState>(
        valueListenable: voice.state,
        builder: (context, state, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              minLines: 3,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'O que foi observado?',
                hintText: 'Registre contexto, decisão ou pendência.',
                border: OutlineInputBorder(),
              ),
            ),
            if (voiceDraft) ...[
              const SizedBox(height: 8),
              const Text('Origem: voz transcrita neste dispositivo.'),
            ],
            if (state.errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(state.errorMessage, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: saving ? null : onRecord,
                  icon: Icon(state.listening ? Icons.stop_circle_outlined : Icons.mic_none_outlined),
                  label: Text(state.listening ? 'Parar ditado' : 'Ditar anotação'),
                ),
                FilledButton.icon(
                  onPressed: saving ? null : onSave,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(saving ? 'Salvando...' : 'Salvar anotação'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _TaskDraft {
  const _TaskDraft({required this.title, required this.priority});

  final String title;
  final String priority;
}

class _CreateAgendaTaskDialog extends StatefulWidget {
  const _CreateAgendaTaskDialog({required this.initialTitle});

  final String initialTitle;

  @override
  State<_CreateAgendaTaskDialog> createState() => _CreateAgendaTaskDialogState();
}

class _CreateAgendaTaskDialogState extends State<_CreateAgendaTaskDialog> {
  late final _title = TextEditingController(text: widget.initialTitle);
  String _priority = 'medium';

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Criar compromisso na Agenda'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _title,
          maxLength: 220,
          decoration: const InputDecoration(labelText: 'Título do compromisso'),
        ),
        DropdownButtonFormField<String>(
          value: _priority,
          decoration: const InputDecoration(labelText: 'Prioridade'),
          items: const [
            DropdownMenuItem(value: 'low', child: Text('Baixa')),
            DropdownMenuItem(value: 'medium', child: Text('Normal')),
            DropdownMenuItem(value: 'high', child: Text('Alta')),
            DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
          ],
          onChanged: (value) => setState(() => _priority = value ?? 'medium'),
        ),
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      FilledButton(
        onPressed: () => Navigator.pop(
          context,
          _TaskDraft(title: _title.text.trim(), priority: _priority),
        ),
        child: const Text('Criar compromisso'),
      ),
    ],
  );
}
