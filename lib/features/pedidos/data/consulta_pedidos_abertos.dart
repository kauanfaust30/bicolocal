import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/data_civil.dart';

enum OperadorFiltro { igual, maiorOuIgual }

/// Um filtro `where` da consulta, descrito sem depender do Firestore real.
class FiltroConsulta {
  const FiltroConsulta.igual(this.campo, this.valor)
    : operador = OperadorFiltro.igual;

  const FiltroConsulta.maiorOuIgual(this.campo, this.valor)
    : operador = OperadorFiltro.maiorOuIgual;

  final String campo;
  final OperadorFiltro operador;
  final Object valor;

  @override
  bool operator ==(Object other) =>
      other is FiltroConsulta &&
      other.campo == campo &&
      other.operador == operador &&
      other.valor == valor;

  @override
  int get hashCode => Object.hash(campo, operador, valor);

  @override
  String toString() => 'where($campo ${operador.name} $valor)';
}

/// Consulta da tela "Pedidos por cidade".
///
/// A regra `allow list` de `requests` só libera a listagem para o prestador
/// quando a consulta garante `estado == 'aberto'` e validade a partir de hoje,
/// por isso esses filtros são obrigatórios. Cada combinação precisa do índice
/// composto correspondente em `firestore.indexes.json`.
abstract final class ConsultaPedidosAbertos {
  static const campoOrdenacao = 'validadeAteDia';

  static List<FiltroConsulta> filtros({
    required String cidade,
    required String dataCivil,
    String? categoriaId,
  }) => [
    const FiltroConsulta.igual('estado', 'aberto'),
    FiltroConsulta.igual('cidadeChave', cidade.trim().toLowerCase()),
    if (categoriaId != null) FiltroConsulta.igual('categoriaId', categoriaId),
    FiltroConsulta.maiorOuIgual(
      'validadeAteDia',
      Timestamp.fromDate(DataCivil.inicioDiaUtc(dataCivil)),
    ),
  ];

  static Query<Map<String, dynamic>> aplicar(
    Query<Map<String, dynamic>> base,
    List<FiltroConsulta> filtros,
  ) {
    var consulta = base;
    for (final filtro in filtros) {
      consulta = switch (filtro.operador) {
        OperadorFiltro.igual => consulta.where(
          filtro.campo,
          isEqualTo: filtro.valor,
        ),
        OperadorFiltro.maiorOuIgual => consulta.where(
          filtro.campo,
          isGreaterThanOrEqualTo: filtro.valor,
        ),
      };
    }
    return consulta.orderBy(campoOrdenacao);
  }
}
