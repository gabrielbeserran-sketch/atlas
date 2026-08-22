import 'package:flutter/material.dart';

/// Estado de erro reutilizável para módulos operacionais do Atlas.
///
/// Evita telas vazias ou mensagens técnicas sem saída. O usuário sempre recebe
/// uma explicação curta e a ação "Tentar novamente".
class AtlasLoadErrorState extends StatelessWidget {
  const AtlasLoadErrorState({
    required this.message,
    required this.onRetry,
    this.title = 'Não foi possível carregar os dados',
    super.key,
  });

  final String title;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 44,
                semanticLabel: 'Falha ao carregar',
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => onRetry(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
