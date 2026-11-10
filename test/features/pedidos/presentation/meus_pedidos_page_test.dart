import 'package:bicolocal/core/app.dart';
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
}
