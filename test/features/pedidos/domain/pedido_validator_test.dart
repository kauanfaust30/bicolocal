import 'package:bicolocal/features/pedidos/domain/pedido_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PedidoValidator', () {
    test('aceita pedido válido com validade até a data desejada', () {
      final erros = PedidoValidator.validar(
        titulo: 'Montar uma estante',
        categoriaId: 'reparos',
        descricao: 'Montagem de estante pequena',
        cidade: 'São Paulo',
        local: 'Centro',
        dataDesejada: DateTime.utc(2026, 10, 27),
        validadeAte: DateTime(2026, 10, 26),
        valorCentavos: 12000,
        agoraUtc: DateTime.utc(2026, 10, 26, 15),
      );

      expect(erros, isEmpty);
    });

    test('rejeita campos vazios e valor igual ou menor que zero', () {
      final erros = PedidoValidator.validar(
        titulo: '',
        categoriaId: '',
        descricao: '',
        cidade: '',
        local: '',
        dataDesejada: DateTime.utc(2026, 10, 27),
        validadeAte: DateTime(2026, 10, 26),
        valorCentavos: 0,
        agoraUtc: DateTime.utc(2026, 10, 26, 15),
      );

      expect(
        erros.keys,
        containsAll([
          'titulo',
          'categoriaId',
          'descricao',
          'cidade',
          'local',
          'valorCentavos',
        ]),
      );
    });

    test('rejeita data desejada passada e validade posterior ao serviço', () {
      final erros = PedidoValidator.validar(
        titulo: 'Montar uma estante',
        categoriaId: 'reparos',
        descricao: 'Montagem de estante pequena',
        cidade: 'São Paulo',
        local: 'Centro',
        dataDesejada: DateTime.utc(2026, 10, 25),
        validadeAte: DateTime(2026, 10, 27),
        valorCentavos: 12000,
        agoraUtc: DateTime.utc(2026, 10, 26, 15),
      );

      expect(erros.keys, containsAll(['dataDesejada', 'validadeAte']));
    });

    test('considera a virada do dia em São Paulo às 03:00 UTC', () {
      final antesDaMeiaNoite = _validarDatas(
        agoraUtc: DateTime.utc(2026, 10, 27, 2, 59, 59),
        validadeAte: DateTime(2026, 10, 26),
      );
      final noInicioDoDiaSeguinte = _validarDatas(
        agoraUtc: DateTime.utc(2026, 10, 27, 3),
        validadeAte: DateTime(2026, 10, 26),
      );

      expect(antesDaMeiaNoite, isNot(contains('validadeAte')));
      expect(noInicioDoDiaSeguinte, contains('validadeAte'));
    });
  });
}

Map<String, String> _validarDatas({
  required DateTime agoraUtc,
  required DateTime validadeAte,
}) {
  return PedidoValidator.validar(
    titulo: 'Montar uma estante',
    categoriaId: 'reparos',
    descricao: 'Montagem de estante pequena',
    cidade: 'São Paulo',
    local: 'Centro',
    dataDesejada: DateTime.utc(2026, 10, 27),
    validadeAte: validadeAte,
    valorCentavos: 12000,
    agoraUtc: agoraUtc,
  );
}
