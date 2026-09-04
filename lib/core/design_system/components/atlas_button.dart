import 'package:flutter/material.dart';

import '../foundations/atlas_colors.dart';
import '../foundations/atlas_radius.dart';

class AtlasButton extends StatelessWidget {
  const AtlasButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AtlasButtonVariant.primary,
    this.busy = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AtlasButtonVariant variant;
  final bool busy;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy) ...[
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 10),
        ],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    final callback = busy ? null : onPressed;
    final button = switch (variant) {
      AtlasButtonVariant.primary =>
        FilledButton(onPressed: callback, child: child),
      AtlasButtonVariant.secondary =>
        OutlinedButton(onPressed: callback, child: child),
      AtlasButtonVariant.ghost =>
        TextButton(onPressed: callback, child: child),
      AtlasButtonVariant.danger => FilledButton(
          onPressed: callback,
          style: FilledButton.styleFrom(
            backgroundColor: AtlasColors.critical,
            foregroundColor: AtlasColors.textInverse,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AtlasRadius.sm),
            ),
          ),
          child: child,
        ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

enum AtlasButtonVariant { primary, secondary, ghost, danger }
