import 'categoria.dart';
import 'pedido.dart';

abstract interface class PedidoRepository {
  Future<List<Categoria>> carregarCategorias();

  Future<List<Pedido>> listarAbertos({
    required String cidade,
    required String dataCivil,
    String? categoriaId,
  });

  Future<void> publicar(Pedido pedido);

  Future<List<Pedido>> listarGerenciaveis({required String uid});

  Future<Pedido?> buscar({required String pedidoId});

  Future<void> atualizar({
    required Pedido pedido,
    required String editorUid,
    required DateTime agoraUtc,
  });

  Future<void> cancelar({
    required String pedidoId,
    required String editorUid,
    required DateTime agoraUtc,
  });

  /// Passa o pedido de em andamento para concluído, alterando só `estado` e
  /// `atualizadoEm` (FR-001).
  Future<void> concluir({required String pedidoId, required String editorUid});
}
