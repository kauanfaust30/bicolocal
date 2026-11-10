import 'package:bicolocal/core/app.dart';
import 'package:bicolocal/features/conta/domain/conta.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';

import '../../../support/fakes/fake_repositories.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cadastro vazio informa campos obrigatórios em português', (
    tester,
  ) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(),
        pedidoRepository: FakePedidoRepository(),
        candidaturaRepository: FakeCandidaturaRepository(),
        initialLocation: '/cadastro',
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('Escolha um perfil.'), findsOneWidget);
    for (final mensagem in [
      'Informe seu bairro.',
      'Informe sua cidade.',
      'Informe seu nome.',
      'Informe sua senha.',
      'Informe seu e-mail.',
    ]) {
      await tester.dragUntilVisible(
        find.text(mensagem),
        find.byType(ListView),
        const Offset(0, 200),
      );
      expect(find.text(mensagem), findsOneWidget);
    }
  });

  testWidgets('entrada vazia mostra erros junto aos campos', (tester) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(),
        pedidoRepository: FakePedidoRepository(),
        candidaturaRepository: FakeCandidaturaRepository(),
        initialLocation: '/entrar',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
  });

  testWidgets('Sair encerra a sessão e volta para a tela de entrada', (
    tester,
  ) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: _contratante),
        pedidoRepository: FakePedidoRepository(),
        candidaturaRepository: FakeCandidaturaRepository(),
        initialLocation: '/inicio',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Olá, Ana Silva'), findsOneWidget);
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(find.text('E-mail'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Entrar'), findsOneWidget);
  });

  testWidgets('tela inicial explica o perfil da conta', (tester) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: _contratante),
        pedidoRepository: FakePedidoRepository(),
        candidaturaRepository: FakeCandidaturaRepository(),
        initialLocation: '/inicio',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('selo-perfil')),
        matching: find.text('Contratante'),
      ),
      findsOneWidget,
    );
    expect(
      find.text('Publique e gerencie seus próprios pedidos.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'leva perfil contratante para início ao abrir lista de prestador',
    (tester) async {
      await tester.pumpWidget(
        BicoLocalApp(
          contaRepository: FakeContaRepository(contaInicial: _contratante),
          pedidoRepository: FakePedidoRepository(),
          candidaturaRepository: FakeCandidaturaRepository(),
          initialLocation: '/pedidos',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('selo-perfil')),
          matching: find.text('Contratante'),
        ),
        findsOneWidget,
      );
      expect(
        find.text('Publique e gerencie seus próprios pedidos.'),
        findsOneWidget,
      );
    },
  );
}

const _contratante = Conta(
  uid: 'conta-1',
  email: 'ana@example.com',
  nome: 'Ana Silva',
  cidade: 'São Paulo',
  bairro: 'Centro',
  perfil: Perfil.contratante,
);
