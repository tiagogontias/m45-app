import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../core/routes.dart';
import '../services/pocketbase_service.dart';
import '../services/local_storage_service.dart';
import '../shared/widgets/loading_button.dart';
import '../shared/widgets/error_dialog.dart';

class RegisterScreen extends StatefulWidget {
  final String? codigoIndicacaoPrefill;

  const RegisterScreen({super.key, this.codigoIndicacaoPrefill});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codigoIndicacaoController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.codigoIndicacaoPrefill != null) {
      _codigoIndicacaoController.text = widget.codigoIndicacaoPrefill!;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codigoIndicacaoController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final pb = GetIt.instance<PocketBaseService>();
      final localStorage = GetIt.instance<LocalStorageService>();

      final user = await pb.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nome: _nomeController.text.trim(),
        codigoIndicacao: _codigoIndicacaoController.text.trim().isEmpty
            ? null
            : _codigoIndicacaoController.text.trim(),
      );

      await localStorage.saveUser(user);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta criada com sucesso! Faça login.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      await ErrorDialog.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe seu nome';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe seu e-mail';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(
                          () => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Crie uma senha';
                  }
                  if (value.length < 6) {
                    return 'Mínimo 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirmar senha',
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
                obscureText: true,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Senhas não conferem';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codigoIndicacaoController,
                decoration: const InputDecoration(
                  labelText: 'Código de indicação (opcional)',
                  prefixIcon: Icon(Icons.redeem_outlined),
                  helperText:
                      'Se alguém te indicou, informe o código M45-XXXXX',
                ),
              ),
              const SizedBox(height: 24),
              LoadingButton(
                label: 'Cadastrar',
                isLoading: _isLoading,
                onPressed: _register,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
