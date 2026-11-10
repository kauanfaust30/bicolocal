import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/async/async_state.dart';
import '../../../core/widgets/estado_ilustrado.dart';
import '../../conta/domain/perfil.dart';
import '../../conta/presentation/conta_controller.dart';
import '../domain/pedido.dart';
import '../domain/pedido_permissions.dart';
import 'pedido_card.dart';
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
          return const EstadoIlustrado.carregando(
            titulo: 'Carregando seus pedidos…',
          );
        }
        if (estado.status == AsyncStatus.erro) {
          return EstadoIlustrado(
            icone: Icons.cloud_off_outlined,
            erro: true,
            titulo:
                estado.mensagemErro ??
                'Não foi possível carregar seus pedidos.',
            acao: ElevatedButton.icon(
              onPressed: () =>
                  controller.carregarGerenciaveis(contaController.conta),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          );
        }
        final pedidos = estado.data ?? const <Pedido>[];
        if (pedidos.isEmpty) {
          final contratante =
              contaController.conta?.perfil == Perfil.contratante;
          return EstadoIlustrado(
            icone: Icons.inventory_2_outlined,
            titulo: 'Você ainda não tem pedidos.',
            mensagem: contratante
                ? 'Publique um pedido para encontrar ajuda perto de você.'
                : 'Quando uma candidatura sua for aceita, o pedido aparece aqui.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: pedidos.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
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
            return PedidoCard(
              pedido: pedido,
              acoes: [
                if (autor && pedido.estado == EstadoPedido.aberto)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.go('/pedidos/${pedido.id}/candidaturas'),
                      icon: const Icon(Icons.people_outline),
                      label: const Text('Ver candidaturas'),
                    ),
                  ),
                if (podeGerenciar)
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.go('/pedidos/${pedido.id}/gerenciar'),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Gerenciar pedido'),
                  ),
              ],
            );
          },
        );
      },
    ),
  );
}
