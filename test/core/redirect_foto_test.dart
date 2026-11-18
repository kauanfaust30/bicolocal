import 'package:bicolocal/core/app.dart';
import 'package:bicolocal/features/conta/domain/conta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders/test_data.dart';
import '../support/fakes/fake_repositories.dart';

/// FR-018: conta sem foto é levada a Adicionar foto antes das demais telas.
void main() {
  Future<void> abrir(WidgetTester tester, Conta conta, String caminho) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: conta),
        pedidoRepository: FakePedidoRepository(),
        candidaturaRepository: FakeCandidaturaRepository(),
        perfilRepository: FakePerfilRepository(),
        avaliacaoRepository: FakeAvaliacaoRepository(),
        seletorFoto: FakeSeletorFoto(),
        initialLocation: caminho,
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final caminho in ['/inicio', '/meus-pedidos', '/pedidos', '/perfil']) {
    testWidgets('conta sem foto em $caminho vai para Adicionar foto', (
      tester,
    ) async {
      await abrir(tester, criarContaTeste(temFoto: false), caminho);

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Adicionar foto'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Olá,'), findsNothing);
    });
  }

  testWidgets('conta com foto em /foto vai para o início', (tester) async {
    await abrir(tester, criarContaTeste(nome: 'Ana Silva'), '/foto');

    expect(find.text('Olá, Ana Silva'), findsOneWidget);
  });
}
