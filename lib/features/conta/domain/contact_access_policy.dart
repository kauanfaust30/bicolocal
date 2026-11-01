import '../../pedidos/domain/pedido.dart';

class ContactAccessPolicy {
  const ContactAccessPolicy._();

  static bool podeLerContato({
    required Pedido pedido,
    required String leitorUid,
    required String donoContatoUid,
  }) {
    if (leitorUid == donoContatoUid) return true;
    if (pedido.estado != EstadoPedido.emAndamento) return false;

    final partes = {pedido.contratanteUid, pedido.prestadorEscolhidoUid};
    return partes.contains(leitorUid) && partes.contains(donoContatoUid);
  }
}
