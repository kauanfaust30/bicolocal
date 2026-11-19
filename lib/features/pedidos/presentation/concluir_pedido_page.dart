import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../conta/presentation/conta_controller.dart';
import '../domain/pedido.dart';
import '../domain/pedido_permissions.dart';
import 'pedido_card.dart';
import 'pedido_controller.dart';

/// Concluir pedido (FR-001, FR-002). Só o contratante chega aqui (router).
class ConcluirPedidoPage extends StatefulWidget {
  const ConcluirPedidoPage({super.key, required this.pedidoId});

  final String pedidoId;

  @override
  State<ConcluirPedidoPage> createState() => _ConcluirPedidoPageState();
}

class _ConcluirPedidoPageState extends State<ConcluirPedidoPage> {
  late final Future<Pedido?> _pedido;
  bool _recusado = false;

  @override
  void initState() {
    super.initState();
    _pedido = context.read<PedidoController>().buscar(
      pedidoId: widget.pedidoId,
    );
  }

  Future<void> _concluir(Pedido pedido) async {
    final concluido = await context.read<PedidoController>().concluirPedido(
      editor: context.read<ContaController>().conta,
      pedido: pedido,
    );
    if (!mounted) return;
    if (!concluido) {
      setState(() => _recusado = true);
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Pedido concluído.')));
    context.go('/meus-pedidos');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Concluir pedido')),
    body: FutureBuilder<Pedido?>(
      future: _pedido,
      builder: (context, snapshot) {
        final contas = context.watch<ContaController>();
        if (snapshot.connectionState != ConnectionState.done ||
            contas.carregandoSessao) {
          return const Center(child: CircularProgressIndicator());
        }
        final pedido = snapshot.data;
        if (snapshot.hasError || pedido == null) {
          return const Center(
            child: Text('Não foi possível abrir este pedido.'),
          );
        }
        // Só o contratante conclui (FR-001, FR-029); quem mais abrir por
        // link vai ao início.
        if (contas.conta?.uid != pedido.contratanteUid) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/inicio');
          });
          return const SizedBox.shrink();
        }
        if (_recusado ||
            !PedidoPermissions.podeConcluir(
              pedido: pedido,
              uid: contas.conta?.uid,
            )) {
          return const _Recusa();
        }
        final enviando = context.watch<PedidoController>().publicando;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PedidoCard(pedido: pedido),
            const SizedBox(height: 20),
            const Text(
              'Depois de concluído, o pedido não pode mais ser editado nem '
              'cancelado. Você e o prestador poderão se avaliar.',
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              key: const Key('botao-concluir'),
              onPressed: enviando ? null : () => _concluir(pedido),
              icon: const Icon(Icons.task_alt),
              label: const Text('Concluir pedido'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.go('/meus-pedidos'),
              child: const Text('Voltar'),
            ),
          ],
        );
      },
    ),
  );
}

class _Recusa extends StatelessWidget {
  const _Recusa();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Este pedido não pode ser concluído agora.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/inicio'),
            child: const Text('Voltar ao início'),
          ),
        ],
      ),
    ),
  );
}
