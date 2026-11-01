import 'package:bicolocal/features/pedidos/domain/categoria.dart';
import 'package:bicolocal/features/pedidos/domain/pedido.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes/fake_repositories.dart';

void main() {
  late FakePedidoRepository repositorio;

  setUp(() {
    repositorio = FakePedidoRepository(
      pedidos: [_reparo, _limpeza, _outraCidade],
    );
  });

  test('consulta por categoria mantém cidade e validade', () async {
    final resultado = await repositorio.listarAbertos(
      cidade: 'São Paulo',
      dataCivil: '2099-01-01',
      categoriaId: 'reparos',
    );

    expect(resultado.map((pedido) => pedido.id), ['reparo']);
  });

  test(
    'consulta sem categoria retorna todas as categorias da cidade',
    () async {
      final resultado = await repositorio.listarAbertos(
        cidade: 'São Paulo',
        dataCivil: '2099-01-01',
        categoriaId: null,
      );

      expect(resultado.map((pedido) => pedido.id), ['reparo', 'limpeza']);
    },
  );

  test(
    'consulta aceita cidade diferente e continua filtrando categoria',
    () async {
      final resultado = await repositorio.listarAbertos(
        cidade: 'Campinas',
        dataCivil: '2099-01-01',
        categoriaId: 'reparos',
      );

      expect(resultado.map((pedido) => pedido.id), ['outra-cidade']);
    },
  );
}

const _reparos = Categoria(id: 'reparos', nome: 'Reparos');

final _reparo = _pedido(id: 'reparo', cidade: 'São Paulo', categoria: _reparos);
final _limpeza = _pedido(
  id: 'limpeza',
  cidade: 'São Paulo',
  categoria: const Categoria(id: 'limpeza', nome: 'Limpeza'),
);
final _outraCidade = _pedido(
  id: 'outra-cidade',
  cidade: 'Campinas',
  categoria: _reparos,
);

Pedido _pedido({
  required String id,
  required String cidade,
  required Categoria categoria,
}) => Pedido(
  id: id,
  contratanteUid: 'contratante',
  titulo: id,
  categoriaId: categoria.id,
  categoriaNome: categoria.nome,
  descricao: 'Descrição',
  cidade: cidade,
  local: 'Centro',
  dataDesejada: DateTime.utc(2099, 1, 3),
  validadeAte: DateTime.utc(2099, 1, 2),
  valorCentavos: 10000,
);
