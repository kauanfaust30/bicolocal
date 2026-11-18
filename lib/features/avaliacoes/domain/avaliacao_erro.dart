/// Avaliação recusada: pedido não concluído, quem não é parte ou segunda
/// avaliação da mesma parte (FR-005).
class AvaliacaoPermissaoErro implements Exception {
  const AvaliacaoPermissaoErro();
}

/// Nota ou comentário inválidos, com a mensagem de cada campo (FR-004).
class AvaliacaoValidacaoErro implements Exception {
  const AvaliacaoValidacaoErro(this.campos);

  final Map<String, String> campos;
}
