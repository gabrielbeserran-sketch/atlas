import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/design_system/atlas_design_system.dart';

class AtlasErrorState extends StatelessWidget {
  const AtlasErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title = 'Não foi possível carregar os dados',
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title. $message',
      child: AtlasStatePanel(
        title: title,
        message: message,
        icon: Icons.cloud_off_outlined,
        tone: AtlasStateTone.critical,
        actionLabel: onRetry == null ? null : 'Tentar novamente',
        onAction: onRetry,
      ),
    );
  }
}
