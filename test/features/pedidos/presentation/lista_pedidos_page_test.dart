import 'package:bicolocal/core/app.dart';
import 'package:bicolocal/features/conta/domain/conta.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:bicolocal/features/pedidos/domain/categoria.dart';
import 'package:bicolocal/features/pedidos/domain/pedido.dart';
import 'package:flutter/material.dart';

import '../../../support/builders/test_data.dart';
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
        perfilRepository: FakePerfilRepository(),
        avaliacaoRepository: FakeAvaliacaoRepository(),
        seletorFoto: FakeSeletorFoto(),
        initialLocation: '/pedidos',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhum pedido por aqui ainda.'), findsOneWidget);
    expect(find.text('Tente outra cidade ou categoria.'), findsOneWidget);
    expect(find.byKey(const Key('ilustracao-estado')), findsOneWidget);
  });

  testWidgets('enquanto carrega mostra ilustração e texto amigável', (
    tester,
  ) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: _prestador),
        pedidoRepository: FakePedidoRepository(),
        candidaturaRepository: FakeCandidaturaRepository(),
        perfilRepository: FakePerfilRepository(),
        avaliacaoRepository: FakeAvaliacaoRepository(),
        seletorFoto: FakeSeletorFoto(),
        initialLocation: '/pedidos',
      ),
    );

    expect(find.text('Buscando pedidos perto de você…'), findsOneWidget);
    await tester.pumpAndSettle();
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
        perfilRepository: FakePerfilRepository(),
        avaliacaoRepository: FakeAvaliacaoRepository(),
        seletorFoto: FakeSeletorFoto(),
        initialLocation: '/pedidos',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar os pedidos.'), findsOneWidget);
    expect(find.byKey(const Key('ilustracao-estado')), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum pedido por aqui ainda.'), findsOneWidget);
  });

  testWidgets('cartão apresenta os dados necessários para avaliar pedido', (
    tester,
  ) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: _prestador),
        pedidoRepository: FakePedidoRepository(pedidos: [_pedido]),
        candidaturaRepository: FakeCandidaturaRepository(),
        perfilRepository: FakePerfilRepository(),
        avaliacaoRepository: FakeAvaliacaoRepository(),
        seletorFoto: FakeSeletorFoto(),
        initialLocation: '/pedidos',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Montar uma estante'), findsOneWidget);
    expect(find.text('Reparos'), findsOneWidget);
    expect(find.text('Montagem de estante pequena'), findsOneWidget);
    expect(find.text('Local: Centro'), findsOneWidget);
    expect(find.text('R\$ 120,00'), findsOneWidget);

    Finder noCartao(Finder alvo) =>
        find.descendant(of: find.byType(Card), matching: alvo);
    expect(noCartao(find.byIcon(Icons.home_repair_service)), findsOneWidget);
    expect(noCartao(find.text('São Paulo')), findsOneWidget);
    expect(noCartao(find.text('Válido até 01/01/2099')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('estado-pedido-1')),
        matching: find.text('Aberto'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('"Ver contratante" abre o perfil do contratante (FR-014)', (
    tester,
  ) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: _prestador),
        pedidoRepository: FakePedidoRepository(pedidos: [_pedido]),
        candidaturaRepository: FakeCandidaturaRepository(),
        perfilRepository: FakePerfilRepository(
          perfis: {
            _pedido.contratanteUid: criarPerfilTeste(
              uid: _pedido.contratanteUid,
              nome: 'Marta Contratante',
              perfil: Perfil.contratante,
            ),
          },
        ),
        avaliacaoRepository: FakeAvaliacaoRepository(),
        seletorFoto: FakeSeletorFoto(),
        initialLocation: '/pedidos',
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Ver contratante'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver contratante'));
    await tester.pumpAndSettle();

    expect(find.text('Marta Contratante'), findsOneWidget);
    expect(find.text('Contratante'), findsOneWidget);
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
        perfilRepository: FakePerfilRepository(),
        avaliacaoRepository: FakeAvaliacaoRepository(),
        seletorFoto: FakeSeletorFoto(),
        initialLocation: '/pedidos/novo',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Novo pedido'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
    expect(find.text('Categoria'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Data desejada'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    expect(find.text('Data desejada'), findsOneWidget);
    expect(find.text('Validade até'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Publicar pedido'),
      find.byType(ListView),
      const Offset(0, -300),
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
