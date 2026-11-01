import 'package:bicolocal/core/app.dart';
import 'package:bicolocal/features/conta/domain/conta.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:bicolocal/features/pedidos/domain/categoria.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes/fake_repositories.dart';

void main() {
  testWidgets(
    'falha ao carregar categorias mostra erro e permite tentar novamente',
    (tester) async {
      await tester.pumpWidget(
        BicoLocalApp(
          contaRepository: FakeContaRepository(contaInicial: _contratante),
          pedidoRepository: FakePedidoRepository(
            categorias: const [Categoria(id: 'reparos', nome: 'Reparos')],
            falhasCategoriasRestantes: 1,
          ),
          candidaturaRepository: FakeCandidaturaRepository(),
          initialLocation: '/pedidos/novo',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível carregar as categorias.'),
        findsOneWidget,
      );
      expect(find.text('Tentar novamente'), findsOneWidget);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível carregar as categorias.'),
        findsNothing,
      );
      expect(find.text('Tentar novamente'), findsNothing);

      await tester.tap(find.byType(DropdownButtonFormField<Categoria>));
      await tester.pumpAndSettle();
      expect(find.text('Reparos'), findsWidgets);
    },
  );

  testWidgets('sem categorias cadastradas avisa e desabilita a publicação', (
    tester,
  ) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: _contratante),
        pedidoRepository: FakePedidoRepository(),
        candidaturaRepository: FakeCandidaturaRepository(),
        initialLocation: '/pedidos/novo',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhuma categoria disponível. Tente novamente mais tarde.'),
      findsOneWidget,
    );

    await tester.dragUntilVisible(
      find.text('Publicar pedido'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    final botao = find.widgetWithText(ElevatedButton, 'Publicar pedido');
    expect(tester.widget<ElevatedButton>(botao).onPressed, isNull);
  });

  testWidgets('com categorias carregadas a publicação fica habilitada', (
    tester,
  ) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: _contratante),
        pedidoRepository: FakePedidoRepository(
          categorias: const [Categoria(id: 'reparos', nome: 'Reparos')],
        ),
        candidaturaRepository: FakeCandidaturaRepository(),
        initialLocation: '/pedidos/novo',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhuma categoria disponível. Tente novamente mais tarde.'),
      findsNothing,
    );
    expect(find.text('Tentar novamente'), findsNothing);

    await tester.dragUntilVisible(
      find.text('Publicar pedido'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    final botao = find.widgetWithText(ElevatedButton, 'Publicar pedido');
    expect(tester.widget<ElevatedButton>(botao).onPressed, isNotNull);
  });
}

const _contratante = Conta(
  uid: 'contratante-1',
  email: 'contratante@example.com',
  nome: 'Ana Silva',
  cidade: 'São Paulo',
  bairro: 'Centro',
  perfil: Perfil.contratante,
);
