class CandidaturaPermissaoErro implements Exception {
  const CandidaturaPermissaoErro(this.mensagem);

  final String mensagem;
}

class CandidaturaDuplicadaErro implements Exception {
  const CandidaturaDuplicadaErro();
}
