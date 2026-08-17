import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_weekly_review.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_weekly_review_controller.dart';

class AtlasExecutionWeeklyReviewScreen extends StatefulWidget {
  const AtlasExecutionWeeklyReviewScreen({
    required this.actionController,
    super.key,
  });

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasExecutionWeeklyReviewScreen> createState() =>
      _AtlasExecutionWeeklyReviewScreenState();
}

class _AtlasExecutionWeeklyReviewScreenState
    extends State<AtlasExecutionWeeklyReviewScreen> {
  late final AtlasExecutionWeeklyReviewController controller;

  @override
  void initState() {
    super.initState();

    controller = AtlasExecutionWeeklyReviewController(
      actionController: widget.actionController,
    )..load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Revisão semanal'),
            actions: [
              IconButton(
                tooltip: 'Gerar nova revisão',
                onPressed: controller.isLoading ? null : _generateReview,
                icon: const Icon(Icons.auto_graph_outlined),
              ),
              IconButton(
                tooltip: 'Atualizar histórico',
                onPressed: controller.isLoading ? null : controller.load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: _buildBody(),
          floatingActionButton: widget.actionController.actions.isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: controller.isLoading ? null : _generateReview,
                  icon: const Icon(Icons.playlist_add_check),
                  label: const Text('Gerar revisão'),
                ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (controller.isLoading && controller.reviews.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage != null && controller.reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Não foi possível carregar as revisões: '
            '${controller.errorMessage}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (controller.reviews.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_view_week_outlined, size: 56),
              SizedBox(height: 16),
              Text(
                'Nenhuma revisão semanal foi gerada.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 8),
              Text(
                'Use o botão “Gerar revisão” para consolidar '
                'resultados, gargalos e prioridades da semana.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: controller.reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final review = controller.reviews[index];

        return Card(
          child: InkWell(
            onTap: () => _openReview(review),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_view_week_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Semana de '
                          '${DateFormat('dd/MM').format(review.periodStart)} '
                          'a '
                          '${DateFormat('dd/MM/yyyy').format(review.periodEnd)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            controller.delete(review);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Excluir revisão'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text('${review.completedInPeriod} concluída(s)'),
                      ),
                      Chip(label: Text('${review.overdueActions} atrasada(s)')),
                      Chip(
                        label: Text(
                          '${review.executionHealthPercent.toStringAsFixed(0)}% saúde',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    review.focusActions.isEmpty
                        ? 'Sem foco prioritário definido.'
                        : 'Foco principal: '
                              '${review.focusActions.first}',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateReview() async {
    final review = await controller.generate();

    if (!mounted) {
      return;
    }

    await _openReview(review);
  }

  Future<void> _openReview(AtlasExecutionWeeklyReview review) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Revisão de '
            '${DateFormat('dd/MM/yyyy').format(review.generatedAt)}',
          ),
          content: SizedBox(
            width: 720,
            height: 560,
            child: ListView(
              children: [
                _ReviewMetrics(review: review),
                const SizedBox(height: 18),
                _ReviewSection(
                  title: 'Conquistas da semana',
                  icon: Icons.task_alt,
                  items: review.achievements,
                ),
                const SizedBox(height: 14),
                _ReviewSection(
                  title: 'Gargalos identificados',
                  icon: Icons.warning_amber_rounded,
                  items: review.bottlenecks,
                ),
                const SizedBox(height: 14),
                _ReviewSection(
                  title: 'Foco para o próximo ciclo',
                  icon: Icons.flag_outlined,
                  items: review.focusActions,
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
}

class _ReviewMetrics extends StatelessWidget {
  const _ReviewMetrics({required this.review});

  final AtlasExecutionWeeklyReview review;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        Chip(label: Text('${review.totalActions} ações')),
        Chip(label: Text('${review.openActions} abertas')),
        Chip(label: Text('${review.completedInPeriod} concluídas')),
        Chip(label: Text('${review.overdueActions} atrasadas')),
        Chip(label: Text('${review.blockedActions} bloqueadas')),
        Chip(
          label: Text(
            '${review.averageProgressPercent.toStringAsFixed(0)}% progresso',
          ),
        ),
        Chip(
          label: Text(
            '${review.executionHealthPercent.toStringAsFixed(0)}% saúde',
          ),
        ),
        Chip(
          label: Text(
            'R\$ ${review.expectedFinancialImpact.toStringAsFixed(2)} impacto',
          ),
        ),
      ],
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: Icon(Icons.circle, size: 7),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
