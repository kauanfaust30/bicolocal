import 'package:go_router/go_router.dart';

import '../features/conta/domain/perfil.dart';
import '../features/conta/presentation/cadastro_page.dart';
import '../features/conta/presentation/conta_controller.dart';
import '../features/conta/presentation/entrada_page.dart';
import '../features/conta/presentation/inicio_page.dart';
import '../features/candidaturas/presentation/revisar_candidaturas_page.dart';
import '../features/pedidos/presentation/lista_pedidos_page.dart';
import '../features/pedidos/presentation/gerenciar_pedido_page.dart';
import '../features/pedidos/presentation/meus_pedidos_page.dart';
import '../features/pedidos/presentation/publicar_pedido_page.dart';

GoRouter criarRouter({
  String initialLocation = '/cadastro',
  required ContaController contaController,
}) => GoRouter(
  initialLocation: initialLocation,
  refreshListenable: contaController,
  redirect: (context, state) {
    if (contaController.carregandoSessao) return null;
    final conta = contaController.conta;
    final caminho = state.matchedLocation;
    final rotaPublica = caminho == '/cadastro' || caminho == '/entrar';
    if (conta == null) return rotaPublica ? null : '/entrar';
    if (rotaPublica || caminho == '/') return '/inicio';
    if (caminho == '/pedidos' && conta.perfil != Perfil.prestador) {
      return '/inicio';
    }
    final somenteContratante =
        caminho == '/pedidos/novo' ||
        state.fullPath == '/pedidos/:pedidoId/candidaturas';
    if (somenteContratante && conta.perfil != Perfil.contratante) {
      return '/inicio';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      redirect: (_, _) =>
          contaController.conta == null ? '/cadastro' : '/inicio',
    ),
    GoRoute(path: '/cadastro', builder: (_, _) => const CadastroPage()),
    GoRoute(path: '/entrar', builder: (_, _) => const EntradaPage()),
    GoRoute(path: '/inicio', builder: (_, _) => const InicioPage()),
    GoRoute(path: '/pedidos', builder: (_, _) => const ListaPedidosPage()),
    GoRoute(path: '/meus-pedidos', builder: (_, _) => const MeusPedidosPage()),
    GoRoute(
      path: '/pedidos/:pedidoId/candidaturas',
      builder: (_, state) =>
          RevisarCandidaturasPage(pedidoId: state.pathParameters['pedidoId']!),
    ),
    GoRoute(
      path: '/pedidos/:pedidoId/gerenciar',
      builder: (_, state) =>
          GerenciarPedidoPage(pedidoId: state.pathParameters['pedidoId']!),
    ),
    GoRoute(
      path: '/pedidos/novo',
      builder: (_, _) => const PublicarPedidoPage(),
    ),
  ],
);
