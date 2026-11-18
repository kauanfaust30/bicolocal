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
    nome: 'Ana Contratante',
    perfil: Perfil.contratante,
  );
  final concluido =
      criarPedidoTeste(
        id: 'p1',
        contratanteUid: contratante.uid,
        dataDesejada: DateTime.utc(2099, 11, 6),
        validadeAte: DateTime.utc(2099, 11, 5),
      ).copyWith(
        estado: EstadoPedido.concluido,
        prestadorEscolhidoUid: 'prestador-1',
      );

  Future<FakeAvaliacaoRepository> abrir(
    WidgetTester tester, {
    Conta? conta,
    Pedido? pedido,
  }) async {
    final avaliacoes = FakeAvaliacaoRepository();
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(
          contaInicial: conta ?? contratante,
        ),
        pedidoRepository: FakePedidoRepository(pedidos: [pedido ?? concluido]),
        candidaturaRepository: FakeCandidaturaRepository(),
        perfilRepository: FakePerfilRepository(
          perfis: {
            'prestador-1': criarPerfilTeste(
              uid: 'prestador-1',
              nome: 'Bruno Prestador',
            ),
          },
        ),
        avaliacaoRepository: avaliacoes,
        seletorFoto: FakeSeletorFoto(),
        initialLocation: '/pedidos/p1/avaliar',
      ),
    );
    await tester.pumpAndSettle();
    return avaliacoes;
  }

  Future<void> enviar(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Enviar avaliação'));
    await tester.pump();
    await tester.tap(find.text('Enviar avaliação'));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra a outra parte, as estrelas, o contador e o aviso', (
    tester,
  ) async {
    await abrir(tester);

    expect(find.text('Bruno Prestador'), findsOneWidget);
    for (final rotulo in [
      '1 estrela',
      '2 estrelas',
      '3 estrelas',
      '4 estrelas',
      '5 estrelas',
    ]) {
      expect(find.byTooltip(rotulo), findsOneWidget);
    }
    expect(find.text('0/300'), findsOneWidget);
    expect(
      find.text('A avaliação não pode ser editada depois.'),
      findsOneWidget,
    );
  });

  testWidgets('estrelas têm alvo de toque de pelo menos 48 dp', (tester) async {
    await abrir(tester);

    final tamanho = tester.getSize(find.byTooltip('3 estrelas'));
    expect(tamanho.width, greaterThanOrEqualTo(48));
    expect(tamanho.height, greaterThanOrEqualTo(48));
  });

  testWidgets('contador acompanha o comentário', (tester) async {
    await abrir(tester);

    await tester.enterText(find.byType(TextField), 'Muito bom');
    await tester.pump();

    expect(find.text('9/300'), findsOneWidget);
  });

  testWidgets('sem nota mostra o erro e não registra', (tester) async {
    final avaliacoes = await abrir(tester);

    await enviar(tester);

    expect(find.text('Escolha uma nota de 1 a 5.'), findsOneWidget);
    expect(avaliacoes.avaliacoes, isEmpty);
  });

  testWidgets('comentário acima de 300 caracteres mostra o erro', (
    tester,
  ) async {
    final avaliacoes = await abrir(tester);

    await tester.tap(find.byTooltip('5 estrelas'));
    await tester.enterText(find.byType(TextField), 'a' * 301);
    await enviar(tester);

    expect(
      find.text('O comentário pode ter até 300 caracteres.'),
      findsOneWidget,
    );
    expect(avaliacoes.avaliacoes, isEmpty);
  });

  testWidgets('falha preserva nota e comentário', (tester) async {
    final avaliacoes = await abrir(tester);
    avaliacoes.falharProximoEnvio = true;

    await tester.tap(find.byTooltip('4 estrelas'));
    await tester.enterText(find.byType(TextField), 'Pontual');
    await enviar(tester);

    expect(
      find.text(
        'Não foi possível enviar a avaliação. Sua nota e seu comentário '
        'continuam aqui. Tente de novo.',
      ),
      findsOneWidget,
    );
    expect(find.text('Pontual'), findsOneWidget);

    await enviar(tester);

    expect(avaliacoes.avaliacoes.single.nota, 4);
    expect(avaliacoes.avaliacoes.single.comentario, 'Pontual');
  });

  testWidgets('toque duplo gera uma só avaliação', (tester) async {
    final avaliacoes = await abrir(tester);

    await tester.tap(find.byTooltip('5 estrelas'));
    await tester.pump();
    await tester.ensureVisible(find.text('Enviar avaliação'));
    await tester.pump();
    await tester.tap(find.text('Enviar avaliação'));
    await tester.tap(find.text('Enviar avaliação'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(avaliacoes.avaliacoes, hasLength(1));
  });

  testWidgets('depois de enviar, o pedido mostra "Você já avaliou"', (
    tester,
  ) async {
    await abrir(tester);

    await tester.tap(find.byTooltip('5 estrelas'));
    await enviar(tester);

    expect(find.text('Meus pedidos'), findsOneWidget);
    expect(find.text('Você já avaliou'), findsOneWidget);
    expect(find.text('Avaliar'), findsNothing);
  });

  testWidgets('quem não é parte vai para o início', (tester) async {
    await abrir(tester, conta: criarContaTeste(uid: 'outra-pessoa'));

    expect(find.text('Enviar avaliação'), findsNothing);
    expect(find.text('Meu perfil'), findsOneWidget);
  });

  testWidgets('pedido não concluído vai para o início', (tester) async {
    await abrir(
      tester,
      pedido: concluido.copyWith(estado: EstadoPedido.emAndamento),
    );

    expect(find.text('Enviar avaliação'), findsNothing);
    expect(find.text('Meu perfil'), findsOneWidget);
  });
}
