enum AsyncStatus { inicial, carregando, sucesso, erro }

class AsyncState<T> {
  const AsyncState._({required this.status, this.data, this.mensagemErro});

  final AsyncStatus status;
  final T? data;
  final String? mensagemErro;

  const AsyncState.inicial() : this._(status: AsyncStatus.inicial);
  const AsyncState.carregando() : this._(status: AsyncStatus.carregando);
  const AsyncState.sucesso(T data)
    : this._(status: AsyncStatus.sucesso, data: data);
  const AsyncState.erro(String mensagem)
    : this._(status: AsyncStatus.erro, mensagemErro: mensagem);
}
