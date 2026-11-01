import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Firebase configura índice composto para listar pedidos por cidade e validade', () {
    final firebase = jsonDecode(
      File('firebase.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final indexesPath = firebase['firestore']['indexes'] as String;
    final indexes = jsonDecode(
      File(indexesPath).readAsStringSync(),
    ) as Map<String, dynamic>;
    final encontrados = (indexes['indexes'] as List<dynamic>).where((indice) {
      final item = indice as Map<String, dynamic>;
      if (item['collectionGroup'] != 'requests' ||
          item['queryScope'] != 'COLLECTION') {
        return false;
      }
      final campos = (item['fields'] as List<dynamic>)
          .map((campo) => (campo as Map<String, dynamic>)['fieldPath'])
          .toSet();
      return campos.containsAll(['estado', 'cidadeChave', 'validadeAteDia']);
    });

    expect(encontrados, isNotEmpty);
  });

  test(
    'Firebase configura índice composto para filtrar pedidos por categoria',
    () {
      final firebase = jsonDecode(
        File('firebase.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final indexesPath = firebase['firestore']['indexes'] as String;
      final indexes = jsonDecode(
        File(indexesPath).readAsStringSync(),
      ) as Map<String, dynamic>;
      final encontrados = (indexes['indexes'] as List<dynamic>).where((indice) {
        final item = indice as Map<String, dynamic>;
        if (item['collectionGroup'] != 'requests' ||
            item['queryScope'] != 'COLLECTION') {
          return false;
        }
        final campos = (item['fields'] as List<dynamic>)
            .map((campo) => (campo as Map<String, dynamic>)['fieldPath'])
            .toSet();
        return campos.containsAll([
          'estado',
          'cidadeChave',
          'categoriaId',
          'validadeAteDia',
        ]);
      });

      expect(encontrados, isNotEmpty);
    },
  );
}
