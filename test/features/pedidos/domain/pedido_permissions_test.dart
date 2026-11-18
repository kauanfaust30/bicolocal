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

  group('foto da outra parte (FR-020)', () {
    for (final estado in [EstadoPedido.emAndamento, EstadoPedido.concluido]) {
      test('as duas partes veem com o pedido ${estado.name}', () {
        final pedido = _pedido(estado: estado);
        expect(
          PedidoPermissions.podeVerFotoDaParte(
            pedido: pedido,
            uid: 'contratante-1',
          ),
          isTrue,
        );
        expect(
          PedidoPermissions.podeVerFotoDaParte(
            pedido: pedido,
            uid: 'prestador-1',
          ),
          isTrue,
        );
      });
    }

    test('quem não é parte nunca vê', () {
      expect(
        PedidoPermissions.podeVerFotoDaParte(pedido: _pedido(), uid: 'outro'),
        isFalse,
      );
      expect(
        PedidoPermissions.podeVerFotoDaParte(pedido: _pedido(), uid: null),
        isFalse,
      );
    });

    test('pedido aberto ou cancelado volta à inicial', () {
      for (final estado in [EstadoPedido.aberto, EstadoPedido.cancelado]) {
        expect(
          PedidoPermissions.podeVerFotoDaParte(
            pedido: _pedido(estado: estado),
            uid: 'contratante-1',
          ),
          isFalse,
          reason: estado.name,
        );
      }
    });
  });

  group('concluir (FR-001)', () {
    test('só o contratante, com o pedido em andamento', () {
      expect(
        PedidoPermissions.podeConcluir(pedido: _pedido(), uid: 'contratante-1'),
        isTrue,
      );
      expect(
        PedidoPermissions.podeConcluir(pedido: _pedido(), uid: 'prestador-1'),
        isFalse,
      );
      expect(
        PedidoPermissions.podeConcluir(pedido: _pedido(), uid: 'outro'),
        isFalse,
      );
    });

    test('recusa pedido aberto, cancelado ou já concluído', () {
      for (final estado in [
        EstadoPedido.aberto,
        EstadoPedido.cancelado,
        EstadoPedido.concluido,
      ]) {
        expect(
          PedidoPermissions.podeConcluir(
            pedido: _pedido(estado: estado),
            uid: 'contratante-1',
          ),
          isFalse,
          reason: estado.name,
        );
      }
    });
  });

  group('avaliar (FR-003, FR-005)', () {
    test('as duas partes avaliam o pedido concluído', () {
      final pedido = _pedido(estado: EstadoPedido.concluido);
      expect(
        PedidoPermissions.podeAvaliar(pedido: pedido, uid: 'contratante-1'),
        isTrue,
      );
      expect(
        PedidoPermissions.podeAvaliar(pedido: pedido, uid: 'prestador-1'),
        isTrue,
      );
    });

    test('quem não é parte não avalia', () {
      expect(
        PedidoPermissions.podeAvaliar(
          pedido: _pedido(estado: EstadoPedido.concluido),
          uid: 'outro',
        ),
        isFalse,
      );
    });

    test('pedido não concluído não pode ser avaliado', () {
      for (final estado in [
        EstadoPedido.aberto,
        EstadoPedido.emAndamento,
        EstadoPedido.cancelado,
      ]) {
        expect(
          PedidoPermissions.podeAvaliar(
            pedido: _pedido(estado: estado),
            uid: 'contratante-1',
          ),
          isFalse,
          reason: estado.name,
        );
      }
    });
  });

  test('pedido concluído não pode ser editado nem cancelado (FR-002)', () {
    expect(
      PedidoPermissions.podeEditarOuCancelar(
        pedido: _pedido(estado: EstadoPedido.concluido),
        uid: 'contratante-1',
        agoraUtc: DateTime.utc(2026, 10, 27, 12),
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
