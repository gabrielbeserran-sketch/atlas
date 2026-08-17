import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/navigation/atlas_home_shell.dart';
import 'package:projeto_atlas/core/session/atlas_session_controller.dart';
import 'package:projeto_atlas/core/session/atlas_session_scope.dart';
import 'package:projeto_atlas/features/authentication/presentation/screens/company_selection_screen.dart';
import 'package:projeto_atlas/features/authentication/presentation/screens/login_screen.dart';

class AtlasSessionGate extends StatefulWidget {
  const AtlasSessionGate({super.key});

  @override
  State<AtlasSessionGate> createState() => _AtlasSessionGateState();
}

class _AtlasSessionGateState extends State<AtlasSessionGate> {
  late final AtlasSessionController controller;

  @override
  void initState() {
    super.initState();
    controller = AtlasSessionController();
    controller.restore();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AtlasSessionScope(
      controller: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          switch (controller.status) {
            case AtlasSessionStatus.restoring:
            case AtlasSessionStatus.loadingContext:
              return const _LoadingScreen();
            case AtlasSessionStatus.unauthenticated:
              return LoginScreen(onAuthenticated: controller.acceptSession);
            case AtlasSessionStatus.selectingCompany:
              return CompanySelectionScreen(
                session: controller.session!,
                onSelected: controller.acceptSession,
              );
            case AtlasSessionStatus.failure:
              return _FailureScreen(
                message: controller.error ?? 'Falha ao carregar o contexto.',
                onRetry: controller.loadContext,
                onLogout: controller.logout,
              );
            case AtlasSessionStatus.authenticated:
              return const AtlasHomeShell();
          }
        },
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Preparando o Atlas...'),
        ],
      ),
    ),
  );
}

class _FailureScreen extends StatelessWidget {
  const _FailureScreen({
    required this.message,
    required this.onRetry,
    required this.onLogout,
  });
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onLogout;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 56),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
              TextButton(
                onPressed: onLogout,
                child: const Text('Sair da conta'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
