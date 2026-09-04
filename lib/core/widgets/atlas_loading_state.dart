import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/design_system/atlas_design_system.dart';

class AtlasLoadingState extends StatelessWidget {
  const AtlasLoadingState({super.key, this.message = 'Carregando dados...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AtlasStatePanel(
      title: 'Preparando informações',
      message: message,
      icon: Icons.hourglass_top_rounded,
      loading: true,
    );
  }
}
