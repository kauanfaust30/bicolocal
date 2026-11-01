import 'package:bicolocal/features/pedidos/domain/pedido.dart';
import 'package:bicolocal/features/pedidos/domain/pedido_permissions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('contratante autor e prestador escolhido podem gerenciar sem depender do perfil ativo', () {
    final pedido = _pedido();
    final agora = DateTime.utc(2026, 10, 27, 12);

    expect(
      PedidoPermissions.podeEditarOuCancelar(
        pedido: pedido,
        uid: 'contratante-1',
        agoraUtc: agora,
      ),
      isTrue,
    );
    expect(
      PedidoPermissions.podeEditarOuCancelar(
        pedido: pedido,
        uid: 'prestador-1',
        agoraUtc: agora,
      ),
      isTrue,
    );
    expect(
      PedidoPermissions.podeEditarOuCancelar(
        pedido: pedido,
        uid: 'outro',
        agoraUtc: agora,
      ),
      isFalse,
    );
  });

  test('recusa pedido expirado ou cancelado e prestador não escolhido', () {
    final agora = DateTime.utc(2026, 10, 27, 12);
    expect(
      PedidoPermissions.podeEditarOuCancelar(
        pedido: _pedido(
          estado: EstadoPedido.aberto,
          validadeAte: DateTime.utc(2026, 10, 26),
        ),
        uid: 'contratante-1',
        agoraUtc: agora,
      ),
      isFalse,
    );
    expect(
      PedidoPermissions.podeEditarOuCancelar(
        pedido: _pedido(estado: EstadoPedido.cancelado),
        uid: 'contratante-1',
        agoraUtc: agora,
      ),
      isFalse,
    );
    expect(
      PedidoPermissions.podeEditarOuCancelar(
        pedido: _pedido(),
        uid: 'outro',
        agoraUtc: agora,
      ),
      isFalse,
    );
  });
}

Pedido _pedido({
  EstadoPedido estado = EstadoPedido.emAndamento,
  DateTime? validadeAte,
}) => Pedido(
  id: 'pedido-1',
  contratanteUid: 'contratante-1',
  titulo: 'Montagem',
  categoriaId: 'reparos',
  categoriaNome: 'Reparos',
  descricao: 'Montar estante',
  cidade: 'São Paulo',
  local: 'Centro',
  dataDesejada: DateTime.utc(2026, 10, 30),
  validadeAte: validadeAte ?? DateTime.utc(2026, 10, 28),
  valorCentavos: 12000,
  estado: estado,
  prestadorEscolhidoUid: 'prestador-1',
);
