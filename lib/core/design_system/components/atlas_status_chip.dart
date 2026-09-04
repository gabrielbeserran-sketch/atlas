import 'package:flutter/material.dart';

import '../foundations/atlas_colors.dart';
import '../foundations/atlas_radius.dart';

class AtlasStatusChip extends StatelessWidget {
  const AtlasStatusChip({
    super.key,
    required this.label,
    this.tone = AtlasStatusTone.neutral,
    this.icon,
  });

  final String label;
  final AtlasStatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = _colors(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(AtlasRadius.pill),
        border: Border.all(color: colors.$2.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: colors.$2),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: colors.$2,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _colors(AtlasStatusTone tone) => switch (tone) {
        AtlasStatusTone.success => (AtlasColors.successSoft, AtlasColors.success),
        AtlasStatusTone.warning => (AtlasColors.warningSoft, AtlasColors.warning),
        AtlasStatusTone.critical => (AtlasColors.criticalSoft, AtlasColors.critical),
        AtlasStatusTone.info => (AtlasColors.infoSoft, AtlasColors.info),
        AtlasStatusTone.neutral => (AtlasColors.surfaceMuted, AtlasColors.textSecondary),
      };
}

enum AtlasStatusTone { neutral, success, warning, critical, info }
