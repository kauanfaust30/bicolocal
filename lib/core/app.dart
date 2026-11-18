import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/conta/domain/conta_repository.dart';
import '../features/conta/presentation/conta_controller.dart';
import '../features/candidaturas/domain/candidatura_repository.dart';
import '../features/candidaturas/presentation/candidatura_controller.dart';
import '../features/pedidos/domain/pedido_repository.dart';
import '../features/pedidos/presentation/pedido_controller.dart';
import '../features/avaliacoes/domain/avaliacao_repository.dart';
import '../features/avaliacoes/presentation/avaliacao_controller.dart';
import '../features/perfil/domain/perfil_repository.dart';
import '../features/perfil/domain/seletor_foto.dart';
import 'router.dart';
import 'tema.dart';

class BicoLocalApp extends StatefulWidget {
  const BicoLocalApp({
    super.key,
    required this.contaRepository,
    required this.pedidoRepository,
    required this.candidaturaRepository,
    required this.perfilRepository,
    required this.avaliacaoRepository,
    required this.seletorFoto,
    this.initialLocation = '/cadastro',
  });

  final ContaRepository contaRepository;
  final PedidoRepository pedidoRepository;
  final CandidaturaRepository candidaturaRepository;
  final PerfilRepository perfilRepository;
  final AvaliacaoRepository avaliacaoRepository;
  final SeletorFoto seletorFoto;
  final String initialLocation;

  @override
  State<BicoLocalApp> createState() => _BicoLocalAppState();
}

class _BicoLocalAppState extends State<BicoLocalApp> {
  late final ContaController _contaController;
  late final PedidoController _pedidoController;
  late final CandidaturaController _candidaturaController;
  late final AvaliacaoController _avaliacaoController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _contaController = ContaController(widget.contaRepository);
    _pedidoController = PedidoController(widget.pedidoRepository);
    _candidaturaController = CandidaturaController(
      widget.candidaturaRepository,
      widget.perfilRepository,
    );
    _avaliacaoController = AvaliacaoController(widget.avaliacaoRepository);
    _router = criarRouter(
      initialLocation: widget.initialLocation,
      contaController: _contaController,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _contaController.dispose();
    _pedidoController.dispose();
    _candidaturaController.dispose();
    _avaliacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: _contaController),
      ChangeNotifierProvider.value(value: _pedidoController),
      ChangeNotifierProvider.value(value: _candidaturaController),
      ChangeNotifierProvider.value(value: _avaliacaoController),
      Provider<PerfilRepository>.value(value: widget.perfilRepository),
      Provider<CandidaturaRepository>.value(
        value: widget.candidaturaRepository,
      ),
      Provider<AvaliacaoRepository>.value(value: widget.avaliacaoRepository),
      Provider<SeletorFoto>.value(value: widget.seletorFoto),
    ],
    child: MaterialApp.router(
      title: 'BicoLocal',
      theme: criarTemaBicoLocal(),
      builder: (context, child) => _LarguraMaxima(child: child),
      routerConfig: _router,
    ),
  );
}

/// Em telas largas (navegador, tablet), centraliza o app com até 600 px
/// para o conteúdo não esticar. No celular, usa a largura toda.
class _LarguraMaxima extends StatelessWidget {
  const _LarguraMaxima({required this.child});

  static const larguraMaxima = 600.0;

  final Widget? child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: larguraMaxima),
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );
}
