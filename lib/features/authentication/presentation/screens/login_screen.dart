import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/authentication/presentation/screens/company_selection_screen.dart';
import 'package:projeto_atlas/features/authentication/presentation/screens/password_recovery_screen.dart';
import 'package:projeto_atlas/features/authentication/presentation/screens/register_screen.dart';
import 'package:projeto_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/models/atlas_enterprise_remote_session.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _restoreSession() async {
    try {
      final session =
          await AtlasEnterpriseApiClient.instance.me();

      if (!mounted) return;

      _openNext(session);
    } catch (_) {
      // Mantém a tela de login quando a sessão não pode ser restaurada.
    }
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _message('Preencha o e-mail e a senha.');
      return;
    }

    setState(() => isLoading = true);

    try {
      var session =
          await AtlasEnterpriseApiClient.instance.login(
        email: email,
        password: password,
      );

      if (session.mfaRequired) {
        final code = await _requestMfaCode();

        if (code == null || code.trim().isEmpty) return;

        session =
            await AtlasEnterpriseApiClient.instance.completeMfa(
          challengeToken: session.challengeToken,
          code: code,
        );
      }

      if (!mounted) return;

      _openNext(session);
    } on AtlasEnterpriseApiException catch (error) {
      if (!mounted) return;
      _message(error.message);
    } catch (_) {
      if (!mounted) return;
      _message(
        'Não foi possível conectar ao backend Atlas. '
        'Confirme o servidor, o PostgreSQL e a URL da API.',
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<String?> _requestMfaCode() {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Verificação em duas etapas'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Código do autenticador',
            prefixIcon: Icon(Icons.phonelink_lock_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _openNext(AtlasRemoteSession session) {
    if (session.companies.length > 1 &&
        session.companyId.isEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => CompanySelectionScreen(
            session: session,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const DashboardScreen(),
      ),
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.agriculture_outlined,
                    size: 76,
                    color: Color(0xFF1B5E20),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'PROJETO ATLAS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Dados que guiam. Resultados que permanecem.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextField(
                    controller: emailController,
                    enabled: !isLoading,
                    keyboardType:
                        TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon:
                          Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    enabled: !isLoading,
                    obscureText: obscurePassword,
                    onSubmitted: (_) => login(),
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon:
                          const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: isLoading
                            ? null
                            : () => setState(
                                  () => obscurePassword =
                                      !obscurePassword,
                                ),
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const PasswordRecoveryScreen(),
                                ),
                              ),
                      child:
                          const Text('Esqueci minha senha'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed:
                          isLoading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Entrar',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const RegisterScreen(),
                                ),
                              ),
                      child: const Text('Criar uma conta'),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Beserra Consultoria Veterinária',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black45),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
