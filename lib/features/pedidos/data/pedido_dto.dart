import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/categoria.dart';
import '../domain/data_civil.dart';
import '../domain/pedido.dart';

class PedidoDto {
  const PedidoDto._();

  static Categoria categoriaFromDocument(
    String id,
    Map<String, dynamic> data,
  ) => Categoria(id: id, nome: data['nome'] as String? ?? '');

  static Pedido fromDocument(String id, Map<String, dynamic> data) {
    final estado = switch (data['estado']) {
      'em_andamento' => EstadoPedido.emAndamento,
      'cancelado' => EstadoPedido.cancelado,
      _ => EstadoPedido.aberto,
    };
    return Pedido(
      id: id,
      contratanteUid: data['contratanteUid'] as String? ?? '',
      titulo: data['titulo'] as String? ?? '',
      categoriaId: data['categoriaId'] as String? ?? '',
      categoriaNome: data['categoriaNome'] as String? ?? '',
      descricao: data['descricao'] as String? ?? '',
      cidade: data['cidade'] as String? ?? '',
      local: data['local'] as String? ?? '',
      dataDesejada: DataCivil.deChave(data['dataDesejada'] as String),
      validadeAte: DataCivil.deChave(data['validadeAte'] as String),
      valorCentavos: data['valorCentavos'] as int? ?? 0,
      estado: estado,
      prestadorEscolhidoUid: data['prestadorEscolhidoUid'] as String?,
    );
  }

  static Map<String, Object?> toDocument(Pedido pedido) => {
    'contratanteUid': pedido.contratanteUid,
    'titulo': pedido.titulo,
    'categoriaId': pedido.categoriaId,
    'categoriaNome': pedido.categoriaNome,
    'descricao': pedido.descricao,
    'cidade': pedido.cidade,
    'cidadeChave': pedido.cidade.trim().toLowerCase(),
    'local': pedido.local,
    'dataDesejada': DataCivil.chave(pedido.dataDesejada),
    'dataDesejadaDia': Timestamp.fromDate(
      DateTime.utc(
        pedido.dataDesejada.year,
        pedido.dataDesejada.month,
        pedido.dataDesejada.day,
      ),
    ),
    'validadeAte': DataCivil.chave(pedido.validadeAte),
    'validadeAteDia': Timestamp.fromDate(
      DateTime.utc(
        pedido.validadeAte.year,
        pedido.validadeAte.month,
        pedido.validadeAte.day,
      ),
    ),
    'valorCentavos': pedido.valorCentavos,
    'estado': 'aberto',
    'prestadorEscolhidoUid': null,
    'criadoEm': FieldValue.serverTimestamp(),
    'atualizadoEm': FieldValue.serverTimestamp(),
  };
}
