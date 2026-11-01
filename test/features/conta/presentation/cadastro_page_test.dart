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

    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
    expect(find.text('Informe seu nome.'), findsOneWidget);
    expect(find.text('Informe sua cidade.'), findsOneWidget);
    expect(find.text('Informe seu bairro.'), findsOneWidget);
    expect(find.text('Escolha um perfil.'), findsOneWidget);
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

  testWidgets('explica e alterna entre os perfis sem perder a conta', (
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

    expect(find.text('Perfil ativo: Contratante'), findsOneWidget);
    expect(
      find.text('Publique e gerencie seus próprios pedidos.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Trocar para prestador'));
    await tester.pumpAndSettle();

    expect(find.text('Perfil ativo: Prestador'), findsOneWidget);
    expect(
      find.text('Consulte pedidos locais e candidate-se.'),
      findsOneWidget,
    );
  });

  testWidgets('redireciona se o perfil muda em outra aba', (tester) async {
    final contas = FakeContaRepository(
      contaInicial: _contratante.copyWith(perfil: Perfil.prestador),
    );
    addTearDown(contas.dispose);
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: contas,
        pedidoRepository: FakePedidoRepository(),
        candidaturaRepository: FakeCandidaturaRepository(),
        initialLocation: '/pedidos',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pedidos por cidade'), findsOneWidget);

    contas.publicarConta(_contratante);
    await tester.pumpAndSettle();

    expect(find.text('Perfil ativo: Contratante'), findsOneWidget);
    expect(find.text('Pedidos por cidade'), findsNothing);
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

      expect(find.text('Perfil ativo: Contratante'), findsOneWidget);
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
