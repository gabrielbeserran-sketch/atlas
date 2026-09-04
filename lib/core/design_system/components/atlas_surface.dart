import 'package:flutter/material.dart';

import '../foundations/atlas_colors.dart';
import '../foundations/atlas_elevation.dart';
import '../foundations/atlas_radius.dart';
import '../foundations/atlas_spacing.dart';

class AtlasSurface extends StatelessWidget {
  const AtlasSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AtlasSpacing.cardPadding),
    this.elevated = false,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool elevated;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? AtlasColors.surface,
        borderRadius: BorderRadius.circular(AtlasRadius.md),
        border: Border.all(color: AtlasColors.border),
        boxShadow: elevated ? AtlasElevation.soft : const [],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
