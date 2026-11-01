import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../domain/perfil.dart';
import 'conta_controller.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _nome = TextEditingController();
  final _cidade = TextEditingController();
  final _bairro = TextEditingController();
  Perfil? _perfil;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    _nome.dispose();
    _cidade.dispose();
    _bairro.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    final controller = context.read<ContaController>();
    await controller.cadastrar(
      email: _email.text,
      senha: _senha.text,
      nome: _nome.text,
      cidade: _cidade.text,
      bairro: _bairro.text,
      perfil: _perfil,
    );
    if (mounted && controller.conta != null && controller.erro == null) {
      context.go('/inicio');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cadastro')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Escolha seu perfil',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Contratante: publique e gerencie seus pedidos.'),
              const Text('Prestador: encontre pedidos locais e candidate-se.'),
              const SizedBox(height: 16),
              _campo('E-mail', _email, 'email'),
              const SizedBox(height: 12),
              _campo('Senha', _senha, 'senha', segredo: true),
              const SizedBox(height: 12),
              _campo('Nome', _nome, 'nome'),
              const SizedBox(height: 12),
              _campo('Cidade', _cidade, 'cidade'),
              const SizedBox(height: 12),
              _campo('Bairro', _bairro, 'bairro'),
              const SizedBox(height: 12),
              Consumer<ContaController>(
                builder: (context, controller, _) =>
                    DropdownButtonFormField<Perfil>(
                      initialValue: _perfil,
                      decoration: InputDecoration(
                        labelText: 'Perfil',
                        errorText: controller.errosCampos['perfil'],
                      ),
                      items: Perfil.values
                          .map(
                            (perfil) => DropdownMenuItem(
                              value: perfil,
                              child: Text(perfil.rotulo),
                            ),
                          )
                          .toList(),
                      onChanged: (perfil) => setState(() => _perfil = perfil),
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
                        child: Text(
                          controller.erro!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: controller.carregando ? null : _cadastrar,
                      child: Text(
                        controller.carregando
                            ? 'Criando conta…'
                            : 'Criar conta',
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/entrar'),
                      child: const Text('Já tenho uma conta'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _campo(
    String label,
    TextEditingController controller,
    String chave, {
    bool segredo = false,
  }) => Consumer<ContaController>(
    builder: (context, estado, _) => TextFormField(
      controller: controller,
      obscureText: segredo,
      keyboardType: chave == 'email' ? TextInputType.emailAddress : null,
      decoration: InputDecoration(
        labelText: label,
        errorText: estado.errosCampos[chave],
      ),
    ),
  );
}
