import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../conta/presentation/conta_controller.dart';
import '../domain/categoria.dart';
import '../presentation/pedido_controller.dart';
import 'categoria_visual.dart';
import 'formulario_pedido_widgets.dart';

class PublicarPedidoPage extends StatefulWidget {
  const PublicarPedidoPage({super.key});

  @override
  State<PublicarPedidoPage> createState() => _PublicarPedidoPageState();
}

class _PublicarPedidoPageState extends State<PublicarPedidoPage> {
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  final _cidade = TextEditingController();
  final _local = TextEditingController();
  final _valor = TextEditingController();
  Categoria? _categoria;
  DateTime? _dataDesejada;
  DateTime? _validadeAte;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final conta = context.read<ContaController>().conta;
      _cidade.text = conta?.cidade ?? '';
      context.read<PedidoController>().carregarCategorias();
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

  Future<void> _selecionarData({required bool validade}) async {
    final hoje = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: validade ? (_validadeAte ?? hoje) : (_dataDesejada ?? hoje),
      firstDate: DateTime(hoje.year, hoje.month, hoje.day),
      lastDate: DateTime(hoje.year + 5),
      helpText: validade ? 'Escolha a validade' : 'Escolha a data do serviço',
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

  Future<void> _publicar() async {
    final controller = context.read<PedidoController>();
    final ok = await controller.publicar(
      conta: context.read<ContaController>().conta,
      titulo: _titulo.text,
      categoria: _categoria,
      descricao: _descricao.text,
      cidade: _cidade.text,
      local: _local.text,
      dataDesejada: _dataDesejada,
      validadeAte: _validadeAte,
      valorCentavos: _valorEmCentavos(_valor.text),
    );
    if (mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido publicado com sucesso.')),
      );
      context.go('/inicio');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Novo pedido')),
    body: SafeArea(
      child: Consumer<PedidoController>(
        builder: (context, controller, _) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                children: [
                  SecaoFormulario(
                    icone: Icons.assignment_outlined,
                    titulo: 'O que você precisa',
                    children: [
                      _campo(
                        'Título',
                        _titulo,
                        'titulo',
                        controller,
                        icone: Icons.short_text,
                        ajuda: AjudaPedido.titulo,
                      ),
                      _categoriaCampo(controller),
                      _campo(
                        'Descrição',
                        _descricao,
                        'descricao',
                        controller,
                        icone: Icons.notes,
                        ajuda: AjudaPedido.descricao,
                        maxLines: 3,
                      ),
                    ],
                  ),
                  SecaoFormulario(
                    icone: Icons.map_outlined,
                    titulo: 'Onde',
                    children: [
                      _campo(
                        'Cidade',
                        _cidade,
                        'cidade',
                        controller,
                        icone: Icons.location_city,
                        ajuda: AjudaPedido.cidade,
                      ),
                      _campo(
                        'Local do serviço',
                        _local,
                        'local',
                        controller,
                        icone: Icons.place_outlined,
                        ajuda: AjudaPedido.local,
                      ),
                    ],
                  ),
                  SecaoFormulario(
                    icone: Icons.event_note_outlined,
                    titulo: 'Quando e quanto',
                    children: [
                      CampoData(
                        rotulo: 'Data desejada',
                        icone: Icons.event,
                        data: _dataDesejada,
                        ajuda: AjudaPedido.dataDesejada,
                        erro: controller.errosCampos['dataDesejada'],
                        aoSelecionar: () => _selecionarData(validade: false),
                      ),
                      CampoData(
                        rotulo: 'Validade até',
                        icone: Icons.event_available,
                        data: _validadeAte,
                        ajuda: AjudaPedido.validade,
                        erro: controller.errosCampos['validadeAte'],
                        aoSelecionar: () => _selecionarData(validade: true),
                      ),
                      _campo(
                        'Valor em reais',
                        _valor,
                        'valorCentavos',
                        controller,
                        icone: Icons.payments_outlined,
                        ajuda: AjudaPedido.valor,
                        teclado: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            BarraAcaoFixa(
              children: [
                if (controller.erro != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      controller.erro!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: controller.publicando || _semCategorias(controller)
                      ? null
                      : _publicar,
                  icon: const Icon(Icons.send_outlined),
                  label: Text(
                    controller.publicando ? 'Publicando…' : 'Publicar pedido',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _categoriaCampo(PedidoController controller) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DropdownButtonFormField<Categoria>(
        initialValue: _categoria,
        decoration: InputDecoration(
          labelText: 'Categoria',
          prefixIcon: const Icon(Icons.category_outlined),
          errorText: controller.errosCampos['categoriaId'],
        ),
        items: controller.categorias
            .map(
              (categoria) => DropdownMenuItem(
                value: categoria,
                child: Row(
                  children: [
                    Icon(
                      CategoriaVisual.daCategoria(categoria).icone,
                      color: CategoriaVisual.daCategoria(categoria).cor,
                    ),
                    const SizedBox(width: 12),
                    Text(categoria.nome),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: (categoria) => setState(() => _categoria = categoria),
      ),
      if (controller.carregandoCategorias)
        const Padding(
          padding: EdgeInsets.all(8),
          child: LinearProgressIndicator(),
        )
      else if (controller.erroCategorias != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  controller.erroCategorias!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              TextButton(
                onPressed: controller.carregarCategorias,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        )
      else if (controller.categorias.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Nenhuma categoria disponível. Tente novamente mais tarde.',
          ),
        ),
    ],
  );

  bool _semCategorias(PedidoController controller) =>
      !controller.carregandoCategorias &&
      controller.erroCategorias == null &&
      controller.categorias.isEmpty;

  Widget _campo(
    String label,
    TextEditingController textController,
    String chave,
    PedidoController estado, {
    required IconData icone,
    String? ajuda,
    int maxLines = 1,
    TextInputType? teclado,
  }) => TextFormField(
    controller: textController,
    keyboardType: teclado,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icone),
      helperText: ajuda,
      helperMaxLines: 2,
      errorText: estado.errosCampos[chave],
    ),
  );

  int? _valorEmCentavos(String texto) {
    final limpo = texto.trim().replaceAll('.', '').replaceAll(',', '.');
    final valor = double.tryParse(limpo);
    if (valor == null) return null;
    return (valor * 100).round();
  }
}
