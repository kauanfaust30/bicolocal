import 'package:bicolocal/features/conta/domain/contact_access_policy.dart';
import 'package:bicolocal/features/pedidos/domain/pedido.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'contatos só aparecem às partes enquanto o pedido está em andamento',
    () {
      final pedido = _pedido();

      expect(
        ContactAccessPolicy.podeLerContato(
          pedido: pedido,
          leitorUid: 'contratante-1',
          donoContatoUid: 'prestador-1',
        ),
        isTrue,
      );
      expect(
        ContactAccessPolicy.podeLerContato(
          pedido: pedido,
          leitorUid: 'prestador-1',
          donoContatoUid: 'contratante-1',
        ),
        isTrue,
      );
      expect(
        ContactAccessPolicy.podeLerContato(
          pedido: pedido,
          leitorUid: 'outro',
          donoContatoUid: 'prestador-1',
        ),
        isFalse,
      );
      expect(
        ContactAccessPolicy.podeLerContato(
          pedido: _pedido(estado: EstadoPedido.cancelado),
          leitorUid: 'contratante-1',
          donoContatoUid: 'prestador-1',
        ),
        isFalse,
      );
      expect(
        ContactAccessPolicy.podeLerContato(
          pedido: _pedido(estado: EstadoPedido.aberto),
          leitorUid: 'contratante-1',
          donoContatoUid: 'prestador-1',
        ),
        isFalse,
      );
    },
  );
}

Pedido _pedido({EstadoPedido estado = EstadoPedido.emAndamento}) => Pedido(
  id: 'pedido-1',
  contratanteUid: 'contratante-1',
  titulo: 'Montagem',
  categoriaId: 'reparos',
  categoriaNome: 'Reparos',
  descricao: 'Montar estante',
  cidade: 'São Paulo',
  local: 'Centro',
  dataDesejada: DateTime.utc(2026, 10, 30),
  validadeAte: DateTime.utc(2026, 10, 28),
  valorCentavos: 12000,
  estado: estado,
  prestadorEscolhidoUid: 'prestador-1',
);
