import 'package:bicolocal/core/app.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/builders/test_data.dart';
import '../../../support/fakes/fake_repositories.dart';

void main() {
  Future<void> abrir(WidgetTester tester, String caminho) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(),
        pedidoRepository: FakePedidoRepository(),
        candidaturaRepository: FakeCandidaturaRepository(),
        perfilRepository: FakePerfilRepository(),
        avaliacaoRepository: FakeAvaliacaoRepository(),
        seletorFoto: FakeSeletorFoto(foto: criarFotoTeste()),
        initialLocation: caminho,
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final caminho in ['/entrar', '/cadastro']) {
    testWidgets('$caminho mostra o logotipo com nome e lema', (tester) async {
      await abrir(tester, caminho);

      expect(find.byIcon(Icons.handyman), findsOneWidget);
      expect(find.text('BicoLocal'), findsOneWidget);
      expect(find.text('Serviços rápidos perto de você'), findsOneWidget);
    });
  }

  testWidgets('cadastro agrupa os campos em Acesso, Seus dados e Perfil', (
    tester,
  ) async {
    await abrir(tester, '/cadastro');
    final lista = find.byType(ListView);

    expect(find.text('Acesso'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Seus dados'),
      lista,
      const Offset(0, -200),
    );
    expect(find.text('Seus dados'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Perfil'),
      lista,
      const Offset(0, -200),
    );
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets(
    'cadastro mostra cartões de perfil e aviso de escolha definitiva',
    (tester) async {
      await abrir(tester, '/cadastro');
      await tester.dragUntilVisible(
        find.text('Criar conta'),
        find.byType(ListView),
        const Offset(0, -300),
      );

      expect(find.byType(DropdownButtonFormField<Perfil>), findsNothing);
      expect(find.text('Preciso de um serviço'), findsOneWidget);
      expect(find.text('Quero fazer bicos'), findsOneWidget);
      expect(
        find.text('O perfil escolhido não poderá ser alterado depois.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('escolher "Quero fazer bicos" cria conta de prestador', (
    tester,
  ) async {
    await abrir(tester, '/cadastro');
    final lista = find.byType(ListView);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-mail'),
      'bia@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha'),
      'senha-segura',
    );
    for (final (rotulo, valor) in [
      ('Nome', 'Bia Souza'),
      ('Cidade', 'Rio do Sul'),
      ('Bairro', 'Centro'),
    ]) {
      final campo = find.widgetWithText(TextFormField, rotulo);
      await tester.dragUntilVisible(campo, lista, const Offset(0, -150));
      await tester.enterText(campo, valor);
    }
    // A foto é obrigatória no cadastro (FR-016).
    for (final botao in ['Escolher da galeria', 'Usar esta foto']) {
      await tester.dragUntilVisible(
        find.text(botao),
        lista,
        const Offset(0, -150),
      );
      await tester.tap(find.text(botao));
      await tester.pumpAndSettle();
    }
    await tester.dragUntilVisible(
      find.text('Quero fazer bicos'),
      lista,
      const Offset(0, -200),
    );
    await tester.tap(find.text('Quero fazer bicos'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Criar conta'),
      lista,
      const Offset(0, -200),
    );
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('Ver pedidos da minha cidade'), findsOneWidget);
  });
}
