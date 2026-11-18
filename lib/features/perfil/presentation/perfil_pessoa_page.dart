import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../avaliacoes/domain/avaliacao_repository.dart';
import '../../candidaturas/domain/candidatura_repository.dart';
import '../../conta/domain/conta.dart';
import '../../conta/presentation/conta_controller.dart';
import '../../pedidos/domain/pedido.dart';
import '../../pedidos/presentation/pedido_controller.dart';
import '../domain/perfil_repository.dart';
import 'perfil_controller.dart';
import 'reputacao_perfil.dart';

/// Perfil de outra pessoa, aberto a partir de um pedido (FR-013 a FR-015).
/// Sem "Trocar foto"; a foto só aparece quando o FR-020 permite.
class PerfilPessoaPage extends StatefulWidget {
  const PerfilPessoaPage({
    super.key,
    required this.uid,
    required this.pedidoId,
  });

  final String uid;
  final String pedidoId;

  @override
  State<PerfilPessoaPage> createState() => _PerfilPessoaPageState();
}

class _PerfilPessoaPageState extends State<PerfilPessoaPage> {
  late final Future<Pedido?> _pedido;

  @override
  void initState() {
    super.initState();
    _pedido = context.read<PedidoController>().buscar(
      pedidoId: widget.pedidoId,
    );
  }

  /// O app só oferece o perfil do contratante do pedido ou, ao próprio
  /// contratante, o de quem se candidatou (FR-015).
  bool _acessoPeloPedido(Pedido pedido, Conta conta) =>
      widget.uid == pedido.contratanteUid || conta.uid == pedido.contratanteUid;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Perfil')),
    body: FutureBuilder<Pedido?>(
      future: _pedido,
      builder: (context, snapshot) {
        final contas = context.watch<ContaController>();
        if (snapshot.connectionState != ConnectionState.done ||
            contas.carregandoSessao) {
          return const Center(child: CircularProgressIndicator());
        }
        final pedido = snapshot.data;
        final conta = contas.conta;
        if (snapshot.hasError ||
            pedido == null ||
            conta == null ||
            !_acessoPeloPedido(pedido, conta)) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Não foi possível abrir este perfil.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ChangeNotifierProvider(
          create: (context) =>
              PerfilController(
                  context.read<PerfilRepository>(),
                  context.read<AvaliacaoRepository>(),
                  context.read<CandidaturaRepository>(),
                )
                ..carregar(widget.uid)
                ..carregarFotoDaParte(
                  pedido: pedido,
                  visualizador: conta,
                  uid: widget.uid,
                ),
          child: const _Conteudo(),
        );
      },
    ),
  );
}

class _Conteudo extends StatelessWidget {
  const _Conteudo();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PerfilController>();
    final perfil = controller.perfil.data;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        if (perfil != null) ...[
          CabecalhoPerfil(
            nome: perfil.nome,
            cidade: perfil.cidade,
            perfil: perfil.perfil,
            foto: controller.foto?.bytes,
          ),
          const SizedBox(height: 24),
        ],
        const ReputacaoPerfil(),
      ],
    );
  }
}
