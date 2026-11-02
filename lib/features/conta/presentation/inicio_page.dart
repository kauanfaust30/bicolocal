import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../domain/perfil.dart';
import 'conta_controller.dart';

class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('BicoLocal'),
      actions: [
        Consumer<ContaController>(
          builder: (context, controller, _) => TextButton.icon(
            onPressed: controller.carregando ? null : controller.sair,
            icon: const Icon(Icons.logout),
            label: const Text('Sair'),
          ),
        ),
      ],
    ),
    body: Consumer<ContaController>(
      builder: (context, controller, _) {
        final conta = controller.conta;
        if (conta == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Entre na sua conta para continuar.'),
                TextButton(
                  onPressed: () => context.go('/entrar'),
                  child: const Text('Entrar'),
                ),
              ],
            ),
          );
        }
        final contratante = conta.perfil == Perfil.contratante;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Olá, ${conta.nome}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Perfil ativo: ${conta.perfil.rotulo}'),
            const SizedBox(height: 16),
            Text(
              contratante
                  ? 'Publique e gerencie seus próprios pedidos.'
                  : 'Consulte pedidos locais e candidate-se.',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.go(contratante ? '/pedidos/novo' : '/pedidos'),
              child: Text(
                contratante ? 'Publicar pedido' : 'Ver pedidos da minha cidade',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.go('/meus-pedidos'),
              child: const Text('Meus pedidos'),
            ),
            if (controller.erro != null) ...[
              const SizedBox(height: 12),
              Text(controller.erro!),
            ],
          ],
        );
      },
    ),
  );
}
