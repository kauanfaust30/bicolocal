import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../candidaturas/presentation/candidatura_controller.dart';
import '../../conta/domain/conta.dart';
import '../../conta/presentation/conta_controller.dart';
import '../domain/categoria.dart';
import '../domain/data_civil.dart';
import '../domain/pedido.dart';
import 'pedido_controller.dart';

class GerenciarPedidoPage extends StatefulWidget {
  const GerenciarPedidoPage({super.key, required this.pedidoId});

  final String pedidoId;

  @override
  State<GerenciarPedidoPage> createState() => _GerenciarPedidoPageState();
}

class _GerenciarPedidoPageState extends State<GerenciarPedidoPage> {
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
    appBar: AppBar(title: const Text('Gerenciar pedido')),
    body: FutureBuilder<Pedido?>(
      future: _pedido,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final pedido = snapshot.data;
        if (pedido == null) {
          return const Center(
            child: Text('Não foi possível abrir este pedido.'),
          );
        }
        return _FormularioPedido(pedido: pedido);
      },
    ),
  );
}

class _FormularioPedido extends StatefulWidget {
  const _FormularioPedido({required this.pedido});

  final Pedido pedido;

  @override
  State<_FormularioPedido> createState() => _FormularioPedidoState();
}

class _FormularioPedidoState extends State<_FormularioPedido> {
  late final TextEditingController _titulo;
  late final TextEditingController _descricao;
  late final TextEditingController _cidade;
  late final TextEditingController _local;
  late final TextEditingController _valor;
  Categoria? _categoria;
  DateTime? _dataDesejada;
  DateTime? _validadeAte;
  bool _contatoCarregado = false;

  @override
  void initState() {
    super.initState();
    final pedido = widget.pedido;
    _titulo = TextEditingController(text: pedido.titulo);
    _descricao = TextEditingController(text: pedido.descricao);
    _cidade = TextEditingController(text: pedido.cidade);
    _local = TextEditingController(text: pedido.local);
    _valor = TextEditingController(
      text: (pedido.valorCentavos / 100)
          .toStringAsFixed(2)
          .replaceAll('.', ','),
    );
    _categoria = Categoria(id: pedido.categoriaId, nome: pedido.categoriaNome);
    _dataDesejada = pedido.dataDesejada;
    _validadeAte = pedido.validadeAte;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PedidoController>().carregarCategorias();
    });
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _cidade.dispose();
    _local.dispose();
    _valor.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final controller = context.read<PedidoController>();
    final alterado = widget.pedido.copyWith(
      titulo: _titulo.text.trim(),
      categoriaId: _categoria?.id ?? widget.pedido.categoriaId,
      categoriaNome: _categoria?.nome ?? widget.pedido.categoriaNome,
      descricao: _descricao.text.trim(),
      cidade: _cidade.text.trim(),
      local: _local.text.trim(),
      dataDesejada: _dataDesejada,
      validadeAte: _validadeAte,
      valorCentavos: _valorEmCentavos(_valor.text),
    );
    final salvo = await controller.atualizarPedido(
      editor: context.read<ContaController>().conta,
      original: widget.pedido,
      alterado: alterado,
    );
    if (mounted && salvo) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Alterações salvas.')));
    }
  }

  Future<void> _cancelar() async {
    await context.read<PedidoController>().cancelarPedido(
      editor: context.read<ContaController>().conta,
      pedido: widget.pedido,
    );
  }

  @override
  Widget build(BuildContext context) => Consumer<PedidoController>(
    builder: (context, controller, _) {
      final conta = context.watch<ContaController>().conta;
      if (!_contatoCarregado &&
          conta != null &&
          widget.pedido.estado == EstadoPedido.emAndamento) {
        _contatoCarregado = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<CandidaturaController>().carregarContato(
              pedido: widget.pedido,
              visualizador: conta,
            );
          }
        });
      }
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _campo('Título', _titulo, erro: controller.errosCampos['titulo']),
          const SizedBox(height: 12),
          _categoriaCampo(controller),
          const SizedBox(height: 12),
          _campo(
            'Descrição',
            _descricao,
            erro: controller.errosCampos['descricao'],
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _campo('Cidade', _cidade, erro: controller.errosCampos['cidade']),
          const SizedBox(height: 12),
          _campo('Local', _local, erro: controller.errosCampos['local']),
          const SizedBox(height: 12),
          _seletorData(
            label: 'Data desejada',
            data: _dataDesejada,
            erro: controller.errosCampos['dataDesejada'],
            aoSelecionar: () => _selecionarData(validade: false),
          ),
          const SizedBox(height: 12),
          _seletorData(
            label: 'Validade até',
            data: _validadeAte,
            erro: controller.errosCampos['validadeAte'],
            aoSelecionar: () => _selecionarData(validade: true),
          ),
          const SizedBox(height: 12),
          _campo(
            'Valor em reais',
            _valor,
            erro: controller.errosCampos['valorCentavos'],
            teclado: TextInputType.number,
          ),
          if (controller.erro != null) ...[
            const SizedBox(height: 12),
            Text(
              controller.erro!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (controller.mensagem != null) ...[
            const SizedBox(height: 12),
            Text(controller.mensagem!),
          ],
          _contato(conta),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.publicando ? null : _salvar,
            child: const Text('Salvar alterações'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: controller.publicando ? null : _cancelar,
            child: const Text('Cancelar pedido'),
          ),
        ],
      );
    },
  );

  Widget _contato(Conta? conta) {
    if (conta == null || widget.pedido.estado != EstadoPedido.emAndamento) {
      return const SizedBox.shrink();
    }
    return Consumer<CandidaturaController>(
      builder: (context, controller, _) => controller.emailContato == null
          ? const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Os contatos ficam disponíveis após o aceite.'),
            )
          : Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SelectableText(
                'E-mail de contato: ${controller.emailContato}',
              ),
            ),
    );
  }

  Widget _campo(
    String rotulo,
    TextEditingController controller, {
    required String? erro,
    int maxLines = 1,
    TextInputType? teclado,
  }) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: teclado,
    decoration: InputDecoration(labelText: rotulo, errorText: erro),
  );

  Widget _categoriaCampo(PedidoController controller) {
    if (controller.categorias.isEmpty) {
      return Text(
        'Categoria: ${_categoria?.nome ?? widget.pedido.categoriaNome}',
      );
    }
    final existe = controller.categorias.any(
      (categoria) => categoria.id == _categoria?.id,
    );
    return DropdownButtonFormField<String>(
      initialValue: existe ? _categoria!.id : null,
      decoration: InputDecoration(
        labelText: 'Categoria',
        errorText: controller.errosCampos['categoriaId'],
      ),
      items: controller.categorias
          .map(
            (categoria) => DropdownMenuItem(
              value: categoria.id,
              child: Text(categoria.nome),
            ),
          )
          .toList(),
      onChanged: (id) {
        for (final categoria in controller.categorias) {
          if (categoria.id == id) _categoria = categoria;
        }
      },
    );
  }

  Future<void> _selecionarData({required bool validade}) async {
    final hoje = DateTime.now();
    final atual = validade ? _validadeAte : _dataDesejada;
    final inicial = atual ?? hoje;
    final escolhida = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(inicial.year < hoje.year ? inicial.year : hoje.year),
      lastDate: DateTime(hoje.year + 10),
      cancelText: 'Cancelar',
      confirmText: 'Selecionar',
    );
    if (escolhida == null) return;
    setState(() {
      if (validade) {
        _validadeAte = escolhida;
      } else {
        _dataDesejada = escolhida;
      }
    });
  }

  Widget _seletorData({
    required String label,
    required DateTime? data,
    required String? erro,
    required VoidCallback aoSelecionar,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      OutlinedButton(
        onPressed: aoSelecionar,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            data == null ? label : '$label: ${DataCivil.formatar(data)}',
          ),
        ),
      ),
      if (erro != null)
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            erro,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
    ],
  );

  int _valorEmCentavos(String texto) {
    final valor = double.tryParse(
      texto.trim().replaceAll('.', '').replaceAll(',', '.'),
    );
    return valor == null ? 0 : (valor * 100).round();
  }
}
