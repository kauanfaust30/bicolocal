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

  static bool podeEditarOuCancelar({
    required Pedido pedido,
    required String uid,
    required DateTime agoraUtc,
  }) {
    if (pedido.estado == EstadoPedido.cancelado ||
        pedido.estado == EstadoPedido.concluido) {
      return false;
    }
    final expirado =
        pedido.estado == EstadoPedido.aberto &&
        DataCivil.chave(
              pedido.validadeAte,
            ).compareTo(DataCivil.chave(DataCivil.hojeEmSaoPaulo(agoraUtc))) <
            0;
    if (expirado) return false;
    return uid == pedido.contratanteUid ||
        (pedido.estado == EstadoPedido.emAndamento &&
            uid == pedido.prestadorEscolhidoUid);
  }
}

class PedidoPermissaoErro implements Exception {
  const PedidoPermissaoErro();
}
