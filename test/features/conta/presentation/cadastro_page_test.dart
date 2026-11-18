import 'package:bicolocal/core/app.dart';
import 'package:bicolocal/features/conta/domain/conta.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:bicolocal/features/perfil/domain/foto_erro.dart';
import 'package:bicolocal/features/perfil/domain/foto_perfil.dart';

import '../../../support/builders/test_data.dart';
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
        perfilRepository: FakePerfilRepository(),
        avaliacaoRepository: FakeAvaliacaoRepository(),
        seletorFoto: FakeSeletorFoto(),
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

  group('foto no cadastro (FR-016, FR-017, FR-021, FR-022)', () {
    const falhaEnvio =
        'Não foi possível enviar sua foto. Seus dados continuam preenchidos. '
        'Verifique a conexão e toque em Criar conta de novo.';

    testWidgets('sem foto o cadastro não é concluído', (tester) async {
      final contas = FakeContaRepository();
      await _abrirCadastroPreenchido(
        tester,
        contas: contas,
        seletor: FakeSeletorFoto(foto: criarFotoTeste()),
      );

      await _criarConta(tester);

      expect(contas.contaInicial, isNull);
      await tester.dragUntilVisible(
        find.text('Adicione uma foto para concluir o cadastro.'),
        find.byType(ListView),
        const Offset(0, 100),
      );
      expect(
        find.text('Adicione uma foto para concluir o cadastro.'),
        findsOneWidget,
      );
    });

    testWidgets('galeria mostra prévia e, confirmada, a conta é criada', (
      tester,
    ) async {
      final contas = FakeContaRepository();
      await _abrirCadastroPreenchido(
        tester,
        contas: contas,
        seletor: FakeSeletorFoto(foto: criarFotoTeste()),
      );

      await _tocar(tester, find.text('Escolher da galeria'));
      expect(find.text('Usar esta foto'), findsOneWidget);
      expect(find.text('Escolher outra'), findsOneWidget);
      await _tocar(tester, find.text('Usar esta foto'));
      expect(find.bySemanticsLabel('Foto de Ana Silva'), findsOneWidget);

      await _criarConta(tester);

      expect(contas.fotoCadastrada, isNotNull);
      expect(find.text('Olá, Ana Silva'), findsOneWidget);
    });

    testWidgets('cancelar a escolha mantém os dados preenchidos', (
      tester,
    ) async {
      await _abrirCadastroPreenchido(
        tester,
        contas: FakeContaRepository(),
        seletor: FakeSeletorFoto(),
      );

      await _tocar(tester, find.text('Tirar foto'));

      expect(find.text('Usar esta foto'), findsNothing);
      await tester.dragUntilVisible(
        find.text('Ana Silva'),
        find.byType(ListView),
        const Offset(0, 100),
      );
      expect(find.text('Ana Silva'), findsOneWidget);
    });

    testWidgets('câmera negada explica e oferece a galeria', (tester) async {
      await _abrirCadastroPreenchido(
        tester,
        contas: FakeContaRepository(),
        seletor: FakeSeletorFoto(
          erro: FotoErro.semPermissao(OrigemFoto.camera),
        ),
      );

      await _tocar(tester, find.text('Tirar foto'));

      expect(
        find.text(
          'Não conseguimos acessar a câmera. Permita o acesso nas '
          'configurações do celular ou escolha uma foto da galeria.',
        ),
        findsOneWidget,
      );
      expect(find.text('Escolher da galeria'), findsOneWidget);
    });

    for (final (mensagem, erro) in [
      ('Esse arquivo não é uma foto. Escolha uma imagem.', FotoErro.naoImagem),
      ('Essa foto ficou grande demais. Escolha outra.', FotoErro.grandeDemais),
    ]) {
      testWidgets('mostra "$mensagem"', (tester) async {
        await _abrirCadastroPreenchido(
          tester,
          contas: FakeContaRepository(),
          seletor: FakeSeletorFoto(erro: erro),
        );

        await _tocar(tester, find.text('Escolher da galeria'));

        expect(find.text(mensagem), findsOneWidget);
      });
    }

    testWidgets('falha no envio mantém os dados e explica o que fazer', (
      tester,
    ) async {
      final contas = FakeContaRepository()..falharFotoNoCadastro = true;
      await _abrirCadastroPreenchido(
        tester,
        contas: contas,
        seletor: FakeSeletorFoto(foto: criarFotoTeste()),
      );
      await _tocar(tester, find.text('Escolher da galeria'));
      await _tocar(tester, find.text('Usar esta foto'));

      await _criarConta(tester);

      expect(contas.contaInicial, isNull);
      expect(find.text(falhaEnvio), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('ana@example.com'),
        find.byType(ListView),
        const Offset(0, 100),
      );
      expect(find.text('ana@example.com'), findsOneWidget);
    });
  });

  testWidgets('entrada vazia mostra erros junto aos campos', (tester) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(),
        pedidoRepository: FakePedidoRepository(),
        candidaturaRepository: FakeCandidaturaRepository(),
        perfilRepository: FakePerfilRepository(),
        avaliacaoRepository: FakeAvaliacaoRepository(),
        seletorFoto: FakeSeletorFoto(),
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
        perfilRepository: FakePerfilRepository(),
        avaliacaoRepository: FakeAvaliacaoRepository(),
        seletorFoto: FakeSeletorFoto(),
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
        perfilRepository: FakePerfilRepository(),
        avaliacaoRepository: FakeAvaliacaoRepository(),
        seletorFoto: FakeSeletorFoto(),
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
          perfilRepository: FakePerfilRepository(),
          avaliacaoRepository: FakeAvaliacaoRepository(),
          seletorFoto: FakeSeletorFoto(),
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

/// Abre o cadastro, preenche os campos de texto e escolhe o perfil.
Future<void> _abrirCadastroPreenchido(
  WidgetTester tester, {
  required FakeContaRepository contas,
  required FakeSeletorFoto seletor,
}) async {
  await tester.pumpWidget(
    BicoLocalApp(
      contaRepository: contas,
      pedidoRepository: FakePedidoRepository(),
      candidaturaRepository: FakeCandidaturaRepository(),
      perfilRepository: FakePerfilRepository(),
      avaliacaoRepository: FakeAvaliacaoRepository(),
      seletorFoto: seletor,
      initialLocation: '/cadastro',
    ),
  );
  await tester.pumpAndSettle();
  for (final (rotulo, valor) in [
    ('E-mail', 'ana@example.com'),
    ('Senha', 'senha-segura'),
    ('Nome', 'Ana Silva'),
    ('Cidade', 'Rio do Sul'),
    ('Bairro', 'Centro'),
  ]) {
    final campo = find.widgetWithText(TextFormField, rotulo);
    await tester.dragUntilVisible(
      campo,
      find.byType(ListView),
      const Offset(0, -100),
    );
    await tester.enterText(campo, valor);
  }
  await _tocar(tester, find.text('Quero fazer bicos'));
}

Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  // Volta ao topo e desce até o alvo: ele pode estar acima ou abaixo.
  await tester.drag(find.byType(ListView), const Offset(0, 5000));
  await tester.pumpAndSettle();
  await tester.dragUntilVisible(
    alvo,
    find.byType(ListView),
    const Offset(0, -100),
  );
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

Future<void> _criarConta(WidgetTester tester) =>
    _tocar(tester, find.text('Criar conta'));

const _contratante = Conta(
  uid: 'conta-1',
  email: 'ana@example.com',
  nome: 'Ana Silva',
  cidade: 'São Paulo',
  bairro: 'Centro',
  perfil: Perfil.contratante,
);
