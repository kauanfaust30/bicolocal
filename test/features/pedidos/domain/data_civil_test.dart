import 'package:bicolocal/features/pedidos/domain/data_civil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converte a data civil em início do dia UTC para consulta Firestore', () {
    expect(
      DataCivil.inicioDiaUtc('2026-10-28'),
      DateTime.utc(2026, 10, 28),
    );
  });
}
