import 'dart:async';

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
  AtlasSessionController? _controller;

  Object? _startupError;

  bool _startupScheduled = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => _startSession());
  }

  void _startSession() {
    if (!mounted || _startupScheduled) {
      return;
    }

    _startupScheduled = true;

    Future<void>.delayed(const Duration(milliseconds: 120), () async {
      if (!mounted) {
        return;
      }

      AtlasSessionController controller;

      try {
        controller = AtlasSessionController();
      } catch (error, stackTrace) {
        debugPrint('ATLAS SessionController construction: $error');

        debugPrintStack(stackTrace: stackTrace);

        if (!mounted) {
          return;
        }

        setState(() {
          _startupError = error;
        });

        return;
      }

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
      });

      try {
        await controller.restore().timeout(const Duration(seconds: 30));
      } on TimeoutException catch (error) {
        if (!mounted) {
          return;
        }

        setState(() {
          _startupError = error;
        });
      } catch (error, stackTrace) {
        debugPrint('ATLAS session restore: $error');

        debugPrintStack(stackTrace: stackTrace);

        if (!mounted) {
          return;
        }

        setState(() {
          _startupError = error;
        });
      }
    });
  }

  void _retryStartup() {
    final previous = _controller;

    _controller = null;

    previous?.dispose();

    setState(() {
      _startupError = null;
      _startupScheduled = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _startSession());
  }

  @override
  void dispose() {
    _controller?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startupError = _startupError;

    if (startupError != null) {
      return _StartupFailureScreen(
        message: startupError.toString(),
        onRetry: _retryStartup,
      );
    }

    final controller = _controller;

    if (controller == null) {
      return const _LoadingScreen(message: 'Preparando a sessão...');
    }

    return AtlasSessionScope(
      controller: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          switch (controller.status) {
            case AtlasSessionStatus.restoring:
              return const _LoadingScreen(message: 'Restaurando sua sessão...');

            case AtlasSessionStatus.loadingContext:
              return const _LoadingScreen(message: 'Carregando sua fazenda...');

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
  const _LoadingScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF123F2D),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFF123F2D),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartupFailureScreen extends StatelessWidget {
  const _StartupFailureScreen({required this.message, required this.onRetry});

  final String message;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 54,
                  color: Color(0xFF123F2D),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Não foi possível concluir a inicialização',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
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
}
