import 'package:bicolocal/core/async/async_state.dart';
import 'package:bicolocal/features/conta/domain/conta.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:bicolocal/features/pedidos/presentation/pedido_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes/fake_repositories.dart';

void main() {
  test(
    'mostra mensagem para o usuário quando o Firestore nega acesso',
    () async {
      final controller = PedidoController(
        FakePedidoRepository(
          falhaListarAbertos: FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        ),
      );

      await controller.carregar(
        _prestador,
        agoraUtc: DateTime.utc(2026, 10, 28),
      );

      expect(controller.estadoLista.status, AsyncStatus.erro);
      expect(controller.estadoLista.mensagemErro, _mensagemUsuario);
      expect(controller.estadoLista.mensagemErro, isNot(contains('UID')));
      expect(controller.estadoLista.mensagemErro, isNot(contains('Firestore')));
    },
  );

  test(
    'mostra mensagem para o usuário quando o índice do Firestore está pendente',
    () async {
      final controller = PedidoController(
        FakePedidoRepository(
          falhaListarAbertos: FirebaseException(
            plugin: 'cloud_firestore',
            code: 'failed-precondition',
          ),
        ),
      );

      await controller.carregar(
        _prestador,
        agoraUtc: DateTime.utc(2026, 10, 28),
      );

      expect(controller.estadoLista.status, AsyncStatus.erro);
      expect(controller.estadoLista.mensagemErro, _mensagemUsuario);
      expect(controller.estadoLista.mensagemErro, isNot(contains('índice')));
      expect(controller.estadoLista.mensagemErro, isNot(contains('Firestore')));
    },
  );
}

const _mensagemUsuario =
    'Não foi possível carregar os pedidos agora. Tente novamente em instantes.';

const _prestador = Conta(
  uid: 'prestador-1',
  email: 'prestador@example.com',
  nome: 'Prestador de teste',
  cidade: 'Rio do Sul',
  bairro: 'Centro',
  perfil: Perfil.prestador,
);
