import 'package:bicolocal/core/app.dart';
import 'package:bicolocal/features/conta/domain/conta.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:bicolocal/features/pedidos/domain/pedido.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/builders/test_data.dart';
import '../../../support/fakes/fake_repositories.dart';

void main() {
  final contratante = criarContaTeste(
    uid: 'contratante-1',
    perfil: Perfil.contratante,
  );
  final prestador = criarContaTeste(uid: 'prestador-1');
  final emAndamento =
      criarPedidoTeste(
        id: 'p1',
        contratanteUid: contratante.uid,
        titulo: 'Pintar a sala',
        dataDesejada: DateTime.utc(2099, 11, 6),
        validadeAte: DateTime.utc(2099, 11, 5),
      ).copyWith(
        estado: EstadoPedido.emAndamento,
        prestadorEscolhidoUid: prestador.uid,
      );

  Future<FakePedidoRepository> abrir(
    WidgetTester tester, {
    required Conta conta,
    required Pedido pedido,
    String local = '/pedidos/p1/concluir',
  }) async {
    final pedidos = FakePedidoRepository(pedidos: [pedido]);
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: conta),
        pedidoRepository: pedidos,
        candidaturaRepository: FakeCandidaturaRepository(),
        perfilRepository: FakePerfilRepository(),
        avaliacaoRepository: FakeAvaliacaoRepository(),
        seletorFoto: FakeSeletorFoto(),
        initialLocation: local,
      ),
    );
    await tester.pumpAndSettle();
    return pedidos;
  }

  testWidgets('mostra o resumo e o aviso antes de concluir', (tester) async {
    await abrir(tester, conta: contratante, pedido: emAndamento);

    expect(find.text('Pintar a sala'), findsOneWidget);
    expect(
      find.text(
        'Depois de concluído, o pedido não pode mais ser editado nem '
        'cancelado. Você e o prestador poderão se avaliar.',
      ),
      findsOneWidget,
    );
    expect(find.text('Voltar'), findsOneWidget);
  });

  testWidgets('sucesso conclui e mostra "Pedido concluído."', (tester) async {
    final pedidos = await abrir(
      tester,
      conta: contratante,
      pedido: emAndamento,
    );

    await tester.tap(find.byKey(const Key('botao-concluir')));
    await tester.pumpAndSettle();

    expect(pedidos.pedidos.single.estado, EstadoPedido.concluido);
    expect(find.text('Pedido concluído.'), findsOneWidget);
  });

  testWidgets('pelo Meus pedidos: concluir e depois avaliar', (tester) async {
    await abrir(
      tester,
      conta: contratante,
      pedido: emAndamento,
      local: '/meus-pedidos',
    );

    await tester.ensureVisible(find.text('Concluir pedido'));
    await tester.tap(find.text('Concluir pedido'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao-concluir')));
    await tester.pumpAndSettle();

    expect(find.text('Pedido concluído.'), findsOneWidget);
    expect(find.text('Avaliar'), findsOneWidget);
    expect(find.text('Concluir pedido'), findsNothing);
  });

  testWidgets('pedido que não está em andamento é recusado', (tester) async {
    await abrir(
      tester,
      conta: contratante,
      pedido: emAndamento.copyWith(estado: EstadoPedido.aberto),
    );

    expect(
      find.text('Este pedido não pode ser concluído agora.'),
      findsOneWidget,
    );
    expect(find.text('Voltar ao início'), findsOneWidget);
    expect(find.byKey(const Key('botao-concluir')), findsNothing);
  });

  testWidgets('falha ao concluir mostra a recusa e mantém o estado', (
    tester,
  ) async {
    final pedidos = await abrir(
      tester,
      conta: contratante,
      pedido: emAndamento,
    );
    pedidos.falharConclusao = true;

    await tester.tap(find.byKey(const Key('botao-concluir')));
    await tester.pumpAndSettle();

    expect(
      find.text('Este pedido não pode ser concluído agora.'),
      findsOneWidget,
    );
    expect(pedidos.pedidos.single.estado, EstadoPedido.emAndamento);
  });

  testWidgets('prestador não abre a tela de concluir', (tester) async {
    await abrir(tester, conta: prestador, pedido: emAndamento);

    expect(find.byKey(const Key('botao-concluir')), findsNothing);
    expect(find.text('Meu perfil'), findsOneWidget);
  });
}
