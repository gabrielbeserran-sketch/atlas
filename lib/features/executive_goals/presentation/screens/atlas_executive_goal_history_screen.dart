import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/executive_goals/domain/models/atlas_executive_goal_history.dart';

class AtlasExecutiveGoalHistoryScreen
    extends StatelessWidget {
  const AtlasExecutiveGoalHistoryScreen({
    required this.data,
    super.key,
  });

  final AtlasExecutiveGoalHistorySummary data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Histórico das Metas',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: data.hasHistory
          ? ListView(
              padding: const EdgeInsets.all(22),
              children: [
                _Hero(data: data),
                const SizedBox(height: 22),
                ...data.series.map(
                  (series) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: _SeriesCard(
                      series: series,
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: Text(
                'Nenhum histórico de metas disponível.',
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),
            ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.data,
  });

  final AtlasExecutiveGoalHistorySummary data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2A1B3D),
            Color(0xFF4A2C6D),
            Color(0xFF68428C),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Evolução das Metas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.summary,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeriesCard extends StatelessWidget {
  const _SeriesCard({
    required this.series,
  });

  final AtlasExecutiveGoalHistorySeries series;

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(series.riskLevel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline_outlined,
                  color: color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    series.kpiTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  atlasExecutiveGoalRiskLevelLabel(
                    series.riskLevel,
                  ),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              series.farmName,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              minHeight: 9,
              value:
                  series.currentProgressPercent / 100,
              backgroundColor:
                  color.withValues(alpha: 0.10),
              valueColor:
                  AlwaysStoppedAnimation<Color>(
                color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${series.currentProgressPercent.toStringAsFixed(0)}% concluído · '
              '${series.averageDailyProgress.toStringAsFixed(2)}% por dia',
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              series.projectedCompletionDate == null
                  ? 'Sem previsão de conclusão.'
                  : 'Previsão de conclusão: '
                      '${_date(series.projectedCompletionDate!)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (series.events.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Últimos eventos',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...series.events.reversed
                  .take(6)
                  .map(
                    (event) => Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 6,
                      ),
                      child: Text(
                        '${_dateTime(event.recordedAt)} · '
                        '${event.description}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

Color _riskColor(
  AtlasExecutiveGoalRiskLevel level,
) {
  switch (level) {
    case AtlasExecutiveGoalRiskLevel.onTrack:
      return const Color(0xFF1B5E20);
    case AtlasExecutiveGoalRiskLevel.attention:
      return const Color(0xFFEF6C00);
    case AtlasExecutiveGoalRiskLevel.high:
      return const Color(0xFFC62828);
    case AtlasExecutiveGoalRiskLevel.completed:
      return const Color(0xFF1565C0);
  }
}

String _date(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month =
      value.month.toString().padLeft(2, '0');

  return '$day/$month/${value.year}';
}

String _dateTime(DateTime value) {
  final hour =
      value.hour.toString().padLeft(2, '0');
  final minute =
      value.minute.toString().padLeft(2, '0');

  return '${_date(value)} $hour:$minute';
}
