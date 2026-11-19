import 'package:bicolocal/features/pedidos/domain/pedido.dart';
import 'package:bicolocal/features/pedidos/domain/pedido_permissions.dart';
import 'package:bicolocal/features/pedidos/domain/pedido_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/builders/test_data.dart';
import '../../../support/fakes/fake_repositories.dart';

/// Depois do aceite, só o contratante edita; o prestador escolhido ainda
/// cancela (002 FR-029, prevalece sobre 001 FR-016).
void main() {
  final agora = DateTime.utc(2026, 10, 27, 12);
  final emAndamento =
      criarPedidoTeste(
        id: 'pedido-1',
        contratanteUid: 'contratante-1',
        dataDesejada: DateTime.utc(2099, 1, 3),
        validadeAte: DateTime.utc(2099, 1, 2),
      ).copyWith(
        estado: EstadoPedido.emAndamento,
        prestadorEscolhidoUid: 'prestador-1',
      );

  late FakePedidoRepository repository;
  late PedidoService service;

  setUp(() {
    repository = FakePedidoRepository(pedidos: [emAndamento]);
    service = PedidoService(repository);
  });

  test('prestador escolhido não edita o pedido em andamento', () async {
    await expectLater(
      service.atualizar(
        original: emAndamento,
        alterado: emAndamento.copyWith(titulo: 'Outro título'),
        editorUid: 'prestador-1',
        agoraUtc: agora,
      ),
      throwsA(isA<PedidoPermissaoErro>()),
    );
    expect(repository.pedidos.single.titulo, emAndamento.titulo);
  });

  test('contratante edita o pedido em andamento', () async {
    await service.atualizar(
      original: emAndamento,
      alterado: emAndamento.copyWith(titulo: 'Outro título'),
      editorUid: 'contratante-1',
      agoraUtc: agora,
    );

    expect(repository.pedidos.single.titulo, 'Outro título');
  });

  test('prestador escolhido cancela o pedido em andamento', () async {
    await service.cancelar(
      pedido: emAndamento,
      editorUid: 'prestador-1',
      agoraUtc: agora,
    );

    expect(repository.pedidos.single.estado, EstadoPedido.cancelado);
  });
}
