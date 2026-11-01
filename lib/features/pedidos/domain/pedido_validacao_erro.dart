class PedidoValidacaoErro implements Exception {
  const PedidoValidacaoErro(this.campos);

  final Map<String, String> campos;
}
