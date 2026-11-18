import 'package:bicolocal/features/pedidos/domain/pedido.dart';
import 'package:bicolocal/features/pedidos/domain/pedido_permissions.dart';
import 'package:bicolocal/features/pedidos/domain/pedido_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/builders/test_data.dart';
import '../../../support/fakes/fake_repositories.dart';

void main() {
  final emAndamento =
      criarPedidoTeste(
        id: 'pedido-1',
        contratanteUid: 'contratante-1',
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

  test('contratante conclui pedido em andamento', () async {
    await service.concluir(pedido: emAndamento, editorUid: 'contratante-1');

    expect(repository.pedidos.single.estado, EstadoPedido.concluido);
  });

  test('prestador escolhido e outras pessoas não concluem', () async {
    for (final uid in ['prestador-1', 'outra-pessoa']) {
      await expectLater(
        service.concluir(pedido: emAndamento, editorUid: uid),
        throwsA(isA<PedidoPermissaoErro>()),
        reason: uid,
      );
    }
    expect(repository.pedidos.single.estado, EstadoPedido.emAndamento);
  });

  test('pedido aberto, cancelado ou concluído não é concluído', () async {
    for (final estado in [
      EstadoPedido.aberto,
      EstadoPedido.cancelado,
      EstadoPedido.concluido,
    ]) {
      await expectLater(
        service.concluir(
          pedido: emAndamento.copyWith(estado: estado),
          editorUid: 'contratante-1',
        ),
        throwsA(isA<PedidoPermissaoErro>()),
        reason: estado.name,
      );
    }
    expect(repository.concluidos, isEmpty);
  });
}
