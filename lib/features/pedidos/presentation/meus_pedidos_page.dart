import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/async/async_state.dart';
import '../../conta/presentation/conta_controller.dart';
import '../domain/pedido.dart';
import '../domain/pedido_permissions.dart';
import 'pedido_controller.dart';

class MeusPedidosPage extends StatefulWidget {
  const MeusPedidosPage({super.key});

  @override
  State<MeusPedidosPage> createState() => _MeusPedidosPageState();
}

class _MeusPedidosPageState extends State<MeusPedidosPage> {
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final conta = context.watch<ContaController>().conta;
    if (!_iniciado && conta != null) {
      _iniciado = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<PedidoController>().carregarGerenciaveis(conta);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Meus pedidos')),
    body: Consumer2<PedidoController, ContaController>(
      builder: (context, controller, contaController, _) {
        final estado = controller.estadoGerenciaveis;
        if (estado.status == AsyncStatus.inicial ||
            estado.status == AsyncStatus.carregando) {
          return const Center(child: CircularProgressIndicator());
        }
        if (estado.status == AsyncStatus.erro) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  estado.mensagemErro ??
                      'Não foi possível carregar seus pedidos.',
                ),
                ElevatedButton(
                  onPressed: () =>
                      controller.carregarGerenciaveis(contaController.conta),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }
        final pedidos = estado.data ?? const <Pedido>[];
        if (pedidos.isEmpty) {
          return const Center(
            child: Text('Você ainda não tem pedidos relacionados.'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: pedidos.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final pedido = pedidos[index];
            final conta = contaController.conta;
            final autor = conta?.uid == pedido.contratanteUid;
            final podeGerenciar =
                conta != null &&
                PedidoPermissions.podeEditarOuCancelar(
                  pedido: pedido,
                  uid: conta.uid,
                  agoraUtc: DateTime.now().toUtc(),
                );
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pedido.titulo,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(_rotuloEstado(pedido.estado)),
                    if (autor && pedido.estado == EstadoPedido.aberto) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () =>
                            context.go('/pedidos/${pedido.id}/candidaturas'),
                        child: const Text('Ver candidaturas'),
                      ),
                    ],
                    if (podeGerenciar) ...[
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () =>
                            context.go('/pedidos/${pedido.id}/gerenciar'),
                        child: const Text('Gerenciar pedido'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  );

  String _rotuloEstado(EstadoPedido estado) => switch (estado) {
    EstadoPedido.aberto => 'Aberto',
    EstadoPedido.emAndamento => 'Em andamento',
    EstadoPedido.cancelado => 'Cancelado',
  };
}
