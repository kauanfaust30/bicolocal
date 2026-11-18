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
        const SizedBox(width: 8),
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
            Align(
              alignment: Alignment.centerLeft,
              child: _SeloPerfil(perfil: conta.perfil),
            ),
            const SizedBox(height: 12),
            Text(
              contratante
                  ? 'Publique e gerencie seus próprios pedidos.'
                  : 'Consulte pedidos locais e candidate-se.',
            ),
            const SizedBox(height: 24),
            if (contratante)
              const _OpcaoInicio(
                icone: Icons.add_circle_outline,
                titulo: 'Publicar pedido',
                descricao: 'Descreva o serviço e encontre ajuda perto de você.',
                destino: '/pedidos/novo',
              )
            else
              const _OpcaoInicio(
                icone: Icons.travel_explore,
                titulo: 'Ver pedidos da minha cidade',
                descricao:
                    'Encontre bicos abertos na sua região e candidate-se.',
                destino: '/pedidos',
              ),
            const SizedBox(height: 12),
            _OpcaoInicio(
              icone: Icons.assignment_outlined,
              titulo: 'Meus pedidos',
              descricao: contratante
                  ? 'Acompanhe candidaturas, edite ou cancele seus pedidos.'
                  : 'Veja os pedidos em que você foi escolhido.',
              destino: '/meus-pedidos',
              secundaria: true,
            ),
            const SizedBox(height: 12),
            const _OpcaoInicio(
              icone: Icons.account_circle_outlined,
              titulo: 'Meu perfil',
              descricao: 'Veja sua foto e seus dados públicos.',
              destino: '/perfil',
              secundaria: true,
            ),
            if (controller.erro != null) ...[
              const SizedBox(height: 12),
              Text(
                controller.erro!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        );
      },
    ),
  );
}

class _SeloPerfil extends StatelessWidget {
  const _SeloPerfil({required this.perfil});

  final Perfil perfil;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final contratante = perfil == Perfil.contratante;
    return Semantics(
      label: 'Perfil: ${perfil.rotulo}',
      excludeSemantics: true,
      child: Chip(
        key: const Key('selo-perfil'),
        avatar: Icon(
          contratante ? Icons.home_outlined : Icons.handyman_outlined,
          color: cores.onSecondaryContainer,
        ),
        label: Text(perfil.rotulo),
        backgroundColor: cores.secondaryContainer,
        labelStyle: TextStyle(color: cores.onSecondaryContainer),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
    );
  }
}

class _OpcaoInicio extends StatelessWidget {
  const _OpcaoInicio({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.destino,
    this.secundaria = false,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final String destino;
  final bool secundaria;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go(destino),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: secundaria
                      ? cores.secondaryContainer
                      : cores.primary,
                  child: Icon(
                    icone,
                    size: 28,
                    color: secundaria
                        ? cores.onSecondaryContainer
                        : cores.onPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(descricao),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: cores.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
