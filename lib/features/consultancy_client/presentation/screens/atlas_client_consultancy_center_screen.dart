import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/widgets/atlas_module_decision_panel.dart';
import 'package:projeto_atlas/features/consultancy_client/data/services/atlas_client_onboarding_service.dart';
import 'package:projeto_atlas/features/consultancy_client/data/services/atlas_consultancy_action_service.dart';
import 'package:projeto_atlas/features/consultancy_client/data/services/atlas_consultancy_contact_service.dart';
import 'package:projeto_atlas/features/consultancy_client/data/services/atlas_consultancy_whatsapp_service.dart';
import 'package:projeto_atlas/features/consultancy_client/domain/models/atlas_client_onboarding_progress.dart';
import 'package:projeto_atlas/features/consultancy_client/domain/models/atlas_consultancy_action.dart';
import 'package:projeto_atlas/features/consultancy_client/domain/models/atlas_consultancy_contact_profile.dart';
import 'package:projeto_atlas/features/consultancy_client/presentation/widgets/atlas_client_onboarding_card.dart';
import 'package:projeto_atlas/features/consultancy_client/presentation/widgets/atlas_consultancy_action_plan_card.dart';
import 'package:projeto_atlas/features/consultancy_client/presentation/widgets/atlas_monthly_bulletins_card.dart';
import 'package:projeto_atlas/features/dashboard/data/services/atlas_operational_intelligence_service.dart';
import 'package:projeto_atlas/features/dashboard/domain/models/atlas_operational_intelligence_data.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_agenda/data/services/farm_agenda_storage_service.dart';
import 'package:projeto_atlas/features/farm_agenda/domain/models/farm_agenda_data.dart';
import 'package:projeto_atlas/features/reports/presentation/screens/reports_screen.dart';

class AtlasClientConsultancyCenterScreen extends StatefulWidget {
  const AtlasClientConsultancyCenterScreen({
    required this.farm,
    this.embedded = false,
    this.canManageContact = false,
    super.key,
  });

  final FarmData farm;
  final bool embedded;
  final bool canManageContact;

  @override
  State<AtlasClientConsultancyCenterScreen> createState() =>
      _AtlasClientConsultancyCenterScreenState();
}

class _AtlasClientConsultancyCenterScreenState
    extends State<AtlasClientConsultancyCenterScreen> {
  final AtlasConsultancyContactService contactService =
      AtlasConsultancyContactService();
  final AtlasClientOnboardingService onboardingService =
      AtlasClientOnboardingService();
  final AtlasConsultancyActionService actionService =
      AtlasConsultancyActionService();
  final AtlasConsultancyWhatsAppService whatsAppService =
      const AtlasConsultancyWhatsAppService();
  final AtlasOperationalIntelligenceService intelligenceService =
      AtlasOperationalIntelligenceService();
  final FarmAgendaStorageService agendaService = FarmAgendaStorageService();

  AtlasOperationalIntelligenceData? intelligence;
  AtlasConsultancyContactProfile contact =
      AtlasConsultancyContactProfile.unavailable;
  AtlasClientOnboardingProgress onboarding =
      AtlasClientOnboardingProgress.empty();
  List<FarmAgendaData> agenda = const [];
  List<AtlasConsultancyAction> consultancyActions = const [];
  bool loading = true;
  bool savingOnboarding = false;
  bool savingActions = false;
  String? warning;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (mounted) {
      setState(() {
        loading = true;
        warning = null;
      });
    }

    AtlasOperationalIntelligenceData? loadedIntelligence;
    AtlasConsultancyContactProfile loadedContact =
        AtlasConsultancyContactProfile.unavailable;
    AtlasClientOnboardingProgress loadedOnboarding =
        AtlasClientOnboardingProgress.empty();
    List<FarmAgendaData> loadedAgenda = const [];
    List<AtlasConsultancyAction> loadedActions = const [];
    final failures = <String>[];

    final farmId = widget.farm.id?.trim() ?? '';
    if (farmId.isNotEmpty) {
      try {
        loadedIntelligence = await intelligenceService.load(farmId);
      } catch (_) {
        failures.add('resumo operacional');
      }
      try {
        loadedContact = await contactService.loadForFarm(farmId);
      } catch (_) {
        failures.add('contato do veterinário');
      }
    } else {
      failures.add('identificação da fazenda');
    }

    try {
      loadedAgenda = await agendaService.loadTasks(
        widget.farm.name,
        farmId: farmId,
      );
    } catch (_) {
      failures.add('agenda');
    }

    try {
      loadedOnboarding = await onboardingService.load(farmId);
    } catch (_) {
      failures.add('implantação');
    }

    if (farmId.isNotEmpty) {
      try {
        loadedActions = await actionService.load(farmId);
      } catch (_) {
        failures.add('plano de ação');
      }
    }

    if (!mounted) return;
    setState(() {
      intelligence = loadedIntelligence;
      contact = loadedContact;
      onboarding = loadedOnboarding;
      agenda = loadedAgenda;
      consultancyActions = loadedActions;
      loading = false;
      warning = failures.isEmpty
          ? null
          : 'Não foi possível atualizar: ${failures.join(', ')}. '
                'As demais áreas da central continuam disponíveis; recursos '
                'dependentes do dado indisponível ficam temporariamente limitados.';
    });
  }

  DateTime? _parseAgendaDate(FarmAgendaData task) {
    final dateParts = task.date.trim().split('/');
    if (dateParts.length != 3) return DateTime.tryParse(task.date.trim());

    final day = int.tryParse(dateParts[0]);
    final month = int.tryParse(dateParts[1]);
    final year = int.tryParse(dateParts[2]);
    if (day == null || month == null || year == null) return null;

    final timeParts = task.time.trim().split(':');
    final hour =
        timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
    final minute =
        timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
    return DateTime(year, month, day, hour, minute);
  }

  FarmAgendaData? get nextConsultancyVisit {
    final now = DateTime.now();
    final candidates = agenda.where((task) {
      if (task.isCompleted || task.isCancelled) return false;
      final text =
          '${task.title} ${task.category} ${task.notes}'.toLowerCase();
      final consultancy =
          text.contains('consult') ||
          text.contains('visita') ||
          text.contains('veterin');
      final date = _parseAgendaDate(task);
      return consultancy && date != null && !date.isBefore(now);
    }).toList(growable: false)
      ..sort((first, second) {
        final a = _parseAgendaDate(first)!;
        final b = _parseAgendaDate(second)!;
        return a.compareTo(b);
      });

    return candidates.isEmpty ? null : candidates.first;
  }

  String _formatVisit(FarmAgendaData? visit) {
    if (visit == null) return 'Nenhuma visita registrada na agenda';
    final date = _parseAgendaDate(visit);
    if (date == null) return visit.date;
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}'
        '${taskTime(visit).isEmpty ? '' : ' • ${taskTime(visit)}'}';
  }

  String taskTime(FarmAgendaData task) => task.time.trim();

  AtlasModuleAttentionLevel get attentionLevel {
    final data = intelligence;
    if (data == null) return AtlasModuleAttentionLevel.attention;
    if (data.criticalAlerts > 0 || data.overdueTasks > 0) {
      return AtlasModuleAttentionLevel.critical;
    }
    if (data.highAlerts > 0 || data.alertTotal > 0) {
      return AtlasModuleAttentionLevel.attention;
    }
    return AtlasModuleAttentionLevel.normal;
  }

  String get statusTitle {
    final data = intelligence;
    if (data == null) return 'Acompanhamento disponível';
    if (attentionLevel == AtlasModuleAttentionLevel.critical) {
      return 'Há pontos importantes para revisar';
    }
    if (attentionLevel == AtlasModuleAttentionLevel.attention) {
      return 'A fazenda requer acompanhamento';
    }
    return 'Operação sem prioridade crítica';
  }

  List<AtlasModuleDecisionItem> get decisionItems {
    final data = intelligence;
    if (data == null) {
      return const [
        AtlasModuleDecisionItem(
          title: 'Resumo operacional indisponível',
          description:
              'Você ainda pode falar diretamente com o veterinário responsável.',
          icon: Icons.support_agent_outlined,
          level: AtlasModuleAttentionLevel.attention,
        ),
      ];
    }

    final items = <AtlasModuleDecisionItem>[];
    if (data.criticalAlerts > 0) {
      items.add(
        AtlasModuleDecisionItem(
          title: '${data.criticalAlerts} alerta(s) crítico(s)',
          description:
              'Priorize esses pontos na conversa com a consultoria.',
          icon: Icons.error_outline,
          level: AtlasModuleAttentionLevel.critical,
        ),
      );
    }
    if (data.overdueTasks > 0) {
      items.add(
        AtlasModuleDecisionItem(
          title: '${data.overdueTasks} tarefa(s) atrasada(s)',
          description:
              'Revise prazo, responsável e necessidade de apoio técnico.',
          icon: Icons.event_busy_outlined,
          level: AtlasModuleAttentionLevel.critical,
        ),
      );
    }
    for (final action in data.topActions.take(2)) {
      items.add(
        AtlasModuleDecisionItem(
          title: action.title,
          description: action.recommendedAction.trim().isEmpty
              ? action.area
              : action.recommendedAction,
          icon: Icons.task_alt_outlined,
          level: action.severity.toLowerCase() == 'critical'
              ? AtlasModuleAttentionLevel.critical
              : AtlasModuleAttentionLevel.attention,
        ),
      );
    }
    return items;
  }

  String _baseMessage(String subject) {
    return 'Olá! Sou cliente da consultoria Beserra e estou entrando em contato '
        'pelo Atlas.\n\n'
        'Fazenda: ${widget.farm.name}\n'
        'Assunto: $subject';
  }

  String _summaryMessage() {
    final data = intelligence;
    if (data == null) {
      return '${_baseMessage('Revisão da fazenda')}\n\n'
          'O resumo operacional não carregou no momento. '
          'Gostaria de revisar a situação da fazenda.';
    }

    final priorities = data.topActions
        .take(3)
        .map((item) => '• ${item.title}')
        .join('\n');

    return '${_baseMessage('Revisão do resumo operacional')}\n\n'
        'Score operacional: ${data.operationalScore}\n'
        'Alertas: ${data.alertTotal} '
        '(${data.criticalAlerts} críticos / ${data.highAlerts} altos)\n'
        'Tarefas abertas: ${data.openTasks}\n'
        'Tarefas atrasadas: ${data.overdueTasks}\n'
        '${priorities.isEmpty ? '' : '\nPrioridades atuais:\n$priorities\n'}'
        '\nGostaria de conversar sobre esses pontos.';
  }

  Future<void> openWhatsApp(String message) async {
    if (!contact.hasValidWhatsapp) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'O veterinário responsável ainda não está configurado para esta fazenda.',
            ),
          ),
        );
      return;
    }

    try {
      await whatsAppService.openConversation(
        contact: contact,
        message: message,
      );
    } catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(exception.toString())));
    }
  }

  Future<void> configureResponsibleContact() async {
    final farmId = widget.farm.id?.trim() ?? '';
    if (farmId.isEmpty || !widget.canManageContact) return;

    final name = TextEditingController(
      text: contact.configured ? contact.displayName : '',
    );
    final role = TextEditingController(
      text: contact.role.isEmpty
          ? 'Veterinário responsável'
          : contact.role,
    );
    final phone = TextEditingController(
      text: contact.configured ? contact.whatsappNumber : '',
    );
    final company = TextEditingController(
      text: contact.configured ? contact.companyLabel : '',
    );
    var active = contact.configured ? contact.active : true;

    final draft = await showDialog<_ResponsibleContactDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Veterinário responsável'),
          content: SizedBox(
            width: 520,
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
                  TextField(
                    controller: role,
                    decoration: const InputDecoration(
                      labelText: 'Função',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp',
                      hintText: '5561999999999',
                      helperText: 'Use DDI + DDD + número.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: company,
                    decoration: const InputDecoration(
                      labelText: 'Consultoria / empresa',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: active,
                    title: const Text('Contato ativo para esta fazenda'),
                    onChanged: (value) =>
                        setLocal(() => active = value),
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
                if (name.text.trim().length < 2 ||
                    company.text.trim().length < 2 ||
                    phone.text.replaceAll(RegExp(r'[^0-9]'), '').length < 10) {
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  _ResponsibleContactDraft(
                    displayName: name.text.trim(),
                    role: role.text.trim().isEmpty
                        ? 'Veterinário responsável'
                        : role.text.trim(),
                    whatsappNumber: phone.text.trim(),
                    companyLabel: company.text.trim(),
                    active: active,
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    name.dispose();
    role.dispose();
    phone.dispose();
    company.dispose();

    if (draft == null) return;

    try {
      final updated = await contactService.updateForFarm(
        farmId: farmId,
        displayName: draft.displayName,
        role: draft.role,
        whatsappNumber: draft.whatsappNumber,
        companyLabel: draft.companyLabel,
        active: draft.active,
      );
      if (!mounted) return;
      setState(() => contact = updated);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Veterinário responsável atualizado.'),
          ),
        );
    } catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(exception.toString())));
    }
  }

  Future<void> updateOnboardingStep(String stepId, bool value) async {
    if (!widget.canManageContact || savingOnboarding) return;

    final farmId = widget.farm.id?.trim() ?? '';
    if (farmId.isEmpty) return;

    final step = AtlasClientOnboardingProgress.canonicalSteps
        .where((item) => item.id == stepId)
        .firstOrNull;
    if (step == null || step.automatic) return;

    final previous = onboarding;
    final optimistic = onboarding.copyWithManualStep(stepId, value);
    setState(() {
      onboarding = optimistic;
      savingOnboarding = true;
    });

    try {
      final confirmed = await onboardingService.saveManualStep(
        farmId: farmId,
        stepId: stepId,
        value: value,
      );
      if (!mounted) return;
      setState(() => onboarding = confirmed);
    } catch (exception) {
      if (!mounted) return;
      setState(() => onboarding = previous);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível atualizar a implantação: $exception',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => savingOnboarding = false);
    }
  }

  Future<void> createActionsFromPriorities() async {
    if (!widget.canManageContact || savingActions) return;
    final farmId = widget.farm.id?.trim() ?? '';
    final data = intelligence;
    if (farmId.isEmpty || data == null || data.topActions.isEmpty) return;

    setState(() => savingActions = true);
    try {
      for (final priority in data.topActions.take(3)) {
        await actionService.createFromPriority(
          farmId: farmId,
          priority: priority,
          generatedAt: data.generatedAt,
        );
      }
      final refreshed = await actionService.load(farmId);
      final refreshedAgenda = await agendaService.loadTasks(
        widget.farm.name,
        farmId: farmId,
      );
      if (!mounted) return;
      setState(() {
        consultancyActions = refreshed;
        agenda = refreshedAgenda;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Prioridades registradas no plano de ação e sincronizadas com a Agenda.',
            ),
          ),
        );
    } catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Não foi possível criar o plano: $exception')),
        );
    } finally {
      if (mounted) setState(() => savingActions = false);
    }
  }

  Future<void> completeConsultancyAction(AtlasConsultancyAction action) async {
    if (!widget.canManageContact || savingActions) return;
    setState(() => savingActions = true);
    try {
      await actionService.complete(
        actionId: action.id,
        actualResult: 'Concluída pela Central da Consultoria.',
      );
      final farmId = widget.farm.id?.trim() ?? '';
      final refreshed = await actionService.load(farmId);
      final refreshedAgenda = await agendaService.loadTasks(
        widget.farm.name,
        farmId: farmId,
      );
      if (!mounted) return;
      setState(() {
        consultancyActions = refreshed;
        agenda = refreshedAgenda;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Ação concluída também na Agenda.'),
          ),
        );
    } catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Não foi possível concluir a ação: $exception')),
        );
    } finally {
      if (mounted) setState(() => savingActions = false);
    }
  }

  void openReports() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ReportsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = intelligence;
    final visit = nextConsultancyVisit;

    final body = loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: loadData,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              children: [
                _ConsultancyHeader(
                  farmName: widget.farm.name,
                  contact: contact,
                ),
                if (warning != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Atualização parcial'),
                      subtitle: Text(warning!),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _VeterinarianContactCard(
                  contact: contact,
                  canManageContact: widget.canManageContact,
                  onConfigure: configureResponsibleContact,
                  onContact: () => openWhatsApp(
                    '${_baseMessage('Orientação técnica')}\n\n'
                    'Gostaria de falar com o veterinário responsável.',
                  ),
                  onRequestVisit: () => openWhatsApp(
                    '${_baseMessage('Solicitação de visita')}\n\n'
                    'Gostaria de verificar uma data para visita à fazenda.',
                  ),
                  onSendSummary: () => openWhatsApp(_summaryMessage()),
                ),
                const SizedBox(height: 16),
                AtlasClientOnboardingCard(
                  progress: onboarding,
                  canManage: widget.canManageContact,
                  saving: savingOnboarding,
                  onChanged: updateOnboardingStep,
                ),
                const SizedBox(height: 16),
                AtlasMonthlyBulletinsCard(farm: widget.farm),
                const SizedBox(height: 16),
                AtlasModuleDecisionPanel(
                  statusTitle: statusTitle,
                  statusDescription: data == null
                      ? 'A consultoria continua acessível mesmo com conexão parcial.'
                      : 'Score ${data.operationalScore} • '
                            '${data.alertTotal} alertas • '
                            '${data.openTasks} tarefas abertas',
                  items: decisionItems,
                  level: attentionLevel,
                ),
                const SizedBox(height: 16),
                AtlasConsultancyActionPlanCard(
                  actions: consultancyActions,
                  canManage: widget.canManageContact,
                  busy: savingActions,
                  hasPriorities: data?.topActions.isNotEmpty == true,
                  onCreateFromPriorities: createActionsFromPriorities,
                  onComplete: completeConsultancyAction,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    _ConsultancyMetric(
                      title: 'Score operacional',
                      value: data == null ? '—' : '${data.operationalScore}',
                      subtitle: data?.operationalLevel ?? 'Sem atualização',
                      icon: Icons.speed_outlined,
                    ),
                    _ConsultancyMetric(
                      title: 'Alertas',
                      value: data == null ? '—' : '${data.alertTotal}',
                      subtitle: data == null
                          ? 'Sem atualização'
                          : '${data.criticalAlerts} críticos • '
                                '${data.highAlerts} altos',
                      icon: Icons.notifications_active_outlined,
                    ),
                    _ConsultancyMetric(
                      title: 'Tarefas',
                      value: data == null ? '—' : '${data.openTasks}',
                      subtitle: data == null
                          ? 'Sem atualização'
                          : '${data.overdueTasks} atrasadas',
                      icon: Icons.task_alt_outlined,
                    ),
                    _ConsultancyMetric(
                      title: 'Próxima visita',
                      value: visit == null ? 'Não agendada' : visit.title,
                      subtitle: _formatVisit(visit),
                      icon: Icons.event_available_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.bar_chart_outlined),
                    ),
                    title: const Text(
                      'Relatórios gerenciais',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Abra os relatórios antes da conversa para revisar '
                      'resultados, custos, estoque, agenda e plano de ação.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: openReports,
                  ),
                ),
                const SizedBox(height: 14),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.verified_user_outlined),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'O WhatsApp abre uma conversa externa e a mensagem '
                            'fica visível para você revisar antes do envio. '
                            'O Atlas não envia mensagens sem a sua ação.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Consultoria')),
      body: body,
    );
  }
}

class _ConsultancyHeader extends StatelessWidget {
  const _ConsultancyHeader({
    required this.farmName,
    required this.contact,
  });

  final String farmName;
  final AtlasConsultancyContactProfile contact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1F6B2A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFF4E9254),
            child: Icon(Icons.support_agent, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Central da Consultoria',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$farmName • ${contact.companyLabel} • contato técnico direto',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VeterinarianContactCard extends StatelessWidget {
  const _VeterinarianContactCard({
    required this.contact,
    required this.canManageContact,
    required this.onConfigure,
    required this.onContact,
    required this.onRequestVisit,
    required this.onSendSummary,
  });

  final AtlasConsultancyContactProfile contact;
  final bool canManageContact;
  final VoidCallback onConfigure;
  final VoidCallback onContact;
  final VoidCallback onRequestVisit;
  final VoidCallback onSendSummary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  child: Icon(Icons.medical_services_outlined),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.role,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        contact.displayName,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        contact.companyLabel,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: contact.hasValidWhatsapp ? onContact : null,
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('Falar no WhatsApp'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      contact.hasValidWhatsapp ? onRequestVisit : null,
                  icon: const Icon(Icons.event_outlined),
                  label: const Text('Solicitar visita'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      contact.hasValidWhatsapp ? onSendSummary : null,
                  icon: const Icon(Icons.summarize_outlined),
                  label: const Text('Enviar resumo'),
                ),
                if (canManageContact)
                  OutlinedButton.icon(
                    onPressed: onConfigure,
                    icon: const Icon(Icons.manage_accounts_outlined),
                    label: Text(
                      contact.configured
                          ? 'Editar responsável'
                          : 'Configurar responsável',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsibleContactDraft {
  const _ResponsibleContactDraft({
    required this.displayName,
    required this.role,
    required this.whatsappNumber,
    required this.companyLabel,
    required this.active,
  });

  final String displayName;
  final String role;
  final String whatsappNumber;
  final String companyLabel;
  final bool active;
}

class _ConsultancyMetric extends StatelessWidget {
  const _ConsultancyMetric({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(child: Icon(icon)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
