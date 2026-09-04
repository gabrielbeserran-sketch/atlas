import 'package:flutter/material.dart';

import '../foundations/atlas_colors.dart';
import '../foundations/atlas_spacing.dart';

class AtlasPageHeader extends StatelessWidget {
  const AtlasPageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.description,
    this.leading,
    this.actions = const <Widget>[],
  });

  final String title;
  final String? eyebrow;
  final String? description;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;

        final identity = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AtlasSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (eyebrow != null && eyebrow!.trim().isNotEmpty) ...[
                    Text(
                      eyebrow!.toUpperCase(),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AtlasColors.accent,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: AtlasSpacing.xs),
                  ],
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  if (description != null &&
                      description!.trim().isNotEmpty) ...[
                    const SizedBox(height: AtlasSpacing.xs),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Text(
                        description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );

        if (compact || actions.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              identity,
              if (actions.isNotEmpty) ...[
                const SizedBox(height: AtlasSpacing.md),
                Wrap(
                  spacing: AtlasSpacing.sm,
                  runSpacing: AtlasSpacing.sm,
                  children: actions,
                ),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: identity),
            const SizedBox(width: AtlasSpacing.lg),
            Wrap(
              spacing: AtlasSpacing.sm,
              runSpacing: AtlasSpacing.sm,
              alignment: WrapAlignment.end,
              children: actions,
            ),
          ],
        );
      },
    );
  }
}
