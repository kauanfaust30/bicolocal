import 'dart:convert';
import 'dart:io';

import 'package:bicolocal/features/pedidos/data/consulta_pedidos_abertos.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('consulta de pedidos abertos por cidade', () {
    test('sem categoria filtra estado, cidade e validade a partir de hoje', () {
      final filtros = ConsultaPedidosAbertos.filtros(
        cidade: '  Rio do Sul ',
        dataCivil: '2026-11-09',
      );

      expect(filtros, [
        const FiltroConsulta.igual('estado', 'aberto'),
        const FiltroConsulta.igual('cidadeChave', 'rio do sul'),
        FiltroConsulta.maiorOuIgual(
          'validadeAteDia',
          Timestamp.fromDate(DateTime.utc(2026, 11, 9)),
        ),
      ]);
    });

    test('com categoria acrescenta a igualdade de categoriaId', () {
      final filtros = ConsultaPedidosAbertos.filtros(
        cidade: 'Rio do Sul',
        dataCivil: '2026-11-09',
        categoriaId: 'limpeza',
      );

      expect(
        filtros,
        contains(const FiltroConsulta.igual('categoriaId', 'limpeza')),
      );
      expect(filtros.first, const FiltroConsulta.igual('estado', 'aberto'));
      expect(filtros.length, 4);
    });

    test('ordena pelo campo de intervalo, sem limite', () {
      expect(ConsultaPedidosAbertos.campoOrdenacao, 'validadeAteDia');
    });

    for (final categoriaId in [null, 'limpeza']) {
      test('firestore.indexes.json tem índice composto para a consulta '
          '${categoriaId == null ? 'sem' : 'com'} categoria', () {
        final filtros = ConsultaPedidosAbertos.filtros(
          cidade: 'Rio do Sul',
          dataCivil: '2026-11-09',
          categoriaId: categoriaId,
        );
        final igualdades = filtros
            .where((filtro) => filtro.operador == OperadorFiltro.igual)
            .map((filtro) => filtro.campo)
            .toSet();
        final intervalo = filtros
            .singleWhere(
              (filtro) => filtro.operador == OperadorFiltro.maiorOuIgual,
            )
            .campo;

        final indices =
            (jsonDecode(File('firestore.indexes.json').readAsStringSync())
                    as Map<String, dynamic>)['indexes']
                as List<dynamic>;
        final encontrado = indices.cast<Map<String, dynamic>>().any((indice) {
          if (indice['collectionGroup'] != 'requests' ||
              indice['queryScope'] != 'COLLECTION') {
            return false;
          }
          final campos = (indice['fields'] as List<dynamic>)
              .map((campo) => (campo as Map<String, dynamic>)['fieldPath'])
              .toList();
          // Igualdades primeiro (em qualquer ordem) e o intervalo por último.
          return campos.length == igualdades.length + 1 &&
              campos.last == intervalo &&
              campos.take(igualdades.length).toSet().containsAll(igualdades);
        });

        expect(encontrado, isTrue);
      });
    }
  });
}
