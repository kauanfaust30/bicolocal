import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../conta/presentation/conta_controller.dart';
import '../domain/categoria.dart';
import '../presentation/pedido_controller.dart';

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
        builder: (context, controller, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _campo('Título', _titulo, 'titulo', controller),
            const SizedBox(height: 12),
            DropdownButtonFormField<Categoria>(
              initialValue: _categoria,
              decoration: InputDecoration(
                labelText: 'Categoria',
                errorText: controller.errosCampos['categoriaId'],
              ),
              items: controller.categorias
                  .map(
                    (categoria) => DropdownMenuItem(
                      value: categoria,
                      child: Text(categoria.nome),
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
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
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
            const SizedBox(height: 12),
            _campo(
              'Descrição',
              _descricao,
              'descricao',
              controller,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _campo('Cidade', _cidade, 'cidade', controller),
            const SizedBox(height: 12),
            _campo('Local do serviço', _local, 'local', controller),
            const SizedBox(height: 12),
            _campo(
              'Valor em reais',
              _valor,
              'valorCentavos',
              controller,
              teclado: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            _seletorData(
              label: 'Data desejada',
              data: _dataDesejada,
              erro: controller.errosCampos['dataDesejada'],
              aoSelecionar: () => _selecionarData(validade: false),
            ),
            const SizedBox(height: 8),
            _seletorData(
              label: 'Validade até',
              data: _validadeAte,
              erro: controller.errosCampos['validadeAte'],
              aoSelecionar: () => _selecionarData(validade: true),
            ),
            if (controller.erro != null) ...[
              const SizedBox(height: 12),
              Text(
                controller.erro!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: controller.publicando || _semCategorias(controller)
                  ? null
                  : _publicar,
              child: Text(
                controller.publicando ? 'Publicando…' : 'Publicar pedido',
              ),
            ),
          ],
        ),
      ),
    ),
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
    int maxLines = 1,
    TextInputType? teclado,
  }) => TextFormField(
    controller: textController,
    keyboardType: teclado,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      errorText: estado.errosCampos[chave],
    ),
  );

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
            data == null
                ? label
                : '$label: ${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}',
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

  int? _valorEmCentavos(String texto) {
    final limpo = texto.trim().replaceAll('.', '').replaceAll(',', '.');
    final valor = double.tryParse(limpo);
    if (valor == null) return null;
    return (valor * 100).round();
  }
}
