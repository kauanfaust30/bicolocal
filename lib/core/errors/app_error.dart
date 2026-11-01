class AppError implements Exception {
  const AppError(this.mensagem);

  final String mensagem;

  static const operacaoIndisponivel =
      'Não foi possível concluir agora. Confira sua conexão e tente novamente.';
  static const semPermissao =
      'Você não tem autorização para esta ação. Confira seu perfil e tente novamente.';
}
