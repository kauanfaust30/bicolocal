import 'data_civil.dart';
import 'pedido.dart';

class PedidoPermissions {
  const PedidoPermissions._();

  static bool ehParte({required Pedido pedido, required String? uid}) =>
      uid != null &&
      (uid == pedido.contratanteUid || uid == pedido.prestadorEscolhidoUid);

  /// A foto da outra parte só aparece entre contratante e prestador escolhido,
  /// com o pedido em andamento ou concluído (FR-020). Em qualquer outro caso,
  /// inclusive pedido cancelado, mostra-se a inicial do nome.
  static bool podeVerFotoDaParte({
    required Pedido pedido,
    required String? uid,
  }) =>
      (pedido.estado == EstadoPedido.emAndamento ||
          pedido.estado == EstadoPedido.concluido) &&
      pedido.prestadorEscolhidoUid != null &&
      ehParte(pedido: pedido, uid: uid);

  /// Só o contratante conclui, e só um pedido em andamento (FR-001).
  static bool podeConcluir({required Pedido pedido, required String? uid}) =>
      pedido.estado == EstadoPedido.emAndamento &&
      uid != null &&
      uid == pedido.contratanteUid;

  /// Contratante e prestador escolhido avaliam um ao outro depois que o
  /// pedido é concluído (FR-003, FR-005).
  static bool podeAvaliar({required Pedido pedido, required String? uid}) =>
      pedido.estado == EstadoPedido.concluido &&
      pedido.prestadorEscolhidoUid != null &&
      ehParte(pedido: pedido, uid: uid);

  /// A outra parte do pedido para quem é parte; `null` para os demais.
  static String? outraParte({required Pedido pedido, required String? uid}) {
    if (!ehParte(pedido: pedido, uid: uid)) return null;
    return uid == pedido.contratanteUid
        ? pedido.prestadorEscolhidoUid
        : pedido.contratanteUid;
  }

  /// Editar campos e gerenciar: só o contratante que publicou, com o pedido
  /// aberto e válido ou em andamento (002 FR-029, que prevalece sobre o
  /// FR-016 da 001). Espelha `mayEdit` das regras.
  static bool podeEditar({
    required Pedido pedido,
    required String? uid,
    required DateTime agoraUtc,
  }) => uid != null && uid == pedido.contratanteUid && _ativo(pedido, agoraUtc);

  /// Cancelar: o contratante (aberto válido ou em andamento) e o prestador
  /// escolhido (em andamento). Espelha `mayManage` das regras.
  static bool podeCancelar({
    required Pedido pedido,
    required String? uid,
    required DateTime agoraUtc,
  }) =>
      uid != null &&
      _ativo(pedido, agoraUtc) &&
      (uid == pedido.contratanteUid ||
          (pedido.estado == EstadoPedido.emAndamento &&
              uid == pedido.prestadorEscolhidoUid));

  /// Aberto dentro da validade ou em andamento. Cancelado e concluído não
  /// mudam mais (001 FR-020, 002 FR-002).
  static bool _ativo(Pedido pedido, DateTime agoraUtc) =>
      switch (pedido.estado) {
        EstadoPedido.emAndamento => true,
        EstadoPedido.aberto =>
          DataCivil.chave(pedido.validadeAte).compareTo(
                DataCivil.chave(DataCivil.hojeEmSaoPaulo(agoraUtc)),
              ) >=
              0,
        EstadoPedido.cancelado || EstadoPedido.concluido => false,
      };
}

class PedidoPermissaoErro implements Exception {
  const PedidoPermissaoErro();
}
