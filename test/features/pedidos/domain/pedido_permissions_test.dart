import 'package:bicolocal/features/pedidos/domain/pedido.dart';
import 'package:bicolocal/features/pedidos/domain/pedido_permissions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final agora = DateTime.utc(2026, 10, 27, 12);

  bool podeEditar(Pedido pedido, String uid) =>
      PedidoPermissions.podeEditar(pedido: pedido, uid: uid, agoraUtc: agora);

  bool podeCancelar(Pedido pedido, String uid) =>
      PedidoPermissions.podeCancelar(pedido: pedido, uid: uid, agoraUtc: agora);

  group('editar (002 FR-029, prevalece sobre 001 FR-016)', () {
    test('só o contratante edita, aberto válido ou em andamento', () {
      final aberto = _pedido(estado: EstadoPedido.aberto);
      expect(podeEditar(aberto, 'contratante-1'), isTrue);
      expect(podeEditar(_pedido(), 'contratante-1'), isTrue);
    });

    test('prestador escolhido não edita o pedido em andamento', () {
      expect(podeEditar(_pedido(), 'prestador-1'), isFalse);
    });

    test(
      'recusa quem não é parte e pedido expirado, cancelado ou concluído',
      () {
        expect(podeEditar(_pedido(), 'outro'), isFalse);
        expect(
          podeEditar(
            _pedido(
              estado: EstadoPedido.aberto,
              validadeAte: DateTime.utc(2026, 10, 26),
            ),
            'contratante-1',
          ),
          isFalse,
        );
        for (final estado in [EstadoPedido.cancelado, EstadoPedido.concluido]) {
          expect(
            podeEditar(_pedido(estado: estado), 'contratante-1'),
            isFalse,
            reason: estado.name,
          );
        }
      },
    );
  });

  group('cancelar (001 FR-016, FR-020)', () {
    test(
      'contratante e prestador escolhido cancelam o pedido em andamento',
      () {
        expect(podeCancelar(_pedido(), 'contratante-1'), isTrue);
        expect(podeCancelar(_pedido(), 'prestador-1'), isTrue);
      },
    );

    test('antes do aceite, só o contratante cancela', () {
      final aberto = _pedido(estado: EstadoPedido.aberto);
      expect(podeCancelar(aberto, 'contratante-1'), isTrue);
      expect(podeCancelar(aberto, 'prestador-1'), isFalse);
    });

    test('recusa quem não é parte e pedido expirado ou cancelado', () {
      expect(podeCancelar(_pedido(), 'outro'), isFalse);
      expect(
        podeCancelar(
          _pedido(
            estado: EstadoPedido.aberto,
            validadeAte: DateTime.utc(2026, 10, 26),
          ),
          'contratante-1',
        ),
        isFalse,
      );
      expect(
        podeCancelar(_pedido(estado: EstadoPedido.cancelado), 'contratante-1'),
        isFalse,
      );
    });
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
    final concluido = _pedido(estado: EstadoPedido.concluido);
    expect(podeEditar(concluido, 'contratante-1'), isFalse);
    expect(podeCancelar(concluido, 'contratante-1'), isFalse);
    expect(podeCancelar(concluido, 'prestador-1'), isFalse);
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
