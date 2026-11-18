import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/avatar_pessoa.dart';
import '../../candidaturas/presentation/candidatura_controller.dart';
import '../../conta/domain/conta.dart';
import '../../conta/presentation/conta_controller.dart';
import '../../pedidos/domain/pedido.dart';
import '../../pedidos/domain/pedido_permissions.dart';
import '../../pedidos/presentation/pedido_controller.dart';
import '../domain/avaliacao_validator.dart';
import 'avaliacao_controller.dart';

/// Avaliar a outra parte de um pedido concluído (FR-003 a FR-007). Quem não
/// é parte, ou pedido não concluído, vai para o início.
class AvaliarPage extends StatefulWidget {
  const AvaliarPage({super.key, required this.pedidoId});

  final String pedidoId;

  @override
  State<AvaliarPage> createState() => _AvaliarPageState();
}

class _AvaliarPageState extends State<AvaliarPage> {
  late final Future<Pedido?> _pedido;

  @override
  void initState() {
    super.initState();
    _pedido = context.read<PedidoController>().buscar(
      pedidoId: widget.pedidoId,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Avaliar')),
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
        if (snapshot.hasError || pedido == null) {
          return const Center(
            child: Text('Não foi possível abrir este pedido.'),
          );
        }
        if (conta == null ||
            !PedidoPermissions.podeAvaliar(pedido: pedido, uid: conta.uid)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/inicio');
          });
          return const SizedBox.shrink();
        }
        return _FormularioAvaliacao(pedido: pedido, conta: conta);
      },
    ),
  );
}

class _FormularioAvaliacao extends StatefulWidget {
  const _FormularioAvaliacao({required this.pedido, required this.conta});

  final Pedido pedido;
  final Conta conta;

  @override
  State<_FormularioAvaliacao> createState() => _FormularioAvaliacaoState();
}

class _FormularioAvaliacaoState extends State<_FormularioAvaliacao> {
  final _comentario = TextEditingController();
  int? _nota;

  @override
  void initState() {
    super.initState();
    context.read<AvaliacaoController>().iniciarFormulario();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CandidaturaController>().carregarOutraParte(
        pedido: widget.pedido,
        visualizador: widget.conta,
      );
      context.read<AvaliacaoController>().verificar(
        conta: widget.conta,
        pedido: widget.pedido,
      );
    });
  }

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final enviada = await context.read<AvaliacaoController>().enviar(
      pedido: widget.pedido,
      avaliador: widget.conta,
      nota: _nota,
      comentario: _comentario.text,
    );
    if (enviada && mounted) context.go('/meus-pedidos');
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AvaliacaoController>();
    final cores = Theme.of(context).colorScheme;
    final jaAvaliou = controller.jaAvaliou(
      conta: widget.conta,
      pedido: widget.pedido,
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _OutraParte(),
        const SizedBox(height: 20),
        if (jaAvaliou ?? false) ...[
          const Text('Você já avaliou'),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.go('/meus-pedidos'),
            child: const Text('Voltar'),
          ),
        ] else ...[
          Text('Sua nota', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var nota = 1; nota <= 5; nota++)
                IconButton(
                  tooltip: nota == 1 ? '1 estrela' : '$nota estrelas',
                  isSelected: _nota != null && nota <= _nota!,
                  iconSize: 36,
                  color: cores.primary,
                  icon: const Icon(Icons.star_border),
                  selectedIcon: const Icon(Icons.star),
                  onPressed: () => setState(() => _nota = nota),
                ),
            ],
          ),
          if (controller.errosCampos['nota'] case final erroNota?)
            Text(erroNota, style: TextStyle(color: cores.error)),
          const SizedBox(height: 16),
          TextField(
            controller: _comentario,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Comentário (opcional)',
              counterText:
                  '${AvaliacaoValidator.tamanhoComentario(_comentario.text)}'
                  '/${AvaliacaoValidator.comentarioMaximo}',
              errorText: controller.errosCampos['comentario'],
            ),
          ),
          const SizedBox(height: 16),
          const Text('A avaliação não pode ser editada depois.'),
          if (controller.erro case final erro?)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(erro, style: TextStyle(color: cores.error)),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: controller.enviando ? null : _enviar,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Enviar avaliação'),
          ),
        ],
      ],
    );
  }
}

/// Avatar e nome de quem será avaliado; a foto segue a regra do FR-020.
class _OutraParte extends StatelessWidget {
  const _OutraParte();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CandidaturaController>();
    final nome = controller.nomeOutraParte;
    return Row(
      children: [
        AvatarPessoa(
          nome: nome ?? '',
          bytes: controller.fotoOutraParte?.bytes,
          tamanho: 64,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            nome ?? 'Carregando…',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ],
    );
  }
}
