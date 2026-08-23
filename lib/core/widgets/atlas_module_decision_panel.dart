import 'package:flutter/material.dart';

enum AtlasModuleAttentionLevel { normal, attention, critical }

class AtlasModuleDecisionItem {
  const AtlasModuleDecisionItem({
    required this.title,
    required this.description,
    required this.icon,
    this.level = AtlasModuleAttentionLevel.normal,
  });

  final String title;
  final String description;
  final IconData icon;
  final AtlasModuleAttentionLevel level;
}

class AtlasModuleDecisionPanel extends StatelessWidget {
  const AtlasModuleDecisionPanel({
    required this.statusTitle,
    required this.statusDescription,
    required this.items,
    this.level = AtlasModuleAttentionLevel.normal,
    super.key,
  });

  final String statusTitle;
  final String statusDescription;
  final List<AtlasModuleDecisionItem> items;
  final AtlasModuleAttentionLevel level;

  Color _accent(AtlasModuleAttentionLevel value) {
    return switch (value) {
      AtlasModuleAttentionLevel.normal => const Color(0xFF1B5E20),
      AtlasModuleAttentionLevel.attention => const Color(0xFFB26A00),
      AtlasModuleAttentionLevel.critical => const Color(0xFFB3261E),
    };
  }

  IconData _statusIcon(AtlasModuleAttentionLevel value) {
    return switch (value) {
      AtlasModuleAttentionLevel.normal => Icons.check_circle_outline,
      AtlasModuleAttentionLevel.attention => Icons.warning_amber_outlined,
      AtlasModuleAttentionLevel.critical => Icons.error_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(level);
    final visibleItems = items.isEmpty
        ? const [
            AtlasModuleDecisionItem(
              title: 'Nenhuma prioridade aberta',
              description:
                  'Os dados atuais não indicam ação imediata neste módulo.',
              icon: Icons.check_circle_outline,
            ),
          ]
        : items.take(4).toList(growable: false);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            color: accent.withValues(alpha: 0.08),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: accent.withValues(alpha: 0.12),
                  child: Icon(_statusIcon(level), color: accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Situação do módulo',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusTitle,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusDescription,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 18, 6),
            child: Text(
              'O que precisa de atenção',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          ...visibleItems.map(
            (item) {
              final itemAccent = _accent(item.level);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: itemAccent.withValues(alpha: 0.10),
                  child: Icon(item.icon, color: itemAccent, size: 20),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(item.description),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
