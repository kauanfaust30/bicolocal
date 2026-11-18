/// Avaliação de uma parte pela outra em um pedido concluído. Gravada em
/// `profiles/{avaliadoUid}/avaliacoes/{pedidoId}`; não pode ser editada nem
/// apagada (FR-006).
class Avaliacao {
  const Avaliacao({
    required this.pedidoId,
    required this.avaliadorUid,
    required this.avaliadorNome,
    required this.avaliadoUid,
    required this.nota,
    required this.comentario,
    this.criadaEm,
  });

  final String pedidoId;
  final String avaliadorUid;

  /// Nome de quem avaliou no momento da avaliação; não muda depois (FR-009).
  final String avaliadorNome;
  final String avaliadoUid;
  final int nota;

  /// Vazio quando a pessoa não escreveu comentário.
  final String comentario;

  /// Definida pelo servidor; `null` antes de gravar.
  final DateTime? criadaEm;
}
