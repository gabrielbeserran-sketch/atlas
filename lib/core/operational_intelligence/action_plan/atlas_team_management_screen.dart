import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_team_member.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_team_member_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_team_workload.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_team_workload_service.dart';

class AtlasTeamManagementScreen extends StatefulWidget {
  const AtlasTeamManagementScreen({required this.actionController, super.key});

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasTeamManagementScreen> createState() =>
      _AtlasTeamManagementScreenState();
}

class _AtlasTeamManagementScreenState extends State<AtlasTeamManagementScreen> {
  final AtlasTeamMemberService memberService = AtlasTeamMemberService.instance;
  final AtlasCommandCenterActionService actionService =
      AtlasCommandCenterActionService.instance;
  final AtlasTeamWorkloadService workloadService =
      const AtlasTeamWorkloadService();

  List<AtlasTeamMember> members = <AtlasTeamMember>[];
  bool isLoading = false;
  bool includeInactive = false;

  List<AtlasTeamWorkload> get workloads => workloadService.build(
    members: members,
    actions: widget.actionController.actions,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);

    members = await memberService.load(
      farmName: widget.actionController.farmName,
      includeInactive: includeInactive,
    );

    await widget.actionController.load();

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _createOrEdit({AtlasTeamMember? member}) async {
    final name = TextEditingController(text: member?.name ?? '');
    final phone = TextEditingController(text: member?.phone ?? '');
    final email = TextEditingController(text: member?.email ?? '');
    var role = member?.role ?? AtlasTeamMemberRole.employee;

    final result = await showDialog<AtlasTeamMember>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                member == null ? 'Cadastrar responsável' : 'Editar responsável',
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: name,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AtlasTeamMemberRole>(
                        initialValue: role,
                        decoration: const InputDecoration(
                          labelText: 'Função',
                          border: OutlineInputBorder(),
                        ),
                        items: AtlasTeamMemberRole.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(atlasTeamMemberRoleLabel(value)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => role = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: email,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (name.text.trim().isEmpty) {
                      return;
                    }

                    final now = DateTime.now();
                    final result = member == null
                        ? AtlasTeamMember(
                            id:
                                'team_member_'
                                '${now.microsecondsSinceEpoch}',
                            name: name.text.trim(),
                            role: role,
                            phone: phone.text.trim(),
                            email: email.text.trim(),
                            farmName: widget.actionController.farmName,
                            active: true,
                            createdAt: now,
                            updatedAt: now,
                          )
                        : member.copyWith(
                            name: name.text.trim(),
                            role: role,
                            phone: phone.text.trim(),
                            email: email.text.trim(),
                          );

                    Navigator.of(dialogContext).pop(result);
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    name.dispose();
    phone.dispose();
    email.dispose();

    if (result == null) {
      return;
    }

    await memberService.save(result);
    await _load();
  }

  Future<void> _openMember(AtlasTeamWorkload workload) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(workload.member.name),
          content: SizedBox(
            width: 700,
            height: 540,
            child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('${workload.openActions} abertas')),
                    Chip(label: Text('${workload.overdueActions} atrasadas')),
                    Chip(label: Text('${workload.criticalActions} críticas')),
                    Chip(label: Text('${workload.dueSoonActions} próximas')),
                    Chip(label: Text('${workload.blockedActions} bloqueadas')),
                    Chip(
                      label: Text(
                        '${workload.averageProgressPercent.toStringAsFixed(0)}% progresso',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: workload.actions.isEmpty
                      ? const Center(child: Text('Nenhuma ação atribuída.'))
                      : ListView.separated(
                          itemCount: workload.actions.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final action = workload.actions[index];

                            return ListTile(
                              title: Text(action.title),
                              subtitle: Text(
                                '${action.progressPercent}% • '
                                '${action.dueAt == null ? 'Sem prazo' : DateFormat('dd/MM/yyyy').format(action.dueAt!)}',
                              ),
                              trailing: action.isOverdue
                                  ? const Icon(Icons.warning_amber_rounded)
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fechar'),
            ),
            FilledButton.tonalIcon(
              onPressed: workload.openActions == 0
                  ? null
                  : () async {
                      Navigator.of(dialogContext).pop();
                      await _redistribute(source: workload.member);
                    },
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Redistribuir tarefas'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _redistribute({required AtlasTeamMember source}) async {
    final targets = members
        .where((member) => member.active && member.id != source.id)
        .toList();

    if (targets.isEmpty) {
      return;
    }

    AtlasTeamMember? target;
    var onlyOpen = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Redistribuir tarefas'),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Transferir tarefas de ${source.name} para:'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AtlasTeamMember>(
                      decoration: const InputDecoration(
                        labelText: 'Novo responsável',
                        border: OutlineInputBorder(),
                      ),
                      items: targets
                          .map(
                            (member) => DropdownMenuItem(
                              value: member,
                              child: Text(member.name),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        setDialogState(() => target = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Transferir somente ações abertas'),
                      value: onlyOpen,
                      onChanged: (value) {
                        setDialogState(() => onlyOpen = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: target == null
                      ? null
                      : () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Transferir'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || target == null) {
      return;
    }

    final sourceActions = widget.actionController.actions.where((action) {
      final assigned =
          action.responsibleId == source.id ||
          (action.responsibleId == null &&
              action.responsibleName.trim().toLowerCase() ==
                  source.name.trim().toLowerCase());

      return assigned && (!onlyOpen || action.isOpen);
    }).toList();

    for (final action in sourceActions) {
      await actionService.saveAction(
        action.copyWith(
          responsibleId: target!.id,
          responsibleName: target!.name,
          updatedAt: DateTime.now(),
        ),
        source: 'redistribuição em lote',
      );
    }

    await widget.actionController.load();
    await _load();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${sourceActions.length} ação(ões) transferida(s) '
          'para ${target!.name}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamWorkloads = workloads;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipe e responsabilidades'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createOrEdit(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Cadastrar pessoa'),
      ),
      body: isLoading && members.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SwitchListTile(
                  title: const Text('Mostrar pessoas inativas'),
                  value: includeInactive,
                  onChanged: (value) async {
                    setState(() => includeInactive = value);
                    await _load();
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          '${members.where((item) => item.active).length} ativas',
                        ),
                      ),
                      Chip(
                        label: Text(
                          '${widget.actionController.actions.where((item) => item.isOpen).length} ações abertas',
                        ),
                      ),
                      Chip(
                        label: Text(
                          '${widget.actionController.actions.where((item) => item.isOverdue).length} atrasadas',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: teamWorkloads.isEmpty
                      ? const Center(child: Text('Nenhuma pessoa cadastrada.'))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          itemCount: teamWorkloads.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final workload = teamWorkloads[index];

                            return Card(
                              child: ListTile(
                                onTap: () => _openMember(workload),
                                leading: CircleAvatar(
                                  child: Text(
                                    workload.member.name.isEmpty
                                        ? '?'
                                        : workload.member.name[0].toUpperCase(),
                                  ),
                                ),
                                title: Text(
                                  workload.member.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  '${atlasTeamMemberRoleLabel(workload.member.role)} • '
                                  '${workload.openActions} abertas • '
                                  '${workload.overdueActions} atrasadas • '
                                  'carga ${workload.workloadScore.toStringAsFixed(0)}',
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      await _createOrEdit(
                                        member: workload.member,
                                      );
                                    } else if (value == 'redistribute') {
                                      await _redistribute(
                                        source: workload.member,
                                      );
                                    } else if (value == 'toggle') {
                                      await memberService.setActive(
                                        member: workload.member,
                                        active: !workload.member.active,
                                      );
                                      await _load();
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Editar'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'redistribute',
                                      child: Text('Redistribuir tarefas'),
                                    ),
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Text(
                                        workload.member.active
                                            ? 'Desativar'
                                            : 'Reativar',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
