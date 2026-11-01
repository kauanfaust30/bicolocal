import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../conta/presentation/conta_controller.dart';
import '../../conta/domain/conta.dart';
import '../../pedidos/domain/pedido.dart';
import '../../pedidos/presentation/pedido_controller.dart';
import 'candidatura_controller.dart';
import '../domain/candidatura.dart';

class RevisarCandidaturasPage extends StatefulWidget {
  const RevisarCandidaturasPage({super.key, required this.pedidoId});

  final String pedidoId;

  @override
  State<RevisarCandidaturasPage> createState() =>
      _RevisarCandidaturasPageState();
}

class _RevisarCandidaturasPageState extends State<RevisarCandidaturasPage> {
  late final Future<Pedido?> _pedido;
  bool _candidaturasCarregadas = false;

  @override
  void initState() {
    super.initState();
    _pedido = context.read<PedidoController>().buscar(
      pedidoId: widget.pedidoId,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Candidaturas')),
    body: FutureBuilder<Pedido?>(
      future: _pedido,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final pedido = snapshot.data;
        final conta = context.read<ContaController>().conta;
        if (pedido == null ||
            conta == null ||
            pedido.contratanteUid != conta.uid) {
          return const Center(
            child: Text('Não foi possível abrir este pedido.'),
          );
        }
        if (!_candidaturasCarregadas) {
          _candidaturasCarregadas = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<CandidaturaController>().carregar(
                pedido: pedido,
                contratante: conta,
              );
            }
          });
        }
        return _conteudo(pedido, conta);
      },
    ),
  );

  Widget _conteudo(Pedido pedido, Conta conta) =>
      Consumer<CandidaturaController>(
        builder: (context, controller, _) {
          if (controller.carregando) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.erro != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(controller.erro!),
                  ElevatedButton(
                    onPressed: () =>
                        controller.carregar(pedido: pedido, contratante: conta),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }
          if (controller.candidaturas.isEmpty) {
            return const Center(
              child: Text('Ainda não há candidaturas para este pedido.'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final candidatura in controller.candidaturas)
                _cartao(pedido, conta, candidatura, controller),
              if (controller.mensagem != null) Text(controller.mensagem!),
              if (controller.emailContato != null)
                SelectableText(
                  'E-mail do prestador: ${controller.emailContato}',
                ),
            ],
          );
        },
      );

  Widget _cartao(
    Pedido pedido,
    Conta conta,
    Candidatura candidatura,
    CandidaturaController controller,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Prestador interessado'),
          if (candidatura.estado == EstadoCandidatura.pendente)
            ElevatedButton(
              onPressed: controller.executando
                  ? null
                  : () => controller.aceitar(
                      pedido: pedido,
                      candidatura: candidatura,
                      contratante: conta,
                    ),
              child: const Text('Aceitar candidatura'),
            )
          else
            Text(
              candidatura.estado == EstadoCandidatura.aceita
                  ? 'Aceita'
                  : 'Recusada',
            ),
        ],
      ),
    ),
  );
}
