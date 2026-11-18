import 'package:bicolocal/core/app.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:bicolocal/features/pedidos/domain/categoria.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/builders/test_data.dart';
import '../../../support/fakes/fake_repositories.dart';

void main() {
  final contratante = criarContaTeste(
    uid: 'contratante-1',
    perfil: Perfil.contratante,
  );
  final pedido = criarPedidoTeste(
    id: 'pedido-1',
    contratanteUid: contratante.uid,
    dataDesejada: DateTime.utc(2099, 1, 3),
    validadeAte: DateTime.utc(2099, 1, 2),
  );

  Future<void> abrir(WidgetTester tester, String caminho) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: contratante),
        pedidoRepository: FakePedidoRepository(
          categorias: const [Categoria(id: 'reparos', nome: 'Reparos')],
          pedidos: [pedido],
        ),
        candidaturaRepository: FakeCandidaturaRepository(),
        perfilRepository: FakePerfilRepository(),
        avaliacaoRepository: FakeAvaliacaoRepository(),
        seletorFoto: FakeSeletorFoto(),
        initialLocation: caminho,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> verSecoes(WidgetTester tester) async {
    final lista = find.byType(ListView).first;
    for (final secao in ['O que você precisa', 'Onde', 'Quando e quanto']) {
      await tester.dragUntilVisible(
        find.text(secao),
        lista,
        const Offset(0, -150),
      );
      expect(find.text(secao), findsOneWidget, reason: secao);
    }
  }

  void verBotaoFixo(WidgetTester tester, String rotulo) {
    final botao = find.descendant(
      of: find.byKey(const Key('barra-acao')),
      matching: find.text(rotulo),
    );
    expect(botao, findsOneWidget);
    final tela = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(tester.getRect(botao).bottom, lessThanOrEqualTo(tela.height));
    expect(
      tester.getSize(find.byKey(const Key('barra-acao'))).height,
      greaterThanOrEqualTo(48),
    );
  }

  testWidgets('novo pedido agrupa campos em seções com ícones e ajuda', (
    tester,
  ) async {
    await abrir(tester, '/pedidos/novo');

    expect(find.byIcon(Icons.short_text), findsOneWidget);
    expect(find.text('Ex.: Montar um guarda-roupa'), findsOneWidget);
    await verSecoes(tester);
    expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
  });

  testWidgets('novo pedido mantém Publicar pedido fixo e visível', (
    tester,
  ) async {
    await abrir(tester, '/pedidos/novo');

    verBotaoFixo(tester, 'Publicar pedido');
  });

  testWidgets('gerenciar pedido agrupa campos em seções', (tester) async {
    await abrir(tester, '/pedidos/pedido-1/gerenciar');

    expect(find.byIcon(Icons.short_text), findsOneWidget);
    await verSecoes(tester);
  });

  testWidgets('gerenciar pedido mantém Salvar alterações fixo e visível', (
    tester,
  ) async {
    await abrir(tester, '/pedidos/pedido-1/gerenciar');

    verBotaoFixo(tester, 'Salvar alterações');
  });
}
