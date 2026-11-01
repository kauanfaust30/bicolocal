import 'package:bicolocal/features/pedidos/domain/categoria.dart';
import 'package:bicolocal/features/pedidos/domain/pedido.dart';
import 'package:bicolocal/features/pedidos/domain/pedido_repository.dart';
import 'package:bicolocal/features/pedidos/domain/pedido_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'consulta pedidos da mesma cidade ainda válidos no dia corrente',
    () async {
      final repositorio = _RepositorioPedidosFalso();
      final service = PedidoService(repositorio);

      await service.listarAbertos(
        cidade: 'São Paulo',
        agoraUtc: DateTime.utc(2026, 10, 27, 2, 59),
      );

      expect(repositorio.ultimaCidade, 'São Paulo');
      expect(repositorio.ultimaDataCivil, '2026-10-26');
    },
  );
}

class _RepositorioPedidosFalso implements PedidoRepository {
  String? ultimaCidade;
  String? ultimaDataCivil;

  @override
  Future<List<Categoria>> carregarCategorias() async => const [];

  @override
  Future<List<Pedido>> listarAbertos({
    required String cidade,
    required String dataCivil,
    String? categoriaId,
  }) async {
    ultimaCidade = cidade;
    ultimaDataCivil = dataCivil;
    return const [];
  }

  @override
  Future<void> publicar(Pedido pedido) async {}

  @override
  Future<List<Pedido>> listarGerenciaveis({required String uid}) async =>
      const [];

  @override
  Future<Pedido?> buscar({required String pedidoId}) async => null;

  @override
  Future<void> atualizar({
    required Pedido pedido,
    required String editorUid,
    required DateTime agoraUtc,
  }) async {}

  @override
  Future<void> cancelar({
    required String pedidoId,
    required String editorUid,
    required DateTime agoraUtc,
  }) async {}
}
