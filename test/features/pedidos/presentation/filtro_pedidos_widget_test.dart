import 'package:bicolocal/core/app.dart';
import 'package:bicolocal/features/conta/domain/conta.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:bicolocal/features/pedidos/domain/categoria.dart';
import 'package:bicolocal/features/pedidos/domain/pedido.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes/fake_repositories.dart';

void main() {
  testWidgets('seleciona uma categoria e permite limpar o filtro', (
    tester,
  ) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: _prestador),
        pedidoRepository: FakePedidoRepository(
          categorias: const [
            Categoria(id: 'reparos', nome: 'Reparos'),
            Categoria(id: 'limpeza', nome: 'Limpeza'),
          ],
          pedidos: [_reparo, _limpeza],
        ),
        candidaturaRepository: FakeCandidaturaRepository(),
        initialLocation: '/pedidos',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Montar uma estante'), findsOneWidget);
    expect(find.text('Limpar filtro'), findsNothing);

    await tester.tap(find.byKey(const Key('filtro-categoria')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reparos').last);
    await tester.pumpAndSettle();

    expect(find.text('Montar uma estante'), findsOneWidget);
    expect(find.text('Limpeza da casa'), findsNothing);
    expect(find.text('Limpar filtro'), findsOneWidget);

    await tester.tap(find.text('Limpar filtro'));
    await tester.pumpAndSettle();
    expect(find.text('Montar uma estante'), findsOneWidget);
    expect(find.text('Limpeza da casa'), findsOneWidget);
  });

  testWidgets('categoria sem resultado mostra vazio e permite limpar', (
    tester,
  ) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: _prestador),
        pedidoRepository: FakePedidoRepository(
          categorias: const [
            Categoria(id: 'reparos', nome: 'Reparos'),
            Categoria(id: 'limpeza', nome: 'Limpeza'),
            Categoria(id: 'jardinagem', nome: 'Jardinagem'),
          ],
          pedidos: [_reparo],
        ),
        candidaturaRepository: FakeCandidaturaRepository(),
        initialLocation: '/pedidos',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('filtro-categoria')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jardinagem').last);
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhum pedido aberto para esta cidade e categoria.'),
      findsOneWidget,
    );
    expect(find.text('Limpar filtro'), findsOneWidget);
  });

  testWidgets('busca outra cidade e permite voltar à cidade do perfil', (
    tester,
  ) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: _prestador),
        pedidoRepository: FakePedidoRepository(
          categorias: const [Categoria(id: 'reparos', nome: 'Reparos')],
          pedidos: [_reparo, _campinas],
        ),
        candidaturaRepository: FakeCandidaturaRepository(),
        initialLocation: '/pedidos',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Montar uma estante'), findsOneWidget);
    expect(find.text('Consertar portão'), findsNothing);

    await tester.enterText(find.byKey(const Key('filtro-cidade')), 'Campinas');
    await tester.tap(find.text('Buscar cidade'));
    await tester.pumpAndSettle();

    expect(find.text('Montar uma estante'), findsNothing);
    expect(find.text('Consertar portão'), findsOneWidget);

    await tester.tap(find.text('Minha cidade'));
    await tester.pumpAndSettle();
    expect(find.text('Montar uma estante'), findsOneWidget);
    expect(find.text('Consertar portão'), findsNothing);
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

final _reparo = _pedido(
  id: 'reparo',
  titulo: 'Montar uma estante',
  categoriaId: 'reparos',
  categoriaNome: 'Reparos',
);
final _limpeza = _pedido(
  id: 'limpeza',
  titulo: 'Limpeza da casa',
  categoriaId: 'limpeza',
  categoriaNome: 'Limpeza',
);
final _campinas = Pedido(
  id: 'campinas',
  contratanteUid: 'contratante-2',
  titulo: 'Consertar portão',
  categoriaId: 'reparos',
  categoriaNome: 'Reparos',
  descricao: 'Portão emperrado',
  cidade: 'Campinas',
  local: 'Centro',
  dataDesejada: DateTime.utc(2099, 1, 2),
  validadeAte: DateTime.utc(2099, 1, 1),
  valorCentavos: 15000,
);

Pedido _pedido({
  required String id,
  required String titulo,
  required String categoriaId,
  required String categoriaNome,
}) => Pedido(
  id: id,
  contratanteUid: 'contratante-1',
  titulo: titulo,
  categoriaId: categoriaId,
  categoriaNome: categoriaNome,
  descricao: 'Descrição do pedido',
  cidade: 'São Paulo',
  local: 'Centro',
  dataDesejada: DateTime.utc(2099, 1, 2),
  validadeAte: DateTime.utc(2099, 1, 1),
  valorCentavos: 12000,
);
