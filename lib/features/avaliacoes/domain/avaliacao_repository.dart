import 'avaliacao.dart';

abstract interface class AvaliacaoRepository {
  /// As 5 avaliações recebidas mais recentes, da mais nova para a mais
  /// antiga (FR-009).
  Future<List<Avaliacao>> listarRecentes(String avaliadoUid);

  /// Se a pessoa autenticada já avaliou a outra parte neste pedido.
  Future<bool> jaAvaliou({
    required String pedidoId,
    required String avaliadoUid,
  });

  /// Cria a avaliação e atualiza a reputação do avaliado na mesma operação
  /// atômica (research D6, FR-027).
  Future<void> avaliar(Avaliacao avaliacao);
}
