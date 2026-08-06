import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final company = TextEditingController();
  final document = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  bool loading = false;
  bool acceptTerms = false;
  bool obscure = true;

  @override
  void dispose() {
    for (final controller in [
      name,
      email,
      company,
      document,
      password,
      confirmPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    if (!acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aceite os termos para continuar.'),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final result =
          await AtlasEnterpriseApiClient.instance.register(
        name: name.text,
        email: email.text,
        password: password.text,
        companyName: company.text,
        companyDocument: document.text,
      );

      if (!mounted) return;

      final developmentToken =
          result['verification_token']?.toString();

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Conta criada'),
          content: Text(
            developmentToken == null ||
                    developmentToken.isEmpty
                ? 'Verifique seu e-mail para confirmar a conta.'
                : 'Conta criada. Em desenvolvimento, use este token para confirmar:\n\n$developmentToken',
          ),
          actions: [
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );

      if (mounted) Navigator.pop(context);
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
      appBar: AppBar(title: const Text('Criar conta Atlas')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (requiredValidator(value) != null) {
                      return 'Informe o e-mail.';
                    }
                    if (!value!.contains('@')) {
                      return 'Informe um e-mail válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: company,
                  decoration: const InputDecoration(
                    labelText: 'Empresa ou propriedade',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  validator: requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: document,
                  decoration: const InputDecoration(
                    labelText: 'CPF ou CNPJ (opcional)',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: password,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    helperText:
                        '10+ caracteres, maiúscula, minúscula, número e símbolo.',
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => obscure = !obscure),
                      icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    final text = value ?? '';
                    if (text.length < 10) {
                      return 'A senha deve ter no mínimo 10 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPassword,
                  obscureText: obscure,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar senha',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) =>
                      value != password.text
                          ? 'As senhas não coincidem.'
                          : null,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: acceptTerms,
                  onChanged: loading
                      ? null
                      : (value) => setState(
                            () => acceptTerms = value ?? false,
                          ),
                  title: const Text(
                    'Li e aceito os termos de uso e a política de privacidade.',
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: loading ? null : submit,
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.person_add_outlined),
                  label: const Text('Criar conta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? requiredValidator(String? value) =>
      value == null || value.trim().isEmpty
          ? 'Campo obrigatório.'
          : null;
}
