import 'package:bicolocal/core/app.dart';
import 'package:bicolocal/features/conta/domain/conta.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:bicolocal/features/pedidos/domain/pedido.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders/test_data.dart';
import '../support/fakes/fake_repositories.dart';

void main() {
  final contratante = criarContaTeste(
    uid: 'contratante-1',
    perfil: Perfil.contratante,
  );
  final prestador = criarContaTeste(uid: 'prestador-1');
  final pedidoAberto = criarPedidoTeste(
    id: 'pedido-1',
    contratanteUid: contratante.uid,
    dataDesejada: DateTime.utc(2099, 1, 3),
    validadeAte: DateTime.utc(2099, 1, 2),
  );

  Future<void> abrir(
    WidgetTester tester, {
    required Conta conta,
    required String caminho,
    List<Pedido> pedidos = const [],
  }) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: conta),
        pedidoRepository: FakePedidoRepository(pedidos: pedidos),
        candidaturaRepository: FakeCandidaturaRepository(),
        initialLocation: caminho,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('prestador que abre publicar pedido volta para o início', (
    tester,
  ) async {
    await abrir(tester, conta: prestador, caminho: '/pedidos/novo');

    expect(find.text('Novo pedido'), findsNothing);
    expect(find.text('Ver pedidos da minha cidade'), findsOneWidget);
  });

  testWidgets('prestador que abre revisar candidaturas volta para o início', (
    tester,
  ) async {
    await abrir(
      tester,
      conta: prestador,
      caminho: '/pedidos/pedido-1/candidaturas',
      pedidos: [pedidoAberto],
    );

    expect(find.text('Ver pedidos da minha cidade'), findsOneWidget);
  });

  testWidgets(
    'prestador que não é parte do pedido e abre gerenciar volta para o início',
    (tester) async {
      await abrir(
        tester,
        conta: prestador,
        caminho: '/pedidos/pedido-1/gerenciar',
        pedidos: [pedidoAberto],
      );

      expect(find.text('Gerenciar pedido'), findsNothing);
      expect(find.text('Ver pedidos da minha cidade'), findsOneWidget);
    },
  );

  testWidgets('prestador escolhido continua podendo gerenciar o pedido', (
    tester,
  ) async {
    await abrir(
      tester,
      conta: prestador,
      caminho: '/pedidos/pedido-1/gerenciar',
      pedidos: [
        pedidoAberto.copyWith(
          estado: EstadoPedido.emAndamento,
          prestadorEscolhidoUid: prestador.uid,
        ),
      ],
    );

    expect(find.text('Gerenciar pedido'), findsOneWidget);
  });

  testWidgets('contratante que abre a lista por cidade volta para o início', (
    tester,
  ) async {
    await abrir(tester, conta: contratante, caminho: '/pedidos');

    expect(find.text('Pedidos por cidade'), findsNothing);
    expect(find.text('Publicar pedido'), findsOneWidget);
  });

  testWidgets('contratante autor continua podendo gerenciar o pedido', (
    tester,
  ) async {
    await abrir(
      tester,
      conta: contratante,
      caminho: '/pedidos/pedido-1/gerenciar',
      pedidos: [pedidoAberto],
    );

    expect(find.text('Gerenciar pedido'), findsOneWidget);
  });
}
