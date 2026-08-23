import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/widgets/atlas_module_role_card.dart';
import 'package:projeto_atlas/core/widgets/atlas_module_workspace_guide.dart';
import 'package:projeto_atlas/core/navigation/atlas_product_surface_policy.dart';
import 'package:projeto_atlas/core/widgets/atlas_module_decision_panel.dart';
import 'package:projeto_atlas/core/widgets/atlas_operational_action_bar.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_operations/data/services/atlas_operations_repository.dart';
import 'package:projeto_atlas/features/farm_operations/domain/models/atlas_farm_operation.dart';
import 'package:projeto_atlas/features/farm_operations/presentation/screens/atlas_operations_center_screen.dart';
import 'package:projeto_atlas/features/field_operations/presentation/screens/atlas_field_operations_screen.dart';
import 'package:projeto_atlas/features/paddock/data/services/paddock_storage_service.dart';
import 'package:projeto_atlas/features/paddock/domain/models/paddock_data.dart';
import 'package:projeto_atlas/features/paddock/presentation/screens/paddock_list_screen.dart';

class FarmFieldCenterScreen extends StatefulWidget {
  const FarmFieldCenterScreen({
    required this.farm,
    this.embedded = false,
    super.key,
  });

  final FarmData farm;
  final bool embedded;

  @override
  State<FarmFieldCenterScreen> createState() => _FarmFieldCenterScreenState();
}

class _FarmFieldCenterScreenState extends State<FarmFieldCenterScreen> {
  final PaddockStorageService paddockStorage = PaddockStorageService();
  final AtlasOperationsRepository operationsRepository =
      AtlasOperationsRepository();

  List<PaddockData> paddocks = const [];
  List<AtlasFarmOperation> operations = const [];
  bool loading = true;
  String? error;

  int get activePaddocks => paddocks.where((item) {
    final status = item.status.trim().toLowerCase();
    return status.contains('ocup') ||
        status.contains('ativo') ||
        status.contains('pastejo');
  }).length;

  int get restingPaddocks => paddocks.where((item) {
    final status = item.status.trim().toLowerCase();
    return status.contains('descanso') || status.contains('repouso');
  }).length;

  int get animalsInPaddocks =>
      paddocks.fold(0, (total, item) => total + item.animals);

  int get overdueOperations =>
      operations.where((operation) => operation.isOverdue).length;

  int get openOperationsCount => operations.where((operation) {
    return operation.status != AtlasOperationStatus.completed &&
        operation.status != AtlasOperationStatus.cancelled;
  }).length;

  int get criticalOperations => operations.where((operation) {
    return operation.status != AtlasOperationStatus.completed &&
        operation.status != AtlasOperationStatus.cancelled &&
        operation.priority == AtlasOperationPriority.critical;
  }).length;

  Set<String> get activeTeam => operations
      .where((operation) {
        return operation.status != AtlasOperationStatus.completed &&
            operation.status != AtlasOperationStatus.cancelled;
      })
      .expand((operation) => [
            operation.responsible,
            ...operation.team,
          ])
      .where((value) => value.trim().isNotEmpty)
      .map((value) => value.trim())
      .toSet();

  AtlasModuleAttentionLevel get moduleLevel {
    if (overdueOperations > 0 || criticalOperations > 0) {
      return AtlasModuleAttentionLevel.critical;
    }
    if (openOperationsCount > 0) {
      return AtlasModuleAttentionLevel.attention;
    }
    return AtlasModuleAttentionLevel.normal;
  }

  String get moduleStatusTitle {
    if (moduleLevel == AtlasModuleAttentionLevel.critical) {
      return 'Campo exige ação';
    }
    if (moduleLevel == AtlasModuleAttentionLevel.attention) {
      return 'Campo tem atividades em andamento';
    }
    return 'Rotina de campo sob controle';
  }

  List<AtlasModuleDecisionItem> get decisionItems {
    final items = <AtlasModuleDecisionItem>[];
    if (overdueOperations > 0) {
      items.add(
        AtlasModuleDecisionItem(
          title: '$overdueOperations operação(ões) atrasada(s)',
          description:
              'Revise prazo, responsável, equipe e recursos necessários.',
          icon: Icons.event_busy_outlined,
          level: AtlasModuleAttentionLevel.critical,
        ),
      );
    }
    if (criticalOperations > 0) {
      items.add(
        AtlasModuleDecisionItem(
          title: '$criticalOperations operação(ões) de prioridade crítica',
          description:
              'Confirme execução, capacidade da equipe e equipamentos.',
          icon: Icons.priority_high_outlined,
          level: AtlasModuleAttentionLevel.critical,
        ),
      );
    }
    if (openOperationsCount > 0) {
      items.add(
        AtlasModuleDecisionItem(
          title: '$openOperationsCount atividade(s) aberta(s)',
          description:
              '${activeTeam.length} responsável(is)/membro(s) vinculados às atividades atuais.',
          icon: Icons.groups_outlined,
          level: AtlasModuleAttentionLevel.attention,
        ),
      );
    }
    if (paddocks.isEmpty) {
      items.add(
        const AtlasModuleDecisionItem(
          title: 'Nenhum piquete cadastrado',
          description:
              'Cadastre os piquetes para acompanhar ocupação e descanso.',
          icon: Icons.grass_outlined,
          level: AtlasModuleAttentionLevel.attention,
        ),
      );
    }
    return items;
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        paddockStorage.loadPaddocks(widget.farm.id ?? ''),
        operationsRepository.load(farmId: widget.farm.id),
      ]);

      if (!mounted) return;
      setState(() {
        paddocks = results[0] as List<PaddockData>;
        operations = results[1] as List<AtlasFarmOperation>;
      });
    } catch (exception) {
      if (mounted) {
        setState(() => error = exception.toString());
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openPaddocks() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaddockListScreen(farm: widget.farm),
      ),
    );
    await loadData();
  }

  Future<void> openOperations() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AtlasOperationsCenterScreen(
          farmId: widget.farm.id,
        ),
      ),
    );
    await loadData();
  }

  Future<void> openFieldTools() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AtlasFieldOperationsScreen(),
      ),
    );
    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    final body = loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: loadData,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFF1B5E20),
                        child: Icon(
                          Icons.agriculture_outlined,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Central de Campo',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.farm.name} • piquetes, rotina, equipe e operações',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_outlined),
                      title: const Text(
                        'Parte dos dados de campo não pôde ser carregada',
                      ),
                      subtitle: Text(error!),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                AtlasOperationalActionBar(
                  primaryLabel: 'Nova operação',
                  primaryIcon: Icons.add_task_outlined,
                  onPrimary: openOperations,
                  secondaryLabel: 'Gerenciar piquetes',
                  secondaryIcon: Icons.grass_outlined,
                  onSecondary: openPaddocks,
                  onRefresh: loadData,
                  busy: loading,
                ),
                const SizedBox(height: 16),
                AtlasModuleDecisionPanel(
                  statusTitle: moduleStatusTitle,
                  statusDescription:
                      '${paddocks.length} piquetes • '
                      '$openOperationsCount atividades abertas • '
                      '${activeTeam.length} pessoas vinculadas',
                  items: decisionItems,
                  level: moduleLevel,
                ),
                const SizedBox(height: 16),
                AtlasModuleWorkspaceGuide(
                  moduleLabel: 'Campo',
                  workflows:
                      AtlasProductSurfacePolicy.moduleWorkflows['Campo'] ??
                          const <String>[],
                  specializedFamilies:
                      AtlasProductSurfacePolicy
                              .specializedCapabilityCountByOwner['Campo'] ??
                          0,
                ),
                const SizedBox(height: 16),
                AtlasModuleRoleCard(
                  title: 'Campo é onde o trabalho acontece',
                  responsibility:
                      AtlasProductSurfacePolicy.moduleResponsibility['Campo']!,
                  doesNotReplace:
                      AtlasProductSurfacePolicy.moduleDoesNotReplace['Campo']!,
                  icon: Icons.agriculture_outlined,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    _FieldMetric(
                      title: 'Piquetes',
                      value: '${paddocks.length}',
                      subtitle:
                          '$activePaddocks em uso • $restingPaddocks em descanso',
                      icon: Icons.grass_outlined,
                    ),
                    _FieldMetric(
                      title: 'Animais nos piquetes',
                      value: '$animalsInPaddocks',
                      subtitle: 'Ocupação cadastrada',
                      icon: Icons.pets_outlined,
                    ),
                    _FieldMetric(
                      title: 'Operações abertas',
                      value: '$openOperationsCount',
                      subtitle: '$overdueOperations atrasada(s)',
                      icon: Icons.assignment_outlined,
                    ),
                    _FieldMetric(
                      title: 'Equipe vinculada',
                      value: '${activeTeam.length}',
                      subtitle: 'Responsáveis nas operações abertas',
                      icon: Icons.groups_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'Acessos de campo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _FieldAccessCard(
                      title: 'Piquetes e pastagens',
                      subtitle:
                          'Ocupação, descanso, área e animais por piquete.',
                      icon: Icons.grass_outlined,
                      onTap: openPaddocks,
                    ),
                    _FieldAccessCard(
                      title: 'Operações e equipe',
                      subtitle:
                          'Atividades, responsáveis, equipe, equipamentos, custos e prazos.',
                      icon: Icons.engineering_outlined,
                      onTap: openOperations,
                    ),
                    _FieldAccessCard(
                      title: 'Ferramentas de campo',
                      subtitle:
                          'Registros rápidos, capturas e fila offline para uso operacional.',
                      icon: Icons.mobile_friendly_outlined,
                      onTap: openFieldTools,
                    ),
                  ],
                ),
              ],
            ),
          );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Campo')),
      body: body,
    );
  }
}

class _FieldMetric extends StatelessWidget {
  const _FieldMetric({
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
              CircleAvatar(
                backgroundColor: const Color(0xFFE8F5E9),
                child: Icon(icon, color: const Color(0xFF1B5E20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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

class _FieldAccessCard extends StatelessWidget {
  const _FieldAccessCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: Icon(icon, color: const Color(0xFF1B5E20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
