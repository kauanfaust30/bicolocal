import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/async/async_state.dart';
import '../../../core/widgets/estado_ilustrado.dart';
import '../../conta/domain/conta.dart';
import '../../conta/presentation/conta_controller.dart';
import '../../candidaturas/presentation/candidatura_controller.dart';
import '../domain/pedido.dart';
import 'categoria_visual.dart';
import 'pedido_card.dart';
import 'pedido_controller.dart';

class ListaPedidosPage extends StatefulWidget {
  const ListaPedidosPage({super.key});

  @override
  State<ListaPedidosPage> createState() => _ListaPedidosPageState();
}

class _ListaPedidosPageState extends State<ListaPedidosPage> {
  final TextEditingController _cidadeFiltro = TextEditingController();
  bool _carregamentoIniciado = false;
  bool _categoriasIniciadas = false;
  bool _cidadeInicializada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final conta = context.watch<ContaController>().conta;
    if (!_cidadeInicializada && conta != null) {
      _cidadeFiltro.text = conta.cidade;
      _cidadeInicializada = true;
    }
    if (!_carregamentoIniciado && conta != null) {
      _carregamentoIniciado = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<PedidoController>().carregar(conta);
      });
    }
    if (!_categoriasIniciadas && conta != null) {
      _categoriasIniciadas = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<PedidoController>().carregarCategorias();
      });
    }
  }

  @override
  void dispose() {
    _cidadeFiltro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Pedidos por cidade'),
      leading: IconButton(
        tooltip: 'Voltar ao início',
        onPressed: () => context.go('/inicio'),
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: Consumer2<PedidoController, ContaController>(
      builder: (context, pedidos, contaController, _) {
        return Column(
          children: [
            _filtroCidade(pedidos, contaController.conta),
            _filtroCategoria(context, pedidos, contaController.conta),
            Expanded(
              child: _conteudoLista(context, pedidos, contaController.conta),
            ),
          ],
        );
      },
    ),
  );

  Widget _filtroCidade(PedidoController pedidos, Conta? conta) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('filtro-cidade'),
          controller: _cidadeFiltro,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Cidade',
            hintText: 'Digite a cidade para buscar',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (cidade) =>
              pedidos.selecionarCidade(conta: conta, cidade: cidade),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ElevatedButton(
              onPressed: () => pedidos.selecionarCidade(
                conta: conta,
                cidade: _cidadeFiltro.text,
              ),
              child: const Text('Buscar cidade'),
            ),
            TextButton(
              onPressed: () {
                _cidadeFiltro.text = conta?.cidade ?? '';
                pedidos.limparFiltroCidade(conta: conta);
              },
              child: const Text('Minha cidade'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _filtroCategoria(
    BuildContext context,
    PedidoController pedidos,
    Conta? conta,
  ) {
    if (pedidos.carregandoCategorias) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: LinearProgressIndicator(),
      );
    }
    final selecionada = pedidos.categoriaSelecionada;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            key: const Key('filtro-categoria'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  key: const Key('filtro-categoria-todas'),
                  avatar: const Icon(Icons.apps),
                  label: const Text('Todas as categorias'),
                  selected: selecionada == null,
                  onSelected: (_) => pedidos.selecionarCategoria(
                    conta: conta,
                    categoria: null,
                  ),
                ),
                for (final categoria in pedidos.categorias) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    key: Key('filtro-categoria-${categoria.id}'),
                    avatar: Icon(CategoriaVisual.daCategoria(categoria).icone),
                    label: Text(categoria.nome),
                    selected: selecionada?.id == categoria.id,
                    onSelected: (_) => pedidos.selecionarCategoria(
                      conta: conta,
                      categoria: categoria,
                    ),
                  ),
                ],
                if (selecionada != null) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.filter_alt_off_outlined),
                    label: const Text('Limpar filtro'),
                    onPressed: () =>
                        pedidos.limparFiltroCategoria(conta: conta),
                  ),
                ],
              ],
            ),
          ),
          if (pedidos.erroCategorias != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                pedidos.erroCategorias!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _conteudoLista(
    BuildContext context,
    PedidoController pedidos,
    Conta? conta,
  ) {
    final estado = pedidos.estadoLista;
    if (estado.status == AsyncStatus.inicial ||
        estado.status == AsyncStatus.carregando) {
      return const EstadoIlustrado.carregando(
        titulo: 'Buscando pedidos perto de você…',
      );
    }
    if (estado.status == AsyncStatus.erro) {
      return EstadoIlustrado(
        icone: Icons.cloud_off_outlined,
        erro: true,
        titulo: estado.mensagemErro ?? 'Não foi possível carregar os pedidos.',
        acao: ElevatedButton.icon(
          onPressed: () =>
              context.read<PedidoController>().tentarNovamente(conta),
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      );
    }
    final itens = estado.data ?? const <Pedido>[];
    if (itens.isEmpty) {
      return const EstadoIlustrado(
        icone: Icons.search_off,
        iconeDetalhe: Icons.place_outlined,
        titulo: 'Nenhum pedido por aqui ainda.',
        mensagem: 'Tente outra cidade ou categoria.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itens.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _PedidoAberto(pedido: itens[index], prestador: conta!),
    );
  }
}

class _PedidoAberto extends StatelessWidget {
  const _PedidoAberto({required this.pedido, required this.prestador});

  final Pedido pedido;
  final Conta prestador;

  @override
  Widget build(BuildContext context) => Consumer<CandidaturaController>(
    builder: (context, candidatura, _) => PedidoCard(
      pedido: pedido,
      detalhes: true,
      acoes: [
        if (candidatura.mensagem != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(candidatura.mensagem!),
          )
        else if (candidatura.erro != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              candidatura.erro!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        // Perfil do contratante a partir do pedido (FR-014).
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton.icon(
            onPressed: () => context.push(
              '/perfis/${pedido.contratanteUid}?pedido=${pedido.id}',
            ),
            icon: const Icon(Icons.person_outline),
            label: const Text('Ver contratante'),
          ),
        ),
        ElevatedButton(
          onPressed: candidatura.executando
              ? null
              : () => candidatura.candidatar(
                  pedido: pedido,
                  prestador: prestador,
                ),
          child: const Text('Candidatar-se'),
        ),
      ],
    ),
  );
}
