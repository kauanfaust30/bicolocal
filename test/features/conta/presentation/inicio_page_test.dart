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
        perfilRepository: FakePerfilRepository(),
        avaliacaoRepository: FakeAvaliacaoRepository(),
        seletorFoto: FakeSeletorFoto(),
        initialLocation: '/inicio',
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder emCartao(String texto) =>
      find.ancestor(of: find.text(texto), matching: find.byType(Card));

  testWidgets('saúda pelo nome, mostra o selo do perfil e Sair no topo', (
    tester,
  ) async {
    await abrirInicio(
      tester,
      criarContaTeste(nome: 'Ana Silva', perfil: Perfil.contratante),
    );

    expect(find.text('Olá, Ana Silva'), findsOneWidget);
    expect(find.byKey(const Key('selo-perfil')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('selo-perfil')),
        matching: find.text('Contratante'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Sair')),
      findsOneWidget,
    );
  });

  testWidgets('contratante vê as opções do perfil em cartões', (tester) async {
    await abrirInicio(tester, criarContaTeste(perfil: Perfil.contratante));

    expect(emCartao('Publicar pedido'), findsOneWidget);
    expect(emCartao('Meus pedidos'), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    expect(find.text('Ver pedidos da minha cidade'), findsNothing);
    expect(find.textContaining('Trocar para'), findsNothing);
  });

  testWidgets('prestador vê as opções do perfil em cartões', (tester) async {
    await abrirInicio(tester, criarContaTeste(perfil: Perfil.prestador));

    expect(emCartao('Ver pedidos da minha cidade'), findsOneWidget);
    expect(emCartao('Meus pedidos'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('selo-perfil')),
        matching: find.text('Prestador'),
      ),
      findsOneWidget,
    );
    expect(find.text('Publicar pedido'), findsNothing);
    expect(find.textContaining('Trocar para'), findsNothing);
  });

  testWidgets('tocar no cartão abre a tela correspondente', (tester) async {
    await abrirInicio(tester, criarContaTeste(perfil: Perfil.contratante));

    await tester.tap(find.text('Publicar pedido'));
    await tester.pumpAndSettle();

    expect(find.text('Novo pedido'), findsOneWidget);
  });
}
