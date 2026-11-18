import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/avatar_pessoa.dart';
import '../../candidaturas/presentation/candidatura_controller.dart';
import '../../conta/domain/conta.dart';
import '../../conta/presentation/conta_controller.dart';
import '../domain/categoria.dart';
import '../domain/pedido.dart';
import '../domain/pedido_permissions.dart';
import 'categoria_visual.dart';
import 'formulario_pedido_widgets.dart';
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
        final contas = context.watch<ContaController>();
        if (snapshot.connectionState != ConnectionState.done ||
            contas.carregandoSessao) {
          return const Center(child: CircularProgressIndicator());
        }
        final pedido = snapshot.data;
        if (pedido == null) {
          return const Center(
            child: Text('Não foi possível abrir este pedido.'),
          );
        }
        if (!PedidoPermissions.ehParte(
          pedido: pedido,
          uid: contas.conta?.uid,
        )) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/inicio');
          });
          return const SizedBox.shrink();
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
  bool _outraParteCarregada = false;

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
      if (!_outraParteCarregada &&
          conta != null &&
          widget.pedido.prestadorEscolhidoUid != null) {
        _outraParteCarregada = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<CandidaturaController>().carregarOutraParte(
              pedido: widget.pedido,
              visualizador: conta,
            );
          }
        });
      }
      final erros = controller.errosCampos;
      return Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              children: [
                if (PedidoPermissions.outraParte(
                      pedido: widget.pedido,
                      uid: conta?.uid,
                    )
                    case final outroUid?)
                  _OutraParte(
                    rotulo: conta?.uid == widget.pedido.contratanteUid
                        ? 'Prestador escolhido'
                        : 'Contratante',
                    aoTocar: () => context.push(
                      '/perfis/$outroUid?pedido=${widget.pedido.id}',
                    ),
                  ),
                SecaoFormulario(
                  icone: Icons.assignment_outlined,
                  titulo: 'O que você precisa',
                  children: [
                    _campo(
                      'Título',
                      _titulo,
                      erro: erros['titulo'],
                      icone: Icons.short_text,
                      ajuda: AjudaPedido.titulo,
                    ),
                    _categoriaCampo(controller),
                    _campo(
                      'Descrição',
                      _descricao,
                      erro: erros['descricao'],
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
                      erro: erros['cidade'],
                      icone: Icons.location_city,
                      ajuda: AjudaPedido.cidade,
                    ),
                    _campo(
                      'Local',
                      _local,
                      erro: erros['local'],
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
                      erro: erros['dataDesejada'],
                      aoSelecionar: () => _selecionarData(validade: false),
                    ),
                    CampoData(
                      rotulo: 'Validade até',
                      icone: Icons.event_available,
                      data: _validadeAte,
                      ajuda: AjudaPedido.validade,
                      erro: erros['validadeAte'],
                      aoSelecionar: () => _selecionarData(validade: true),
                    ),
                    _campo(
                      'Valor em reais',
                      _valor,
                      erro: erros['valorCentavos'],
                      icone: Icons.payments_outlined,
                      ajuda: AjudaPedido.valor,
                      teclado: TextInputType.number,
                    ),
                  ],
                ),
                _contato(conta),
                const SizedBox(height: 16),
                if (PedidoPermissions.podeConcluir(
                  pedido: widget.pedido,
                  uid: conta?.uid,
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.go('/pedidos/${widget.pedido.id}/concluir'),
                      icon: const Icon(Icons.task_alt),
                      label: const Text('Concluir pedido'),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: controller.publicando ? null : _cancelar,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar pedido'),
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
              if (controller.mensagem != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(controller.mensagem!),
                ),
              ElevatedButton.icon(
                onPressed: controller.publicando ? null : _salvar,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar alterações'),
              ),
            ],
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
    required IconData icone,
    String? ajuda,
    int maxLines = 1,
    TextInputType? teclado,
  }) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: teclado,
    decoration: InputDecoration(
      labelText: rotulo,
      prefixIcon: Icon(icone),
      helperText: ajuda,
      helperMaxLines: 2,
      errorText: erro,
    ),
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
        prefixIcon: const Icon(Icons.category_outlined),
        errorText: controller.errosCampos['categoriaId'],
      ),
      items: controller.categorias
          .map(
            (categoria) => DropdownMenuItem(
              value: categoria.id,
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

  int _valorEmCentavos(String texto) {
    final valor = double.tryParse(
      texto.trim().replaceAll('.', '').replaceAll(',', '.'),
    );
    return valor == null ? 0 : (valor * 100).round();
  }
}

/// Com quem a pessoa está tratando: nome e, depois do aceite, a foto da
/// outra parte (FR-020). Pedido cancelado ou sem cópia mostra a inicial.
class _OutraParte extends StatelessWidget {
  const _OutraParte({required this.rotulo, required this.aoTocar});

  final String rotulo;

  /// Abre o perfil da outra parte (FR-013, FR-014).
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CandidaturaController>();
    final nome = controller.nomeOutraParte ?? rotulo;
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AvatarPessoa(nome: nome, bytes: controller.fotoOutraParte?.bytes),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rotulo, style: Theme.of(context).textTheme.labelLarge),
                    Text(nome, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
