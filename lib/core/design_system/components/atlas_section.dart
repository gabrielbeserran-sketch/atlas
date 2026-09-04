import 'package:flutter/material.dart';

import '../foundations/atlas_spacing.dart';

class AtlasSection extends StatelessWidget {
  const AtlasSection({
    super.key,
    required this.title,
    required this.child,
    this.description,
    this.trailing,
  });

  final String title;
  final String? description;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  if (description != null) ...[
                    const SizedBox(height: AtlasSpacing.xs),
                    Text(description!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AtlasSpacing.md),
              trailing!,
            ],
          ],
        ),
        const SizedBox(height: AtlasSpacing.md),
        child,
      ],
    );
  }
}
