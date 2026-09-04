import 'package:flutter/material.dart';

import '../foundations/atlas_colors.dart';
import '../foundations/atlas_spacing.dart';
import 'atlas_button.dart';
import 'atlas_surface.dart';

class AtlasStatePanel extends StatelessWidget {
  const AtlasStatePanel({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.tone = AtlasStateTone.neutral,
    this.loading = false,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final AtlasStateTone tone;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      AtlasStateTone.neutral => AtlasColors.brand,
      AtlasStateTone.info => AtlasColors.info,
      AtlasStateTone.warning => AtlasColors.warning,
      AtlasStateTone.critical => AtlasColors.critical,
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: AtlasSurface(
          padding: const EdgeInsets.all(AtlasSpacing.xl),
          elevated: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              else
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: color, size: 26),
                ),
              const SizedBox(height: AtlasSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AtlasSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AtlasSpacing.lg),
                AtlasButton(
                  label: actionLabel!,
                  onPressed: onAction,
                ),
              ],
              if (secondaryActionLabel != null &&
                  onSecondaryAction != null) ...[
                const SizedBox(height: AtlasSpacing.xs),
                AtlasButton(
                  label: secondaryActionLabel!,
                  onPressed: onSecondaryAction,
                  variant: AtlasButtonVariant.ghost,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum AtlasStateTone { neutral, info, warning, critical }
