import 'data_civil.dart';
import 'pedido.dart';

class PedidoPermissions {
  const PedidoPermissions._();

  static bool podeEditarOuCancelar({
    required Pedido pedido,
    required String uid,
    required DateTime agoraUtc,
  }) {
    if (pedido.estado == EstadoPedido.cancelado) return false;
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
