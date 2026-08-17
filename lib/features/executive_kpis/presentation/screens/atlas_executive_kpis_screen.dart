import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/executive_goals/data/services/atlas_executive_goal_storage_service.dart';
import 'package:projeto_atlas/features/executive_goals/domain/models/atlas_executive_goal.dart';
import 'package:projeto_atlas/features/executive_goals/domain/services/atlas_executive_goal_service.dart';
import 'package:projeto_atlas/features/executive_goals/presentation/screens/atlas_executive_goals_screen.dart';
import 'package:projeto_atlas/features/executive_kpis/domain/models/atlas_executive_kpi.dart';
import 'package:projeto_atlas/features/executive_kpis/domain/models/atlas_executive_kpi_history.dart';
import 'package:projeto_atlas/features/executive_kpis/presentation/screens/atlas_executive_kpi_history_screen.dart';

class AtlasExecutiveKpisScreen extends StatefulWidget {
  const AtlasExecutiveKpisScreen({
    required this.data,
    this.history,
    this.onOpenFarm,
    super.key,
  });

  final AtlasExecutiveKpiDashboardData data;

  final AtlasExecutiveKpiHistorySummary? history;

  final ValueChanged<String>? onOpenFarm;

  @override
  State<AtlasExecutiveKpisScreen> createState() {
    return _AtlasExecutiveKpisScreenState();
  }
}

class _AtlasExecutiveKpisScreenState extends State<AtlasExecutiveKpisScreen> {
  final AtlasExecutiveGoalStorageService goalStorageService =
      const AtlasExecutiveGoalStorageService();

  final AtlasExecutiveGoalService goalService =
      const AtlasExecutiveGoalService();

  List<AtlasExecutiveGoal> goals = [];

  bool isLoadingGoals = true;

  String? selectedFarm;

  AtlasExecutiveKpiCategory? selectedCategory;

  AtlasExecutiveKpiStatus? selectedStatus;

  AtlasExecutiveKpiDashboardData get data => widget.data;

  List<AtlasExecutiveKpi> get filteredKpis {
    return data.kpis.where((kpi) {
      if (selectedFarm != null && kpi.farmName != selectedFarm) {
        return false;
      }

      if (selectedCategory != null && kpi.category != selectedCategory) {
        return false;
      }

      if (selectedStatus != null && kpi.status != selectedStatus) {
        return false;
      }

      return true;
    }).toList()..sort(
      (first, second) => first.targetAchievementPercent.compareTo(
        second.targetAchievementPercent,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final stored = await goalStorageService.load();

    final synchronized = goalService.synchronizeWithKpis(
      goals: stored,
      kpis: data.kpis,
    );

    await goalStorageService.save(synchronized);

    if (!mounted) {
      return;
    }

    setState(() {
      goals = synchronized;
      isLoadingGoals = false;
    });
  }

  AtlasExecutiveGoalDashboardData get goalsData {
    return goalService.buildDashboard(goals: goals);
  }

  Future<void> _openGoals() async {
    final currentData = goalsData;

    if (!currentData.hasGoals) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Crie uma meta a partir de um indicador para iniciar o acompanhamento.',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return AtlasExecutiveGoalsScreen(
            data: currentData,
            onOpenFarm: widget.onOpenFarm,
          );
        },
      ),
    );

    await _loadGoals();
  }

  Future<void> _createGoalFromKpi(AtlasExecutiveKpi kpi) async {
    final targetController = TextEditingController(
      text: kpi.targetValue.toStringAsFixed(
        kpi.targetValue == kpi.targetValue.roundToDouble() ? 0 : 1,
      ),
    );

    final responsibleController = TextEditingController();

    final notesController = TextEditingController();

    var deadline = DateTime.now().add(const Duration(days: 90));

    final result = await showDialog<_GoalCreationResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Criar meta inteligente'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kpi.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${kpi.farmName} · '
                        'Atual: ${_formatValue(kpi.value, kpi.unit)}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: targetController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Valor-alvo (${kpi.unit})',
                          prefixIcon: const Icon(Icons.flag_outlined),
                        ),
                      ),
                      const SizedBox(height: 13),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_outlined),
                        title: const Text('Prazo da meta'),
                        subtitle: Text(_goalDate(deadline)),
                        trailing: IconButton(
                          tooltip: 'Escolher prazo',
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: deadline,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 3650),
                              ),
                            );

                            if (picked != null) {
                              setDialogState(() {
                                deadline = picked;
                              });
                            }
                          },
                          icon: const Icon(Icons.edit_calendar),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: responsibleController,
                        decoration: const InputDecoration(
                          labelText: 'Responsável',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 13),
                      TextField(
                        controller: notesController,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Observações',
                          hintText:
                              'Descreva estratégia, recursos ou pontos de atenção.',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final normalized = targetController.text
                        .trim()
                        .replaceAll('.', '')
                        .replaceAll(',', '.');

                    final target = double.tryParse(normalized);

                    if (target == null) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Digite um valor-alvo válido.'),
                        ),
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      _GoalCreationResult(
                        targetValue: target,
                        deadline: deadline,
                        responsibleName: responsibleController.text.trim(),
                        notes: notesController.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Criar meta'),
                ),
              ],
            );
          },
        );
      },
    );

    targetController.dispose();
    responsibleController.dispose();
    notesController.dispose();

    if (result == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    final alreadyExists = goals.any((goal) {
      return goal.kpiId == kpi.id &&
          goal.status != AtlasExecutiveGoalStatus.completed &&
          goal.status != AtlasExecutiveGoalStatus.cancelled;
    });

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Já existe uma meta ativa para este indicador.'),
        ),
      );
      return;
    }

    final goal = goalService.createFromKpi(
      kpi: kpi,
      targetValue: result.targetValue,
      deadline: result.deadline,
      responsibleName: result.responsibleName,
      notes: result.notes,
    );

    final updatedGoals = [...goals, goal];

    await goalStorageService.save(updatedGoals);

    if (!mounted) {
      return;
    }

    setState(() {
      goals = updatedGoals;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Meta criada para "${kpi.title}".'),
        action: SnackBarAction(label: 'Abrir metas', onPressed: _openGoals),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Indicadores Inteligentes',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Metas Inteligentes',
            onPressed: isLoadingGoals || goals.isEmpty ? null : _openGoals,
            icon: const Icon(Icons.flag_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: data.hasData
                ? ListView(
                    padding: const EdgeInsets.all(22),
                    children: [
                      _KpiHero(data: data),
                      if (widget.history != null) ...[
                        const SizedBox(height: 18),
                        _KpiHistoryAccessCard(
                          history: widget.history!,
                          onOpen: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) {
                                  return AtlasExecutiveKpiHistoryScreen(
                                    history: widget.history!,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                      if (!isLoadingGoals) ...[
                        const SizedBox(height: 18),
                        _KpiGoalsAccessCard(
                          data: goalsData,
                          onOpen: _openGoals,
                        ),
                      ],
                      const SizedBox(height: 24),
                      _KpiFilters(
                        farms: data.farms,
                        selectedFarm: selectedFarm,
                        selectedCategory: selectedCategory,
                        selectedStatus: selectedStatus,
                        onFarmChanged: (value) {
                          setState(() {
                            selectedFarm = value;
                          });
                        },
                        onCategoryChanged: (value) {
                          setState(() {
                            selectedCategory = value;
                          });
                        },
                        onStatusChanged: (value) {
                          setState(() {
                            selectedStatus = value;
                          });
                        },
                      ),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title: 'Ranking das fazendas',
                        subtitle:
                            'Desempenho consolidado de todos os indicadores.',
                      ),
                      const SizedBox(height: 13),
                      _FarmKpiGrid(
                        farms: data.farms,
                        onOpenFarm: widget.onOpenFarm,
                      ),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title: 'Desempenho por categoria',
                        subtitle:
                            'Produção, reprodução, saúde, financeiro, gestão e inteligência.',
                      ),
                      const SizedBox(height: 13),
                      _CategoryKpiGrid(categories: data.categories),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title: 'Indicadores',
                        subtitle:
                            'Metas, desempenho, tendência e classificação.',
                      ),
                      const SizedBox(height: 13),
                      _KpiList(
                        kpis: filteredKpis,
                        onOpenFarm: widget.onOpenFarm,
                        onCreateGoal: _createGoalFromKpi,
                      ),
                      const SizedBox(height: 32),
                    ],
                  )
                : const _EmptyKpiView(),
          ),
        ),
      ),
    );
  }
}

class _KpiGoalsAccessCard extends StatelessWidget {
  const _KpiGoalsAccessCard({required this.data, required this.onOpen});

  final AtlasExecutiveGoalDashboardData data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final progress = data.progress;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data.hasGoals ? onOpen : null,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF8D6E00).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.flag_outlined,
                  color: Color(0xFF8D6E00),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Metas Inteligentes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.hasGoals
                          ? '${progress.active} no prazo · '
                                '${progress.atRisk} em risco · '
                                '${progress.overdue} atrasadas · '
                                '${progress.completed} concluídas'
                          : 'Use o botão “Criar meta” em um indicador para iniciar.',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (data.hasGoals)
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 17,
                  color: Colors.black45,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalCreationResult {
  const _GoalCreationResult({
    required this.targetValue,
    required this.deadline,
    required this.responsibleName,
    required this.notes,
  });

  final double targetValue;
  final DateTime deadline;
  final String responsibleName;
  final String notes;
}

String _goalDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');

  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

class _KpiHistoryAccessCard extends StatelessWidget {
  const _KpiHistoryAccessCard({required this.history, required this.onOpen});

  final AtlasExecutiveKpiHistorySummary history;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.show_chart_outlined,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Evolução dos Indicadores',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      history.hasHistory
                          ? '${history.improvingCount} em melhora · '
                                '${history.stableCount} estáveis · '
                                '${history.worseningCount} em piora'
                          : 'O primeiro snapshot foi salvo. Os gráficos aparecerão após um novo registro em outro dia.',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 17,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiHero extends StatelessWidget {
  const _KpiHero({required this.data});

  final AtlasExecutiveKpiDashboardData data;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(data.operationStatus);

    final critical = data.criticalKpis.isEmpty ? null : data.criticalKpis.first;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3D2E), Color(0xFF165C45), Color(0xFF1D7356)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          final information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.monitor_heart_outlined,
                    color: Color(0xFFE4C86A),
                    size: 31,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Central de KPIs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                data.summary,
                style: const TextStyle(color: Colors.white70, height: 1.48),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _HeroMetric(label: 'Fazendas', value: data.farms.length),
                  _HeroMetric(label: 'Indicadores', value: data.kpis.length),
                  _HeroMetric(
                    label: 'Críticos',
                    value: data.criticalKpis.length,
                  ),
                  _HeroMetric(
                    label: 'Acima da meta',
                    value: data.positiveHighlights.length,
                  ),
                ],
              ),
            ],
          );

          final score = Container(
            width: 230,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Score da operação',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Text(
                  data.operationScore.toStringAsFixed(0),
                  style: TextStyle(
                    color: color,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  atlasExecutiveKpiStatusLabel(data.operationStatus),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: data.operationScore / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                if (critical != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Prioridade: ${critical.title}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE4C86A),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [information, const SizedBox(height: 20), score],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: information),
              const SizedBox(width: 24),
              score,
            ],
          );
        },
      ),
    );
  }
}

class _KpiFilters extends StatelessWidget {
  const _KpiFilters({
    required this.farms,
    required this.selectedFarm,
    required this.selectedCategory,
    required this.selectedStatus,
    required this.onFarmChanged,
    required this.onCategoryChanged,
    required this.onStatusChanged,
  });

  final List<AtlasExecutiveFarmKpiSummary> farms;

  final String? selectedFarm;

  final AtlasExecutiveKpiCategory? selectedCategory;

  final AtlasExecutiveKpiStatus? selectedStatus;

  final ValueChanged<String?> onFarmChanged;

  final ValueChanged<AtlasExecutiveKpiCategory?> onCategoryChanged;

  final ValueChanged<AtlasExecutiveKpiStatus?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 270,
              child: DropdownButtonFormField<String?>(
                initialValue: selectedFarm,
                decoration: const InputDecoration(
                  labelText: 'Fazenda',
                  prefixIcon: Icon(Icons.agriculture_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todas as fazendas'),
                  ),
                  ...farms.map((farm) {
                    return DropdownMenuItem(
                      value: farm.farmName,
                      child: Text(farm.farmName),
                    );
                  }),
                ],
                onChanged: onFarmChanged,
              ),
            ),
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<AtlasExecutiveKpiCategory?>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todas as categorias'),
                  ),
                  ...AtlasExecutiveKpiCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(atlasExecutiveKpiCategoryLabel(category)),
                    );
                  }),
                ],
                onChanged: onCategoryChanged,
              ),
            ),
            SizedBox(
              width: 230,
              child: DropdownButtonFormField<AtlasExecutiveKpiStatus?>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Classificação',
                  prefixIcon: Icon(Icons.filter_alt_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todas as classificações'),
                  ),
                  ...AtlasExecutiveKpiStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(atlasExecutiveKpiStatusLabel(status)),
                    );
                  }),
                ],
                onChanged: onStatusChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmKpiGrid extends StatelessWidget {
  const _FarmKpiGrid({required this.farms, required this.onOpenFarm});

  final List<AtlasExecutiveFarmKpiSummary> farms;

  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: farms.map((farm) {
            final color = _statusColor(farm.status);

            return SizedBox(
              width: width,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onOpenFarm == null
                      ? null
                      : () {
                          onOpenFarm!(farm.farmName);
                        },
                  child: Padding(
                    padding: const EdgeInsets.all(17),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.agriculture_outlined, color: color),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                farm.farmName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              farm.score.toStringAsFixed(0),
                              style: TextStyle(
                                color: color,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 11),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: farm.score / 100,
                            backgroundColor: color.withValues(alpha: 0.10),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                        const SizedBox(height: 11),
                        Text(
                          '${farm.excellent} excelentes · '
                          '${farm.adequate} adequados · '
                          '${farm.attention} atenção · '
                          '${farm.critical} críticos',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                        if (farm.mainCriticalKpi != null) ...[
                          const SizedBox(height: 9),
                          Text(
                            'Prioridade: ${farm.mainCriticalKpi!.title}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CategoryKpiGrid extends StatelessWidget {
  const _CategoryKpiGrid({required this.categories});

  final List<AtlasExecutiveKpiCategorySummary> categories;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: categories.map((category) {
        final color = _statusColor(category.status);

        return SizedBox(
          width: 245,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_categoryIcon(category.category), color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category.label,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        category.score.toStringAsFixed(0),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      minHeight: 7,
                      value: category.score / 100,
                      backgroundColor: color.withValues(alpha: 0.10),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${category.totalKpis} indicadores · '
                    '${category.criticalKpis} críticos',
                    style: const TextStyle(color: Colors.black54, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _KpiList extends StatelessWidget {
  const _KpiList({
    required this.kpis,
    required this.onOpenFarm,
    required this.onCreateGoal,
  });

  final List<AtlasExecutiveKpi> kpis;

  final ValueChanged<String>? onOpenFarm;

  final ValueChanged<AtlasExecutiveKpi> onCreateGoal;

  @override
  Widget build(BuildContext context) {
    if (kpis.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(22),
          child: Center(
            child: Text(
              'Nenhum indicador encontrado com os filtros atuais.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ),
      );
    }

    return Column(
      children: kpis.map((kpi) {
        final color = _statusColor(kpi.status);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(_categoryIcon(kpi.category), color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                kpi.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _KpiStatusBadge(status: kpi.status),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${kpi.farmName} · '
                          '${atlasExecutiveKpiCategoryLabel(kpi.category)}',
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          kpi.description,
                          style: const TextStyle(
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                minHeight: 8,
                                value: (kpi.targetAchievementPercent / 100)
                                    .clamp(0.0, 1.0),
                                backgroundColor: color.withValues(alpha: 0.10),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${kpi.targetAchievementPercent.toStringAsFixed(0)}% da meta',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _KpiInfoChip(
                              label:
                                  'Atual: ${_formatValue(kpi.value, kpi.unit)}',
                              color: color,
                            ),
                            _KpiInfoChip(
                              label:
                                  'Meta: ${_formatValue(kpi.targetValue, kpi.unit)}',
                              color: const Color(0xFF1565C0),
                            ),
                            _KpiInfoChip(
                              label:
                                  '${atlasExecutiveKpiTrendLabel(kpi.trend)} '
                                  '${kpi.previousValue == null ? '' : '${kpi.trendPercent >= 0 ? '+' : ''}${kpi.trendPercent.toStringAsFixed(1)}%'}',
                              color: _trendColor(kpi.trend),
                            ),
                            if (kpi.sourceLabel.isNotEmpty)
                              _KpiInfoChip(
                                label: kpi.sourceLabel,
                                color: const Color(0xFF6A1B9A),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ActionChip(
                          avatar: const Icon(Icons.flag_outlined, size: 16),
                          label: const Text('Criar meta'),
                          onPressed: () {
                            onCreateGoal(kpi);
                          },
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(
                            Icons.agriculture_outlined,
                            size: 16,
                          ),
                          label: const Text('Abrir fazenda'),
                          onPressed: onOpenFarm == null
                              ? null
                              : () {
                                  onOpenFarm!(kpi.farmName);
                                },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatValue(kpi.value, kpi.unit),
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _KpiStatusBadge extends StatelessWidget {
  const _KpiStatusBadge({required this.status});

  final AtlasExecutiveKpiStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        atlasExecutiveKpiStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _KpiInfoChip extends StatelessWidget {
  const _KpiInfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _EmptyKpiView extends StatelessWidget {
  const _EmptyKpiView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monitor_heart_outlined, size: 58, color: Colors.black38),
            SizedBox(height: 14),
            Text(
              'Nenhum indicador disponível',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 7),
            Text(
              'Os indicadores aparecerão após o carregamento dos dados das fazendas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(AtlasExecutiveKpiStatus status) {
  switch (status) {
    case AtlasExecutiveKpiStatus.excellent:
      return const Color(0xFF1B5E20);

    case AtlasExecutiveKpiStatus.adequate:
      return const Color(0xFF2E7D32);

    case AtlasExecutiveKpiStatus.attention:
      return const Color(0xFFEF6C00);

    case AtlasExecutiveKpiStatus.critical:
      return const Color(0xFFC62828);
  }
}

Color _trendColor(AtlasExecutiveKpiTrend trend) {
  switch (trend) {
    case AtlasExecutiveKpiTrend.strongUp:
    case AtlasExecutiveKpiTrend.up:
      return const Color(0xFF1B5E20);

    case AtlasExecutiveKpiTrend.stable:
      return const Color(0xFF1565C0);

    case AtlasExecutiveKpiTrend.down:
    case AtlasExecutiveKpiTrend.strongDown:
      return const Color(0xFFC62828);

    case AtlasExecutiveKpiTrend.unavailable:
      return const Color(0xFF616161);
  }
}

IconData _categoryIcon(AtlasExecutiveKpiCategory category) {
  switch (category) {
    case AtlasExecutiveKpiCategory.production:
      return Icons.trending_up_outlined;

    case AtlasExecutiveKpiCategory.reproduction:
      return Icons.favorite_outline;

    case AtlasExecutiveKpiCategory.health:
      return Icons.health_and_safety_outlined;

    case AtlasExecutiveKpiCategory.finance:
      return Icons.account_balance_wallet_outlined;

    case AtlasExecutiveKpiCategory.management:
      return Icons.task_alt_outlined;

    case AtlasExecutiveKpiCategory.intelligence:
      return Icons.psychology_outlined;
  }
}

String _formatValue(double value, String unit) {
  if (unit == 'R\$') {
    return _currency(value);
  }

  final decimals = value == value.roundToDouble() ? 0 : 1;

  if (unit.isEmpty) {
    return value.toStringAsFixed(decimals);
  }

  return '${value.toStringAsFixed(decimals)} $unit';
}

String _currency(double value) {
  final fixed = value.abs().toStringAsFixed(2);

  final parts = fixed.split('.');

  final integer = parts.first;
  final decimal = parts.last;

  final buffer = StringBuffer();

  for (var index = 0; index < integer.length; index++) {
    final remaining = integer.length - index;

    buffer.write(integer[index]);

    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  final sign = value < 0 ? '-' : '';

  return '${sign}R\$ ${buffer.toString()},$decimal';
}
