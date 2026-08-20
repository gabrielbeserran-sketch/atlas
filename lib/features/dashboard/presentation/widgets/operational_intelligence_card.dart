import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/dashboard/domain/models/atlas_operational_intelligence_data.dart';

class OperationalIntelligenceCard extends StatelessWidget {
  const OperationalIntelligenceCard({
    required this.data,
    required this.farmName,
    required this.onRefresh,
    required this.onOpenArea,
    required this.onOpenAlerts,
    this.warning,
    super.key,
  });

  final AtlasOperationalIntelligenceData? data;
  final String farmName;
  final VoidCallback onRefresh;
  final ValueChanged<String> onOpenArea;
  final VoidCallback onOpenAlerts;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    final value = data;
    if (value == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.psychology_alt_outlined, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inteligência operacional',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      warning ?? 'Selecione uma fazenda para calcular o score operacional.',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Atualizar',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      );
    }

    final scoreColor = _scoreColor(value.operationalScore);
    final actions = value.topActions.take(3).toList(growable: false);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scoreColor, scoreColor.withValues(alpha: 0.78)],
              ),
            ),
            child: Wrap(
              spacing: 24,
              runSpacing: 18,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: value.operationalScore.clamp(0, 100) / 100,
                        strokeWidth: 9,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      Center(
                        child: Text(
                          '${value.operationalScore}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 29,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 330,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Score operacional Atlas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        farmName,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _levelLabel(value.operationalLevel),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _HeaderMetric(
                  label: 'Alertas',
                  value: '${value.alertTotal}',
                  icon: Icons.notifications_active_outlined,
                ),
                _HeaderMetric(
                  label: 'Críticos/altos',
                  value: '${value.criticalAlerts + value.highAlerts}',
                  icon: Icons.priority_high_rounded,
                ),
                IconButton(
                  tooltip: 'Atualizar inteligência',
                  onPressed: onRefresh,
                  color: Colors.white,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Prioridades recomendadas',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onOpenAlerts,
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: const Text('Ver todos os alertas'),
                    ),
                    if (warning != null)
                      Tooltip(
                        message: warning!,
                        child: const Icon(Icons.info_outline, color: Colors.orange),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (actions.isEmpty)
                  const _AllGoodState()
                else
                  ...actions.map(
                    (action) => _ActionTile(
                      action: action,
                      onTap: () => onOpenArea(action.area),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _scoreColor(int score) {
    if (score >= 85) return const Color(0xFF1B5E20);
    if (score >= 70) return const Color(0xFF2E7D32);
    if (score >= 50) return const Color(0xFFEF6C00);
    return const Color(0xFFC62828);
  }

  static String _levelLabel(String level) {
    return switch (level.toLowerCase()) {
      'excellent' => 'Operação excelente',
      'good' => 'Operação saudável',
      'attention' => 'Operação exige atenção',
      'critical' => 'Intervenção prioritária',
      _ => 'Situação operacional calculada em tempo real',
    };
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action, required this.onTap});
  final AtlasOperationalActionData action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _severityColor(action.severity).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _severityColor(action.severity).withValues(alpha: 0.23)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _severityColor(action.severity),
                foregroundColor: Colors.white,
                child: Text('${action.position}'),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${action.area} · ${action.title}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (action.recommendedAction.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(action.recommendedAction, style: const TextStyle(color: Colors.black54)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('${action.priorityScore}', style: TextStyle(color: _severityColor(action.severity), fontWeight: FontWeight.w900)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  static Color _severityColor(String value) {
    return switch (value.toLowerCase()) {
      'critical' => const Color(0xFFC62828),
      'high' => const Color(0xFFEF6C00),
      'medium' => const Color(0xFFF9A825),
      _ => const Color(0xFF2E7D32),
    };
  }
}

class _AllGoodState extends StatelessWidget {
  const _AllGoodState();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF1B5E20)),
          SizedBox(width: 10),
          Expanded(child: Text('Nenhuma ação prioritária foi identificada neste momento.')),
        ],
      ),
    );
  }
}
