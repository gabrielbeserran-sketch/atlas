import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_decision_action_auto_sync_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_audit_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_meeting.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_meeting_builder.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_meeting_decision.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_meeting_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_meeting_decision_action_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_meeting_decision_action_sync_controller.dart';

class AtlasExecutionMeetingScreen extends StatefulWidget {
  const AtlasExecutionMeetingScreen({
    required this.actionController,
    super.key,
  });

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasExecutionMeetingScreen> createState() =>
      _AtlasExecutionMeetingScreenState();
}

class _AtlasExecutionMeetingScreenState
    extends State<AtlasExecutionMeetingScreen> {
  final AtlasExecutionMeetingService service =
      AtlasExecutionMeetingService.instance;
  final AtlasExecutionMeetingBuilder builder =
      const AtlasExecutionMeetingBuilder();
  final AtlasMeetingDecisionActionService decisionActionService =
      AtlasMeetingDecisionActionService.instance;
  final AtlasDecisionActionAutoSyncService autoSyncService =
      AtlasDecisionActionAutoSyncService.instance;

  List<AtlasExecutionMeeting> meetings =
      <AtlasExecutionMeeting>[];
  bool isLoading = false;
  late final AtlasMeetingDecisionActionSyncController syncController;

  @override
  void initState() {
    super.initState();
    syncController =
        AtlasMeetingDecisionActionSyncController(
      farmName: widget.actionController.farmName,
    );
    autoSyncService.start(
      farmName: widget.actionController.farmName,
      onSynchronized: _load,
    );
    _load();
  }

  @override
  void dispose() {
    syncController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);

    meetings = await service.load(
      farmName: widget.actionController.farmName,
    );

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _createMeeting() async {
    final meeting = builder.build(
      actions: widget.actionController.actions,
      farmName: widget.actionController.farmName,
    );

    await service.save(meeting);
    await _load();

    if (!mounted) {
      return;
    }

    await _openMeeting(meeting);
  }

  Future<void> _openMeeting(
    AtlasExecutionMeeting initialMeeting,
  ) async {
    var meeting = initialMeeting;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save(
              AtlasExecutionMeeting updated,
            ) async {
              meeting = updated;
              await service.save(meeting);
              setDialogState(() {});
            }

            return AlertDialog(
              title: Text(meeting.title),
              content: SizedBox(
                width: 760,
                height: 620,
                child: ListView(
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm')
                          .format(meeting.meetingAt),
                    ),
                    const SizedBox(height: 14),
                    _MeetingSection(
                      title: 'Pauta',
                      icon: Icons.format_list_bulleted,
                      children: meeting.agendaItems
                          .map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.chevron_right,
                              ),
                              title: Text(item),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 14),
                    _MeetingSection(
                      title: 'Decisões',
                      icon: Icons.gavel_outlined,
                      children: [
                        ...meeting.decisions.map(
                          (decision) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    value: decision.completed,
                                    title: Text(decision.title),
                                    subtitle: Text(
                                      '${decision.description}\n'
                                      '${decision.responsibleName.trim().isEmpty ? 'Sem responsável' : decision.responsibleName}'
                                      '${decision.dueAt == null ? '' : ' • Prazo ${DateFormat('dd/MM/yyyy').format(decision.dueAt!)}'}',
                                    ),
                                    onChanged: (value) async {
                                      final updatedDecisions =
                                          meeting.decisions
                                              .map(
                                                (item) =>
                                                    item.id ==
                                                            decision.id
                                                        ? item.copyWith(
                                                            completed:
                                                                value ??
                                                                    false,
                                                          )
                                                        : item,
                                              )
                                              .toList(
                                                growable: false,
                                              );

                                      await save(
                                        meeting.copyWith(
                                          decisions:
                                              updatedDecisions,
                                        ),
                                      );
                                    },
                                  ),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          final edited =
                                              await _editDecision(
                                            dialogContext,
                                            decision,
                                          );

                                          if (edited == null) {
                                            return;
                                          }

                                          final updatedDecisions =
                                              meeting.decisions
                                                  .map(
                                                    (item) =>
                                                        item.id ==
                                                                decision.id
                                                            ? edited
                                                            : item,
                                                  )
                                                  .toList(
                                                    growable: false,
                                                  );

                                          await save(
                                            meeting.copyWith(
                                              decisions:
                                                  updatedDecisions,
                                            ),
                                          );

                                          await autoSyncService
                                              .synchronizeNow();
                                          await widget.actionController
                                              .load();
                                        },
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                        ),
                                        label: const Text('Editar'),
                                      ),
                                      FilledButton.tonalIcon(
                                      onPressed: decision.linkedActionId != null
                                          ? null
                                          : () async {
                                              final action =
                                                  await decisionActionService
                                                      .createAction(
                                                meeting: meeting,
                                                decision: decision,
                                              );

                                              final updatedDecisions =
                                                  meeting.decisions
                                                      .map(
                                                        (item) =>
                                                            item.id ==
                                                                    decision.id
                                                                ? item.copyWith(
                                                                    linkedActionId:
                                                                        action.id,
                                                                  )
                                                                : item,
                                                      )
                                                      .toList(
                                                        growable: false,
                                                      );

                                              await save(
                                                meeting.copyWith(
                                                  decisions:
                                                      updatedDecisions,
                                                ),
                                              );

                                              await widget.actionController
                                                  .load();
                                            },
                                      icon: Icon(
                                        decision.linkedActionId == null
                                            ? Icons.playlist_add_check
                                            : Icons.link,
                                      ),
                                      label: Text(
                                        decision.linkedActionId == null
                                            ? 'Transformar em ação'
                                            : 'Ação criada',
                                      ),
                                    ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.tonalIcon(
                            onPressed: () async {
                              final decision =
                                  await _createDecision(
                                dialogContext,
                              );

                              if (decision == null) {
                                return;
                              }

                              await save(
                                meeting.copyWith(
                                  decisions: [
                                    ...meeting.decisions,
                                    decision,
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text(
                              'Adicionar decisão',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _MeetingSection(
                      title: 'Resumo',
                      icon: Icons.notes_outlined,
                      children: [
                        TextFormField(
                          initialValue: meeting.summary,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            hintText:
                                'Registre os principais pontos da reunião.',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            meeting = meeting.copyWith(
                              summary: value,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(),
                  child: const Text('Fechar'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    await service.save(
                      meeting.copyWith(closed: true),
                    );

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  icon: const Icon(Icons.task_alt),
                  label: const Text(
                    'Encerrar reunião',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    await _load();
  }


  Future<AtlasExecutionMeetingDecision?> _editDecision(
    BuildContext context,
    AtlasExecutionMeetingDecision decision,
  ) async {
    final title = TextEditingController(
      text: decision.title,
    );
    final description = TextEditingController(
      text: decision.description,
    );
    final responsible = TextEditingController(
      text: decision.responsibleName,
    );
    var dueAt = decision.dueAt;
    var completed = decision.completed;

    final result =
        await showDialog<AtlasExecutionMeetingDecision>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar decisão'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: title,
                        decoration: const InputDecoration(
                          labelText: 'Título',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: description,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Descrição',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: responsible,
                        decoration: const InputDecoration(
                          labelText: 'Responsável',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Prazo'),
                        subtitle: Text(
                          dueAt == null
                              ? 'Sem prazo definido'
                              : DateFormat('dd/MM/yyyy')
                                  .format(dueAt!),
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            if (dueAt != null)
                              IconButton(
                                tooltip: 'Remover prazo',
                                onPressed: () {
                                  setDialogState(
                                    () => dueAt = null,
                                  );
                                },
                                icon: const Icon(Icons.clear),
                              ),
                            IconButton(
                              tooltip: 'Escolher prazo',
                              onPressed: () async {
                                final selected =
                                    await showDatePicker(
                                  context: dialogContext,
                                  initialDate:
                                      dueAt ?? DateTime.now(),
                                  firstDate: DateTime.now()
                                      .subtract(
                                    const Duration(days: 1),
                                  ),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 3650),
                                  ),
                                );

                                if (selected != null) {
                                  setDialogState(
                                    () => dueAt = selected,
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.calendar_month,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Decisão concluída'),
                        value: completed,
                        onChanged: (value) {
                          setDialogState(
                            () => completed = value,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (title.text.trim().isEmpty) {
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      decision.copyWith(
                        title: title.text.trim(),
                        description:
                            description.text.trim(),
                        responsibleName:
                            responsible.text.trim(),
                        dueAt: dueAt,
                        clearDueAt: dueAt == null,
                        completed: completed,
                      ),
                    );
                  },
                  child: const Text('Salvar alterações'),
                ),
              ],
            );
          },
        );
      },
    );

    title.dispose();
    description.dispose();
    responsible.dispose();

    return result;
  }

  Future<AtlasExecutionMeetingDecision?>
      _createDecision(
    BuildContext context,
  ) async {
    final title = TextEditingController();
    final description = TextEditingController();
    final responsible = TextEditingController();
    DateTime? dueAt;

    final result =
        await showDialog<AtlasExecutionMeetingDecision>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nova decisão'),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: description,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: responsible,
                      decoration: const InputDecoration(
                        labelText: 'Responsável',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Prazo da decisão'),
                      subtitle: Text(
                        dueAt == null
                            ? 'Sem prazo definido'
                            : DateFormat('dd/MM/yyyy')
                                .format(dueAt!),
                      ),
                      trailing: IconButton(
                        tooltip: 'Definir prazo',
                        onPressed: () async {
                          final selected =
                              await showDatePicker(
                            context: dialogContext,
                            initialDate:
                                dueAt ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 3650),
                            ),
                          );

                          if (selected != null) {
                            setDialogState(
                              () => dueAt = selected,
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.calendar_month,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (title.text.trim().isEmpty) {
                      return;
                    }

                    final now = DateTime.now();

                    Navigator.of(dialogContext).pop(
                      AtlasExecutionMeetingDecision(
                        id: 'meeting_decision_'
                            '${now.microsecondsSinceEpoch}',
                        title: title.text.trim(),
                        description:
                            description.text.trim(),
                        responsibleName:
                            responsible.text.trim(),
                        dueAt: dueAt,
                        completed: false,
                        linkedActionId: null,
                      ),
                    );
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );

    title.dispose();
    description.dispose();
    responsible.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reuniões de execução'),
        actions: [
          IconButton(
            tooltip: 'Auditoria',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AtlasExecutionAuditScreen(
                    farmName: widget.actionController.farmName,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Sincronizar decisões e ações',
            onPressed: syncController.isSyncing
                ? null
                : () async {
                    await syncController.synchronize();
                    await widget.actionController.load();
                    await _load();
                  },
            icon: const Icon(Icons.sync_alt),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading ? null : _createMeeting,
        icon: const Icon(Icons.add),
        label: const Text('Nova reunião'),
      ),
      body: isLoading && meetings.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : meetings.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nenhuma reunião de execução foi registrada.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    96,
                  ),
                  itemCount: meetings.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final meeting = meetings[index];

                    return Card(
                      child: ListTile(
                        onTap: () =>
                            _openMeeting(meeting),
                        leading: Icon(
                          meeting.closed
                              ? Icons.task_alt
                              : Icons.groups_outlined,
                        ),
                        title: Text(meeting.title),
                        subtitle: Text(
                          '${DateFormat('dd/MM/yyyy HH:mm').format(meeting.meetingAt)} • '
                          '${meeting.decisions.length} decisão(ões)',
                        ),
                        trailing: Chip(
                          label: Text(
                            meeting.closed
                                ? 'Encerrada'
                                : 'Aberta',
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _MeetingSection extends StatelessWidget {
  const _MeetingSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}
