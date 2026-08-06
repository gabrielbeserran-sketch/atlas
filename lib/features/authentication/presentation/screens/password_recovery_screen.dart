import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() =>
      _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState
    extends State<PasswordRecoveryScreen> {
  final email = TextEditingController();
  final token = TextEditingController();
  final password = TextEditingController();

  bool loading = false;
  bool requested = false;

  @override
  void dispose() {
    email.dispose();
    token.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> requestToken() async {
    if (email.text.trim().isEmpty) return;

    setState(() => loading = true);

    try {
      await AtlasEnterpriseApiClient.instance
          .requestPasswordReset(email.text);

      if (!mounted) return;

      setState(() => requested = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Caso o e-mail exista, as instruções foram enviadas.',
          ),
        ),
      );
    } on AtlasEnterpriseApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> redefine() async {
    if (token.text.trim().isEmpty ||
        password.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Informe o token e uma senha com pelo menos 10 caracteres.',
          ),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await AtlasEnterpriseApiClient.instance
          .confirmPasswordReset(
        token: token.text,
        newPassword: password.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senha alterada com sucesso.'),
        ),
      );

      Navigator.pop(context);
    } on AtlasEnterpriseApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                controller: email,
                enabled: !requested && !loading,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed:
                    loading || requested ? null : requestToken,
                child: const Text('Solicitar redefinição'),
              ),
              if (requested) ...[
                const SizedBox(height: 28),
                TextField(
                  controller: token,
                  decoration: const InputDecoration(
                    labelText: 'Token recebido',
                    prefixIcon: Icon(Icons.key_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nova senha',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: loading ? null : redefine,
                  child: const Text('Redefinir senha'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
