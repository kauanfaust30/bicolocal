import 'package:bicolocal/core/app.dart';
import 'package:bicolocal/features/conta/domain/conta.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/builders/test_data.dart';
import '../../../support/fakes/fake_repositories.dart';

void main() {
  Future<void> abrirInicio(WidgetTester tester, Conta conta) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: conta),
        pedidoRepository: FakePedidoRepository(),
        candidaturaRepository: FakeCandidaturaRepository(),
        initialLocation: '/inicio',
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('contratante vê só as opções de contratante e não troca perfil', (
    tester,
  ) async {
    await abrirInicio(tester, criarContaTeste(perfil: Perfil.contratante));

    expect(find.widgetWithText(ElevatedButton, 'Publicar pedido'), findsOne);
    expect(find.text('Meus pedidos'), findsOneWidget);
    expect(find.text('Ver pedidos da minha cidade'), findsNothing);
    expect(find.textContaining('Trocar para'), findsNothing);
  });

  testWidgets('prestador vê só as opções de prestador e não troca perfil', (
    tester,
  ) async {
    await abrirInicio(tester, criarContaTeste(perfil: Perfil.prestador));

    expect(find.text('Ver pedidos da minha cidade'), findsOneWidget);
    expect(find.text('Meus pedidos'), findsOneWidget);
    expect(find.text('Publicar pedido'), findsNothing);
    expect(find.textContaining('Trocar para'), findsNothing);
  });
}
