import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/async/async_state.dart';
import '../../conta/domain/conta.dart';
import '../../conta/presentation/conta_controller.dart';
import '../../candidaturas/presentation/candidatura_controller.dart';
import '../domain/categoria.dart';
import '../domain/data_civil.dart';
import '../domain/pedido.dart';
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
            if (pedidos.categoriaSelecionada != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => pedidos.limparFiltroCategoria(
                    conta: contaController.conta,
                  ),
                  child: const Text('Limpar filtro'),
                ),
              ),
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
      return const LinearProgressIndicator();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            key: const Key('filtro-categoria'),
            initialValue: pedidos.categoriaSelecionada?.id ?? '',
            decoration: const InputDecoration(
              labelText: 'Filtrar por categoria',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('Todas as categorias'),
              ),
              ...pedidos.categorias.map(
                (categoria) => DropdownMenuItem(
                  value: categoria.id,
                  child: Text(categoria.nome),
                ),
              ),
            ],
            onChanged: (categoriaId) {
              Categoria? categoria;
              for (final item in pedidos.categorias) {
                if (item.id == categoriaId) {
                  categoria = item;
                  break;
                }
              }
              pedidos.selecionarCategoria(conta: conta, categoria: categoria);
            },
          ),
          if (pedidos.erroCategorias != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
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
      return const Center(child: CircularProgressIndicator());
    }
    if (estado.status == AsyncStatus.erro) {
      return _erro(context, conta, estado.mensagemErro);
    }
    final itens = estado.data ?? const <Pedido>[];
    if (itens.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            pedidos.categoriaSelecionada == null
                ? (pedidos.cidadeSelecionada == null
                      ? 'Nenhum pedido aberto na sua cidade.'
                      : 'Nenhum pedido aberto nesta cidade.')
                : 'Nenhum pedido aberto para esta cidade e categoria.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itens.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _PedidoCard(pedido: itens[index], prestador: conta!),
    );
  }

  Widget _erro(BuildContext context, Conta? conta, String? mensagem) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(mensagem ?? 'Não foi possível carregar os pedidos.'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () =>
                context.read<PedidoController>().tentarNovamente(conta),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    ),
  );
}

class _PedidoCard extends StatelessWidget {
  const _PedidoCard({required this.pedido, required this.prestador});

  final Pedido pedido;
  final Conta prestador;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Consumer<CandidaturaController>(
        builder: (context, candidatura, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pedido.titulo, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(pedido.categoriaNome),
            const SizedBox(height: 8),
            Text(pedido.descricao),
            const SizedBox(height: 8),
            Text('Local: ${pedido.local}'),
            Text('Data desejada: ${DataCivil.formatar(pedido.dataDesejada)}'),
            const SizedBox(height: 8),
            Text(
              DataCivil.formatarValor(pedido.valorCentavos),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (candidatura.mensagem != null)
              Text(candidatura.mensagem!)
            else if (candidatura.erro != null)
              Text(
                candidatura.erro!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 8),
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
      ),
    ),
  );
}
