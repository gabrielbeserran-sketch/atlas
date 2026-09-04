import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/branding/atlas_branding.dart';
import 'package:projeto_atlas/core/design_system/atlas_design_system.dart';
import 'package:projeto_atlas/features/authentication/presentation/screens/company_selection_screen.dart';
import 'package:projeto_atlas/features/authentication/presentation/screens/password_recovery_screen.dart';
import 'package:projeto_atlas/features/authentication/presentation/screens/register_screen.dart';
import 'package:projeto_atlas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/models/atlas_enterprise_remote_session.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({this.onAuthenticated, super.key});

  final Future<void> Function(AtlasRemoteSession session)? onAuthenticated;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
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
      final session = await AtlasEnterpriseApiClient.instance.me();
      if (!mounted) return;
      await _openNext(session);
    } catch (_) {
      // Sessão ausente/expirada mantém o usuário na entrada segura.
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
      var session = await AtlasEnterpriseApiClient.instance.login(
        email: email,
        password: password,
      );

      if (session.mfaRequired) {
        final code = await _requestMfaCode();
        if (code == null || code.trim().isEmpty) return;

        session = await AtlasEnterpriseApiClient.instance.completeMfa(
          challengeToken: session.challengeToken,
          code: code,
        );
      }

      if (!mounted) return;
      await _openNext(session);
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<void> _openNext(AtlasRemoteSession session) async {
    if (widget.onAuthenticated != null) {
      await widget.onAuthenticated!(session);
      return;
    }

    if (session.companies.length > 1 && session.companyId.isEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => CompanySelectionScreen(session: session),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtlasColors.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AtlasSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: wide
                      ? Row(
                          // A Row dentro de SingleChildScrollView recebe altura
                          // ilimitada. "stretch" tenta forçar essa altura nos
                          // filhos e resulta em BoxConstraints infinitas.
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(child: _AtlasLoginStory()),
                            const SizedBox(width: AtlasSpacing.xxl),
                            SizedBox(
                              width: 430,
                              child: _AtlasLoginForm(
                                emailController: emailController,
                                passwordController: passwordController,
                                obscurePassword: obscurePassword,
                                isLoading: isLoading,
                                onTogglePassword: () => setState(
                                  () => obscurePassword = !obscurePassword,
                                ),
                                onLogin: login,
                                onForgotPassword: _openPasswordRecovery,
                                onRegister: _openRegister,
                              ),
                            ),
                          ],
                        )
                      : ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Column(
                            children: [
                              const _AtlasCompactBrand(),
                              const SizedBox(height: AtlasSpacing.xl),
                              _AtlasLoginForm(
                                emailController: emailController,
                                passwordController: passwordController,
                                obscurePassword: obscurePassword,
                                isLoading: isLoading,
                                onTogglePassword: () => setState(
                                  () => obscurePassword = !obscurePassword,
                                ),
                                onLogin: login,
                                onForgotPassword: _openPasswordRecovery,
                                onRegister: _openRegister,
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openPasswordRecovery() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const PasswordRecoveryScreen(),
      ),
    );
  }

  void _openRegister() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }
}

class _AtlasLoginStory extends StatelessWidget {
  const _AtlasLoginStory();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 620),
      padding: const EdgeInsets.all(AtlasSpacing.xxl),
      decoration: BoxDecoration(
        color: AtlasColors.brandStrong,
        borderRadius: BorderRadius.circular(AtlasRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BeserraLogo(height: 118),
          // Este painel também pode viver dentro de uma rolagem vertical.
          // Spacer exige altura finita; um espaçamento explícito preserva a
          // composição sem introduzir constraints infinitas no desktop.
          const SizedBox(height: 88),
          Text(
            'Decisões melhores começam com uma fazenda bem compreendida.',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AtlasColors.textInverse,
                  fontWeight: FontWeight.w700,
                  height: 1.08,
                ),
          ),
          const SizedBox(height: AtlasSpacing.lg),
          Text(
            'O Atlas reúne operação, rebanho, gestão e consultoria em um único '
            'ambiente para transformar dados do campo em decisões práticas.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AtlasColors.textInverse.withValues(alpha: 0.78),
                  height: 1.55,
                ),
          ),
          const SizedBox(height: AtlasSpacing.xl),
          const Wrap(
            spacing: AtlasSpacing.sm,
            runSpacing: AtlasSpacing.sm,
            children: [
              _TrustChip(icon: Icons.verified_user_outlined, label: 'Acesso seguro'),
              _TrustChip(icon: Icons.home_work_outlined, label: 'Contexto por fazenda'),
              _TrustChip(icon: Icons.insights_outlined, label: 'Decisão orientada por dados'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AtlasCompactBrand extends StatelessWidget {
  const _AtlasCompactBrand();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        BeserraLogo(height: 118),
        SizedBox(height: AtlasSpacing.md),
        Text(
          'ATLAS',
          style: TextStyle(
            color: AtlasColors.brandStrong,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.2,
          ),
        ),
        SizedBox(height: AtlasSpacing.xs),
        Text(
          'Gestão pecuária e consultoria em um só lugar',
          textAlign: TextAlign.center,
          style: TextStyle(color: AtlasColors.textSecondary),
        ),
      ],
    );
  }
}

class _AtlasLoginForm extends StatelessWidget {
  const _AtlasLoginForm({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onForgotPassword,
    required this.onRegister,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return AtlasSurface(
      elevated: true,
      padding: const EdgeInsets.all(AtlasSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bem-vindo ao Atlas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AtlasColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AtlasSpacing.xs),
          const Text(
            'Entre para continuar na fazenda e nos módulos autorizados para sua conta.',
            style: TextStyle(
              color: AtlasColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AtlasSpacing.xl),
          TextField(
            controller: emailController,
            enabled: !isLoading,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: AtlasSpacing.md),
          TextField(
            controller: passwordController,
            enabled: !isLoading,
            obscureText: obscurePassword,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => onLogin(),
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                onPressed: isLoading ? null : onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: AtlasSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading ? null : onForgotPassword,
              child: const Text('Esqueci minha senha'),
            ),
          ),
          const SizedBox(height: AtlasSpacing.md),
          AtlasButton(
            label: 'Entrar',
            icon: Icons.arrow_forward_rounded,
            onPressed: isLoading ? null : onLogin,
            busy: isLoading,
            expand: true,
          ),
          const SizedBox(height: AtlasSpacing.sm),
          AtlasButton(
            label: 'Criar uma conta',
            onPressed: isLoading ? null : onRegister,
            variant: AtlasButtonVariant.secondary,
            expand: true,
          ),
          const SizedBox(height: AtlasSpacing.xl),
          const Divider(),
          const SizedBox(height: AtlasSpacing.md),
          const Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 18,
                color: AtlasColors.textTertiary,
              ),
              SizedBox(width: AtlasSpacing.xs),
              Expanded(
                child: Text(
                  'Seu acesso respeita empresa, fazenda e permissões da sessão.',
                  style: TextStyle(
                    color: AtlasColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AtlasSpacing.sm,
        vertical: AtlasSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AtlasColors.textInverse.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AtlasRadius.pill),
        border: Border.all(
          color: AtlasColors.textInverse.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AtlasColors.textInverse),
          const SizedBox(width: AtlasSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              color: AtlasColors.textInverse,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
