import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/design_system/atlas_design_system.dart';

class AtlasEmptyState extends StatelessWidget {
  const AtlasEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AtlasStatePanel(
      title: title,
      message: message,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
