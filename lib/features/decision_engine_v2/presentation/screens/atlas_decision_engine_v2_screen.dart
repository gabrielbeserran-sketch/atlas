import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/decision_engine_v2/domain/models/atlas_decision_engine_v2_data.dart';

class AtlasDecisionEngineV2Screen
    extends StatefulWidget {
  const AtlasDecisionEngineV2Screen({
    required this.data,
    this.onOpenFarm,
    super.key,
  });

  final AtlasDecisionEngineV2Data data;
  final ValueChanged<String>? onOpenFarm;

  @override
  State<AtlasDecisionEngineV2Screen>
      createState() {
    return _AtlasDecisionEngineV2ScreenState();
  }
}

class _AtlasDecisionEngineV2ScreenState
    extends State<AtlasDecisionEngineV2Screen> {
  AtlasDecisionV2Horizon? selectedHorizon;
  String? selectedFarm;

  AtlasDecisionEngineV2Data get data {
    return widget.data;
  }

  List<String> get farms {
    final result = data.rankedActions
        .map((item) => item.farmName)
        .toSet()
        .toList()
      ..sort();

    return result;
  }

  List<AtlasDecisionV2Action>
      get filteredActions {
    return data.rankedActions.where((item) {
      if (selectedFarm != null &&
          item.farmName != selectedFarm) {
        return false;
      }

      if (selectedHorizon != null &&
          item.horizon != selectedHorizon) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Atlas Decision Engine 2.0',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1240,
            ),
            child: data.hasData
                ? ListView(
                    padding:
                        const EdgeInsets.all(22),
                    children: [
                      _DecisionV2Hero(data: data),
                      if (data.bestActionToday !=
                          null) ...[
                        const SizedBox(height: 24),
                        const _SectionTitle(
                          title:
                              'Melhor ação para hoje',
                          subtitle:
                              'A recomendação com maior combinação de impacto, urgência e confiança.',
                        ),
                        const SizedBox(height: 12),
                        _BestActionCard(
                          action:
                              data.bestActionToday!,
                          onOpenFarm:
                              widget.onOpenFarm,
                        ),
                      ],
                      const SizedBox(height: 24),
                      _DecisionFilters(
                        farms: farms,
                        selectedFarm:
                            selectedFarm,
                        selectedHorizon:
                            selectedHorizon,
                        onFarmChanged: (value) {
                          setState(() {
                            selectedFarm = value;
                          });
                        },
                        onHorizonChanged:
                            (value) {
                          setState(() {
                            selectedHorizon = value;
                          });
                        },
                      ),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title:
                            'Ranking unificado de ações',
                        subtitle:
                            'Plano diário, semanal e mensal priorizado automaticamente.',
                      ),
                      const SizedBox(height: 13),
                      if (filteredActions.isEmpty)
                        const _EmptySection()
                      else
                        ...filteredActions.map(
                          (item) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(
                                bottom: 12,
                              ),
                              child:
                                  _ActionCard(
                                action: item,
                                onOpenFarm:
                                    widget.onOpenFarm,
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title: 'Simulações',
                        subtitle:
                            'Comparação entre executar agora, esperar ou aumentar recursos.',
                      ),
                      const SizedBox(height: 13),
                      _SimulationList(
                        simulations:
                            data.simulations,
                        onOpenFarm:
                            widget.onOpenFarm,
                      ),
                      const SizedBox(height: 32),
                    ],
                  )
                : const _EmptyDecisionView(),
          ),
        ),
      ),
    );
  }
}

class _DecisionV2Hero extends StatelessWidget {
  const _DecisionV2Hero({
    required this.data,
  });

  final AtlasDecisionEngineV2Data data;

  @override
  Widget build(BuildContext context) {
    final color =
        _statusColor(data.status);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0A192F),
            Color(0xFF17324D),
            Color(0xFF28536B),
          ],
        ),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          final compact =
              constraints.maxWidth < 760;

          final information = Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.hub_outlined,
                    color: Color(0xFFB3E5FC),
                    size: 32,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Decision Engine 2.0',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                data.summary,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _HeroMetric(
                    label: 'Hoje',
                    value:
                        data.dailyPlan.length,
                  ),
                  _HeroMetric(
                    label: 'Semana',
                    value:
                        data.weeklyPlan.length,
                  ),
                  _HeroMetric(
                    label: 'Mês',
                    value:
                        data.monthlyPlan.length,
                  ),
                  _HeroMetric(
                    label: 'Simulações',
                    value:
                        data.simulations.length,
                  ),
                ],
              ),
            ],
          );

          final side = Container(
            width: 230,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  data.score.toStringAsFixed(0),
                  style: TextStyle(
                    color: color,
                    fontSize: 42,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                Text(
                  atlasDecisionEngineV2StatusLabel(
                    data.status,
                  ),
                  style: TextStyle(
                    color: color,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${data.confidencePercent.toStringAsFixed(0)}% de confiança',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                information,
                const SizedBox(height: 20),
                side,
              ],
            );
          }

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(child: information),
              const SizedBox(width: 24),
              side,
            ],
          );
        },
      ),
    );
  }
}

class _BestActionCard extends StatelessWidget {
  const _BestActionCard({
    required this.action,
    required this.onOpenFarm,
  });

  final AtlasDecisionV2Action action;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    final color =
        _priorityColor(action.priority);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bolt_outlined,
                  color: color,
                  size: 31,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      Text(
                        action.farmName,
                        style: TextStyle(
                          color: color,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  action.decisionScore
                      .toStringAsFixed(0),
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              action.description,
              style: const TextStyle(
                color: Colors.black54,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  label:
                      atlasDecisionV2PriorityLabel(
                    action.priority,
                  ),
                  color: color,
                ),
                _InfoChip(
                  label:
                      'Urgência: ${atlasDecisionV2UrgencyLabel(action.urgency)}',
                  color:
                      const Color(0xFFEF6C00),
                ),
                _InfoChip(
                  label:
                      'Risco: ${atlasDecisionV2RiskLabel(action.risk)}',
                  color:
                      const Color(0xFFC62828),
                ),
                _InfoChip(
                  label:
                      'Esforço: ${atlasDecisionV2EffortLabel(action.effort)}',
                  color:
                      const Color(0xFF6A1B9A),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              'Impacto financeiro esperado: '
              'R\$ ${action.expectedFinancialImpact.toStringAsFixed(2)}',
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              action.reasoning,
              style: const TextStyle(
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (onOpenFarm != null) ...[
              const SizedBox(height: 12),
              ActionChip(
                label:
                    const Text('Abrir fazenda'),
                onPressed: () {
                  onOpenFarm!(action.farmName);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DecisionFilters
    extends StatelessWidget {
  const _DecisionFilters({
    required this.farms,
    required this.selectedFarm,
    required this.selectedHorizon,
    required this.onFarmChanged,
    required this.onHorizonChanged,
  });

  final List<String> farms;
  final String? selectedFarm;
  final AtlasDecisionV2Horizon?
      selectedHorizon;

  final ValueChanged<String?>
      onFarmChanged;

  final ValueChanged<AtlasDecisionV2Horizon?>
      onHorizonChanged;

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
              width: 250,
              child: DropdownButtonFormField<
                  String?>(
                initialValue: selectedFarm,
                decoration:
                    const InputDecoration(
                  labelText: 'Fazenda',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text(
                      'Todas as fazendas',
                    ),
                  ),
                  ...farms.map((farm) {
                    return DropdownMenuItem(
                      value: farm,
                      child: Text(farm),
                    );
                  }),
                ],
                onChanged: onFarmChanged,
              ),
            ),
            SizedBox(
              width: 230,
              child: DropdownButtonFormField<
                  AtlasDecisionV2Horizon?>(
                initialValue:
                    selectedHorizon,
                decoration:
                    const InputDecoration(
                  labelText: 'Horizonte',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text(
                      'Todos os horizontes',
                    ),
                  ),
                  ...AtlasDecisionV2Horizon.values
                      .map((horizon) {
                    return DropdownMenuItem(
                      value: horizon,
                      child: Text(
                        atlasDecisionV2HorizonLabel(
                          horizon,
                        ),
                      ),
                    );
                  }),
                ],
                onChanged:
                    onHorizonChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.action,
    required this.onOpenFarm,
  });

  final AtlasDecisionV2Action action;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    final color =
        _priorityColor(action.priority);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              color.withValues(
            alpha: 0.12,
          ),
          child: Text(
            action.position.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          action.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${action.farmName} · '
          '${atlasDecisionV2HorizonLabel(action.horizon)} · '
          '${action.deadlineDays} dias\n'
          '${action.description}',
        ),
        isThreeLine: true,
        trailing: Text(
          action.decisionScore
              .toStringAsFixed(0),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: onOpenFarm == null
            ? null
            : () {
                onOpenFarm!(action.farmName);
              },
      ),
    );
  }
}

class _SimulationList
    extends StatelessWidget {
  const _SimulationList({
    required this.simulations,
    required this.onOpenFarm,
  });

  final List<AtlasDecisionV2Simulation>
      simulations;

  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (simulations.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: simulations.take(18).map((item) {
        return Card(
          child: ListTile(
            leading: const Icon(
              Icons.science_outlined,
              color: Color(0xFF6A1B9A),
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${atlasDecisionV2SimulationTypeLabel(item.type)} · '
              '${item.delayDays} dias de espera\n'
              '${item.recommendation}',
            ),
            isThreeLine: true,
            trailing: Text(
              'R\$ ${item.projectedFinancialImpact.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: onOpenFarm == null
                ? null
                : () {
                    onOpenFarm!(item.farmName);
                  },
          ),
        );
      }).toList(),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(10),
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
  const _HeroMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.09,
        ),
        borderRadius:
            BorderRadius.circular(12),
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
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Center(
          child: Text(
            'Nenhum item disponível.',
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyDecisionView
    extends StatelessWidget {
  const _EmptyDecisionView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nenhuma ação priorizada disponível.',
        style: TextStyle(
          color: Colors.black54,
        ),
      ),
    );
  }
}

Color _statusColor(
  AtlasDecisionEngineV2Status status,
) {
  switch (status) {
    case AtlasDecisionEngineV2Status.excellent:
      return const Color(0xFF80CBC4);

    case AtlasDecisionEngineV2Status.adequate:
      return const Color(0xFFA5D6A7);

    case AtlasDecisionEngineV2Status.attention:
      return const Color(0xFFFFCC80);

    case AtlasDecisionEngineV2Status.critical:
      return const Color(0xFFEF9A9A);
  }
}

Color _priorityColor(
  AtlasDecisionV2Priority priority,
) {
  switch (priority) {
    case AtlasDecisionV2Priority.low:
      return const Color(0xFF2E7D32);

    case AtlasDecisionV2Priority.medium:
      return const Color(0xFF1565C0);

    case AtlasDecisionV2Priority.high:
      return const Color(0xFFEF6C00);

    case AtlasDecisionV2Priority.critical:
      return const Color(0xFFC62828);
  }
}
