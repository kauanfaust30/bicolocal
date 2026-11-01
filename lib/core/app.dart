import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/conta/domain/conta_repository.dart';
import '../features/conta/presentation/conta_controller.dart';
import '../features/candidaturas/domain/candidatura_repository.dart';
import '../features/candidaturas/presentation/candidatura_controller.dart';
import '../features/pedidos/domain/pedido_repository.dart';
import '../features/pedidos/presentation/pedido_controller.dart';
import 'router.dart';

class BicoLocalApp extends StatefulWidget {
  const BicoLocalApp({
    super.key,
    required this.contaRepository,
    required this.pedidoRepository,
    required this.candidaturaRepository,
    this.initialLocation = '/cadastro',
  });

  final ContaRepository contaRepository;
  final PedidoRepository pedidoRepository;
  final CandidaturaRepository candidaturaRepository;
  final String initialLocation;

  @override
  State<BicoLocalApp> createState() => _BicoLocalAppState();
}

class _BicoLocalAppState extends State<BicoLocalApp> {
  late final ContaController _contaController;
  late final PedidoController _pedidoController;
  late final CandidaturaController _candidaturaController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _contaController = ContaController(widget.contaRepository);
    _pedidoController = PedidoController(widget.pedidoRepository);
    _candidaturaController = CandidaturaController(
      widget.candidaturaRepository,
    );
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: _contaController),
      ChangeNotifierProvider.value(value: _pedidoController),
      ChangeNotifierProvider.value(value: _candidaturaController),
    ],
    child: MaterialApp.router(
      title: 'BicoLocal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF075E46),
          primary: const Color(0xFF075E46),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAF9),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ),
      routerConfig: _router,
    ),
  );
}
