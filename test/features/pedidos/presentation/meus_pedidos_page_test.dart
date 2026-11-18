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
    perfil: Perfil.contratante,
  );

  Future<void> abrir(WidgetTester tester, List<Pedido> pedidos) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: contratante),
        pedidoRepository: FakePedidoRepository(pedidos: pedidos),
        candidaturaRepository: FakeCandidaturaRepository(),
        perfilRepository: FakePerfilRepository(),
        avaliacaoRepository: FakeAvaliacaoRepository(),
        seletorFoto: FakeSeletorFoto(),
        initialLocation: '/meus-pedidos',
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('cartão mostra categoria, valor, cidade, validade e estado', (
    tester,
  ) async {
    await abrir(tester, [
      criarPedidoTeste(
        id: 'p1',
        contratanteUid: contratante.uid,
        titulo: 'Pintar a sala',
        categoriaId: 'pintura',
        categoriaNome: 'Pintura',
        cidade: 'Rio do Sul',
        valorCentavos: 15000,
        dataDesejada: DateTime.utc(2099, 11, 6),
        validadeAte: DateTime.utc(2099, 11, 5),
      ),
      criarPedidoTeste(
        id: 'p2',
        contratanteUid: contratante.uid,
        titulo: 'Limpar o quintal',
        categoriaId: 'limpeza',
        categoriaNome: 'Limpeza',
        dataDesejada: DateTime.utc(2099, 11, 6),
        validadeAte: DateTime.utc(2099, 11, 5),
      ).copyWith(estado: EstadoPedido.cancelado),
    ]);

    expect(find.text('Pintar a sala'), findsOneWidget);
    expect(find.byIcon(Icons.format_paint), findsOneWidget);
    expect(find.text('R\$ 150,00'), findsOneWidget);
    expect(find.text('Rio do Sul'), findsOneWidget);
    expect(find.text('Válido até 05/11/2099'), findsNWidgets(2));
    expect(find.byKey(const Key('estado-p1')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('estado-p1')),
        matching: find.text('Aberto'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('estado-p2')),
        matching: find.text('Cancelado'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('sem pedidos mostra ilustração e texto amigável', (tester) async {
    await abrir(tester, const []);

    expect(find.text('Você ainda não tem pedidos.'), findsOneWidget);
    expect(find.byKey(const Key('ilustracao-estado')), findsOneWidget);
  });

  group('concluir e avaliar (FR-001, FR-007)', () {
    final prestador = criarContaTeste(uid: 'prestador-1');
    final emAndamento =
        criarPedidoTeste(
          id: 'p1',
          contratanteUid: contratante.uid,
          dataDesejada: DateTime.utc(2099, 11, 6),
          validadeAte: DateTime.utc(2099, 11, 5),
        ).copyWith(
          estado: EstadoPedido.emAndamento,
          prestadorEscolhidoUid: prestador.uid,
        );
    final concluido = emAndamento.copyWith(estado: EstadoPedido.concluido);

    Future<void> abrirComo(
      WidgetTester tester,
      Conta conta,
      Pedido pedido, {
      Set<String> avaliadas = const {},
    }) async {
      // Desmonta o app anterior para a nova conta começar do zero.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        BicoLocalApp(
          contaRepository: FakeContaRepository(contaInicial: conta),
          pedidoRepository: FakePedidoRepository(pedidos: [pedido]),
          candidaturaRepository: FakeCandidaturaRepository(),
          perfilRepository: FakePerfilRepository(),
          avaliacaoRepository: FakeAvaliacaoRepository()
            ..avaliadas.addAll(avaliadas),
          seletorFoto: FakeSeletorFoto(),
          initialLocation: '/meus-pedidos',
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('em andamento, só o contratante vê "Concluir pedido"', (
      tester,
    ) async {
      await abrirComo(tester, contratante, emAndamento);
      expect(find.text('Concluir pedido'), findsOneWidget);

      await abrirComo(tester, prestador, emAndamento);
      expect(find.text('Concluir pedido'), findsNothing);
    });

    testWidgets('concluído mostra "Avaliar" às duas partes', (tester) async {
      await abrirComo(tester, contratante, concluido);
      expect(find.text('Avaliar'), findsOneWidget);
      expect(find.text('Concluir pedido'), findsNothing);

      await abrirComo(tester, prestador, concluido);
      expect(find.text('Avaliar'), findsOneWidget);
    });

    testWidgets('quem já avaliou vê "Você já avaliou"; a outra parte não', (
      tester,
    ) async {
      // O contratante avaliou o prestador neste pedido.
      const avaliadas = {'p1:prestador-1'};

      await abrirComo(tester, contratante, concluido, avaliadas: avaliadas);
      expect(find.text('Você já avaliou'), findsOneWidget);
      expect(find.text('Avaliar'), findsNothing);

      await abrirComo(tester, prestador, concluido, avaliadas: avaliadas);
      expect(find.text('Avaliar'), findsOneWidget);
      expect(find.text('Você já avaliou'), findsNothing);
    });

    testWidgets('"Avaliar" abre a tela de avaliação', (tester) async {
      await abrirComo(tester, contratante, concluido);

      await tester.tap(find.text('Avaliar'));
      await tester.pumpAndSettle();

      expect(find.text('Enviar avaliação'), findsOneWidget);
    });
  });
}
