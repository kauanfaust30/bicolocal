import 'avaliacao.dart';

/// Contrato das avaliações. A listagem entra na História 3 (T056).
abstract interface class AvaliacaoRepository {
  /// Se a pessoa autenticada já avaliou a outra parte neste pedido.
  Future<bool> jaAvaliou({
    required String pedidoId,
    required String avaliadoUid,
  });

  /// Cria a avaliação e atualiza a reputação do avaliado na mesma operação
  /// atômica (research D6, FR-027).
  Future<void> avaliar(Avaliacao avaliacao);
}
