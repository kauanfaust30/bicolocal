import 'package:bicolocal/core/app.dart';
import 'package:bicolocal/features/conta/domain/conta.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:bicolocal/features/pedidos/domain/categoria.dart';
import 'package:bicolocal/features/pedidos/domain/pedido.dart';
import 'package:flutter/material.dart';

import '../../../support/fakes/fake_repositories.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('lista vazia informa que não há pedidos disponíveis', (
    tester,
  ) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: _prestador),
        pedidoRepository: FakePedidoRepository(),
        candidaturaRepository: FakeCandidaturaRepository(),
        initialLocation: '/pedidos',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhum pedido aberto na sua cidade.'), findsOneWidget);
  });

  testWidgets('falha oferece nova tentativa e recupera lista vazia', (
    tester,
  ) async {
    final repositorio = FakePedidoRepository(falhasRestantes: 1);
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: _prestador),
        pedidoRepository: repositorio,
        candidaturaRepository: FakeCandidaturaRepository(),
        initialLocation: '/pedidos',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar os pedidos.'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum pedido aberto na sua cidade.'), findsOneWidget);
  });

  testWidgets('cartão apresenta os dados necessários para avaliar pedido', (
    tester,
  ) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: _prestador),
        pedidoRepository: FakePedidoRepository(pedidos: [_pedido]),
        candidaturaRepository: FakeCandidaturaRepository(),
        initialLocation: '/pedidos',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Montar uma estante'), findsOneWidget);
    expect(find.text('Reparos'), findsOneWidget);
    expect(find.text('Montagem de estante pequena'), findsOneWidget);
    expect(find.text('Local: Centro'), findsOneWidget);
    expect(find.text('R\$ 120,00'), findsOneWidget);
  });

  testWidgets('formulário de publicação contém os campos da spec', (
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

    expect(find.text('Novo pedido'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
    expect(find.text('Categoria'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Data desejada'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Data desejada'), findsOneWidget);
    expect(find.text('Validade até'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Publicar pedido'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Publicar pedido'), findsOneWidget);
  });
}

const _prestador = Conta(
  uid: 'prestador-1',
  email: 'prestador@example.com',
  nome: 'João Silva',
  cidade: 'São Paulo',
  bairro: 'Centro',
  perfil: Perfil.prestador,
);

const _contratante = Conta(
  uid: 'contratante-1',
  email: 'contratante@example.com',
  nome: 'Ana Silva',
  cidade: 'São Paulo',
  bairro: 'Centro',
  perfil: Perfil.contratante,
);

final _pedido = Pedido(
  id: 'pedido-1',
  contratanteUid: 'contratante-1',
  titulo: 'Montar uma estante',
  categoriaId: 'reparos',
  categoriaNome: 'Reparos',
  descricao: 'Montagem de estante pequena',
  cidade: 'São Paulo',
  local: 'Centro',
  dataDesejada: DateTime.utc(2099, 1, 2),
  validadeAte: DateTime.utc(2099, 1, 1),
  valorCentavos: 12000,
);
