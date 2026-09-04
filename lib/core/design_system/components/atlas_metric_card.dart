import 'package:flutter/material.dart';

import '../foundations/atlas_colors.dart';
import '../foundations/atlas_spacing.dart';
import 'atlas_surface.dart';
import 'atlas_status_chip.dart';

class AtlasMetricCard extends StatelessWidget {
  const AtlasMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.supportingText,
    this.icon,
    this.statusLabel,
    this.statusTone = AtlasStatusTone.neutral,
  });

  final String label;
  final String value;
  final String? supportingText;
  final IconData? icon;
  final String? statusLabel;
  final AtlasStatusTone statusTone;

  @override
  Widget build(BuildContext context) {
    return AtlasSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AtlasColors.brand, size: 20),
                const SizedBox(width: AtlasSpacing.sm),
              ],
              Expanded(
                child: Text(label, style: Theme.of(context).textTheme.labelLarge),
              ),
              if (statusLabel != null)
                AtlasStatusChip(label: statusLabel!, tone: statusTone),
            ],
          ),
          const SizedBox(height: AtlasSpacing.md),
          Text(value, style: Theme.of(context).textTheme.headlineLarge),
          if (supportingText != null) ...[
            const SizedBox(height: AtlasSpacing.xs),
            Text(supportingText!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
