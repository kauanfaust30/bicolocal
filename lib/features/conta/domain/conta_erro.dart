enum ContaErroTipo {
  emailEmUso,
  credenciaisInvalidas,
  indisponivel,
  fotoNaoEnviada,
}

class ContaErro implements Exception {
  const ContaErro(this.tipo);

  factory ContaErro.emailEmUso() => const ContaErro(ContaErroTipo.emailEmUso);

  factory ContaErro.credenciaisInvalidas() =>
      const ContaErro(ContaErroTipo.credenciaisInvalidas);

  factory ContaErro.indisponivel() =>
      const ContaErro(ContaErroTipo.indisponivel);

  factory ContaErro.fotoNaoEnviada() =>
      const ContaErro(ContaErroTipo.fotoNaoEnviada);

  final ContaErroTipo tipo;

  String get mensagem => switch (tipo) {
    ContaErroTipo.emailEmUso =>
      'Este e-mail já tem uma conta. Entre ou use outro e-mail.',
    ContaErroTipo.credenciaisInvalidas =>
      'E-mail ou senha incorretos. Confira os dados e tente novamente.',
    ContaErroTipo.indisponivel =>
      'Não foi possível acessar sua conta. Tente novamente.',
    ContaErroTipo.fotoNaoEnviada =>
      'Não foi possível enviar sua foto. Seus dados continuam preenchidos. '
          'Verifique a conexão e toque em Criar conta de novo.',
  };
}

class ContaValidacaoErro implements Exception {
  const ContaValidacaoErro(this.campos);

  final Map<String, String> campos;
}
