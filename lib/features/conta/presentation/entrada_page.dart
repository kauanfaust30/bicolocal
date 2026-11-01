import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'conta_controller.dart';

class EntradaPage extends StatefulWidget {
  const EntradaPage({super.key});

  @override
  State<EntradaPage> createState() => _EntradaPageState();
}

class _EntradaPageState extends State<EntradaPage> {
  final _email = TextEditingController();
  final _senha = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final controller = context.read<ContaController>();
    await controller.entrar(email: _email.text, senha: _senha.text);
    if (mounted && controller.conta != null && controller.erro == null) {
      context.go('/inicio');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Entrar')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Consumer<ContaController>(
            builder: (context, controller, _) => TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'E-mail',
                errorText: controller.errosCampos['email'],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Consumer<ContaController>(
            builder: (context, controller, _) => TextField(
              controller: _senha,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Senha',
                errorText: controller.errosCampos['senha'],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Consumer<ContaController>(
            builder: (context, controller, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (controller.erro != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(controller.erro!),
                  ),
                ElevatedButton(
                  onPressed: controller.carregando ? null : _entrar,
                  child: const Text('Entrar'),
                ),
                TextButton(
                  onPressed: () => context.go('/cadastro'),
                  child: const Text('Criar conta'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
