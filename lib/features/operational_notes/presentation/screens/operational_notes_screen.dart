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
  List<OperationalNoteFolder> _folders = const [];
  String? _selectedFolderId;
  bool _loading = true;
  bool _saving = false;
  bool _voiceDraft = false;
  String? _error;

  String get _farmId => widget.farm.id?.trim() ?? '';

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
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    if (_farmId.isEmpty) {
      if (mounted) {
        setState(() {
          _error = 'Selecione uma fazenda válida para acessar as anotações.';
          _loading = false;
        });
      }
      return;
    }
    try {
      final results = await Future.wait([
        _service.list(_farmId),
        _service.listFolders(_farmId),
      ]);
      if (mounted) {
        final folders = results[1] as List<OperationalNoteFolder>;
        setState(() {
          _notes = results[0] as List<OperationalNote>;
          _folders = folders;
          if (_selectedFolderId != null &&
              !folders.any((folder) => folder.id == _selectedFolderId)) {
            _selectedFolderId = null;
          }
        });
      }
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
    if (_farmId.isEmpty) {
      _message('Selecione uma fazenda válida antes de salvar.');
      return;
    }
    setState(() => _saving = true);
    try {
      final note = await _service.create(
        farmId: _farmId,
        content: content,
        cameFromVoice: _voiceDraft,
        folderId: _selectedFolderId,
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

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova pasta de assunto'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          decoration: const InputDecoration(
            labelText: 'Assunto',
            hintText: 'Ex.: Sanidade, Compras ou Reprodução',
          ),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Criar pasta'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    try {
      final folder = await _service.createFolder(farmId: _farmId, name: name);
      if (!mounted) return;
      setState(() {
        _folders = [..._folders, folder]..sort((a, b) => a.name.compareTo(b.name));
        _selectedFolderId = folder.id;
      });
      _message('Pasta "$name" criada e selecionada.');
    } catch (_) {
      if (mounted) _message('Não foi possível criar a pasta. Verifique se o assunto já existe.');
    }
  }

  Future<void> _move(OperationalNote note) async {
    final folderId = await showModalBottomSheet<String?>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Mover anotação para')),
            ListTile(
              leading: const Icon(Icons.folder_off_outlined),
              title: const Text('Sem pasta'),
              onTap: () => Navigator.pop(context, ''),
            ),
            ..._folders.map(
              (folder) => ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(folder.name),
                trailing: folder.id == note.folderId ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, folder.id),
              ),
            ),
          ],
        ),
      ),
    );
    if (folderId == null) return;
    try {
      final updated = await _service.moveToFolder(
        noteId: note.id,
        folderId: folderId.isEmpty ? null : folderId,
      );
      if (!mounted) return;
      setState(() => _notes = _notes.map((item) => item.id == updated.id ? updated : item).toList());
      _message('Pasta da anotação atualizada.');
    } catch (_) {
      if (mounted) _message('Não foi possível mover a anotação.');
    }
  }

  Future<void> _deleteNote(OperationalNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir anotação?'),
        content: const Text('Esta ação remove a anotação. Um compromisso já criado na Agenda será preservado.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final keptTask = await _service.delete(note.id);
      if (!mounted) return;
      setState(() => _notes = _notes.where((item) => item.id != note.id).toList());
      _message(keptTask ? 'Anotação excluída; compromisso da Agenda preservado.' : 'Anotação excluída.');
    } catch (_) {
      if (mounted) _message('Não foi possível excluir a anotação.');
    }
  }

  Future<void> _deleteSelectedFolder() async {
    final folderId = _selectedFolderId;
    if (folderId == null) return;
    final folder = _folderById(folderId);
    if (folder == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir pasta "${folder.name}"?'),
        content: const Text('As anotações serão preservadas e ficarão sem pasta.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir pasta'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final preserved = await _service.deleteFolder(folder.id);
      if (!mounted) return;
      setState(() {
        _notes = _notes.map((note) => note.folderId == folder.id
            ? OperationalNote(
                id: note.id, farmId: note.farmId, folderId: null, authorUserId: note.authorUserId,
                content: note.content, source: note.source, transcript: note.transcript, createdAt: note.createdAt)
            : note).toList();
        _folders = _folders.where((item) => item.id != folder.id).toList();
        _selectedFolderId = null;
      });
      _message('Pasta excluída; $preserved anotações foram preservadas.');
    } catch (_) {
      if (mounted) _message('Não foi possível excluir a pasta.');
    }
  }

  String _titleFrom(String value) {
    final firstLine = value.split(RegExp(r'\r?\n')).first.trim();
    return firstLine.length > 80 ? '${firstLine.substring(0, 80)}…' : firstLine;
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  OperationalNoteFolder? _folderById(String? id) {
    if (id == null) return null;
    for (final folder in _folders) {
      if (folder.id == id) return folder;
    }
    return null;
  }

  String _folderName(String? id) => _folderById(id)?.name ?? 'Sem pasta';

  List<OperationalNote> get _visibleNotes => _selectedFolderId == null
      ? _notes
      : _notes.where((note) => note.folderId == _selectedFolderId).toList();

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
          folders: _folders,
          selectedFolderId: _selectedFolderId,
          onFolderChanged: (value) => setState(() => _selectedFolderId = value),
          onCreateFolder: _createFolder,
          onRecord: _toggleVoice,
          onSave: _save,
        ),
        const SizedBox(height: 20),
        OperationalNoteFolderControls(
          folders: _folders,
          selectedFolderId: _selectedFolderId,
          onChanged: (value) => setState(() => _selectedFolderId = value),
          onCreate: _createFolder,
          onDeleteSelected: _selectedFolderId == null ? null : _deleteSelectedFolder,
        ),
        const SizedBox(height: 12),
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
        else if (_visibleNotes.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Ainda não há anotações nesta pasta.'),
            ),
          )
        else
          ..._visibleNotes.map(
            (note) => Card(
              child: ListTile(
                leading: Icon(note.cameFromVoice ? Icons.mic_outlined : Icons.sticky_note_2_outlined),
                title: Text(note.content, maxLines: 3, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${_folderName(note.folderId)} · ${note.cameFromVoice ? 'Voz transcrita' : 'Texto'} · ${_date(note.createdAt)}',
                ),
                trailing: PopupMenuButton<_NoteAction>(
                  onSelected: (action) {
                    switch (action) {
                      case _NoteAction.agenda:
                        _promote(note);
                      case _NoteAction.move:
                        _move(note);
                      case _NoteAction.delete:
                        _deleteNote(note);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: _NoteAction.agenda, child: Text('Criar compromisso na Agenda')),
                    PopupMenuItem(value: _NoteAction.move, child: Text('Mover para pasta')),
                    PopupMenuDivider(),
                    PopupMenuItem(value: _NoteAction.delete, child: Text('Excluir anotação')),
                  ],
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
    required this.folders,
    required this.selectedFolderId,
    required this.onFolderChanged,
    required this.onCreateFolder,
    required this.onRecord,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool saving;
  final bool voiceDraft;
  final DrBeserraVoiceService voice;
  final List<OperationalNoteFolder> folders;
  final String? selectedFolderId;
  final ValueChanged<String?> onFolderChanged;
  final VoidCallback onCreateFolder;
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(selectedFolderId),
                    initialValue: selectedFolderId ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Pasta de assunto',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Sem pasta')),
                      ...folders.map((folder) => DropdownMenuItem(value: folder.id, child: Text(folder.name))),
                    ],
                    onChanged: saving ? null : (value) => onFolderChanged(value == '' ? null : value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Criar pasta',
                  onPressed: saving ? null : onCreateFolder,
                  icon: const Icon(Icons.create_new_folder_outlined),
                ),
              ],
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

enum _NoteAction { agenda, move, delete }

class OperationalNoteFolderControls extends StatelessWidget {
  const OperationalNoteFolderControls({
    required this.folders,
    required this.selectedFolderId,
    required this.onChanged,
    required this.onCreate,
    required this.onDeleteSelected,
    super.key,
  });

  final List<OperationalNoteFolder> folders;
  final String? selectedFolderId;
  final ValueChanged<String?> onChanged;
  final VoidCallback onCreate;
  final VoidCallback? onDeleteSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      ChoiceChip(
        label: const Text('Todas'),
        selected: selectedFolderId == null,
        onSelected: (_) => onChanged(null),
      ),
      ...folders.map(
        (folder) => ChoiceChip(
          label: Text(folder.name),
          selected: selectedFolderId == folder.id,
          onSelected: (_) => onChanged(folder.id),
        ),
      ),
      ActionChip(
        avatar: const Icon(Icons.create_new_folder_outlined, size: 18),
        label: const Text('Nova pasta'),
        onPressed: onCreate,
      ),
      if (onDeleteSelected != null)
        ActionChip(
          avatar: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Excluir pasta'),
          onPressed: onDeleteSelected,
        ),
    ],
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
          initialValue: _priority,
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
