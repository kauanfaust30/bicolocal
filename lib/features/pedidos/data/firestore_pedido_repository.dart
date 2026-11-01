import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/categoria.dart';
import '../domain/data_civil.dart';
import '../domain/pedido.dart';
import '../domain/pedido_permissions.dart';
import '../domain/pedido_repository.dart';
import 'pedido_dto.dart';

class FirestorePedidoRepository implements PedidoRepository {
  FirestorePedidoRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<Categoria>> carregarCategorias() async {
    final snapshot = await _firestore
        .collection('categories')
        .orderBy('nome')
        .get();
    return snapshot.docs
        .map(
          (documento) =>
              PedidoDto.categoriaFromDocument(documento.id, documento.data()),
        )
        .toList();
  }

  @override
  Future<List<Pedido>> listarAbertos({
    required String cidade,
    required String dataCivil,
    String? categoriaId,
  }) async {
    Query<Map<String, dynamic>> consulta = _firestore
        .collection('requests')
        .where('estado', isEqualTo: 'aberto')
        .where('cidadeChave', isEqualTo: cidade.trim().toLowerCase());
    if (categoriaId != null) {
      consulta = consulta.where('categoriaId', isEqualTo: categoriaId);
    }
    final snapshot = await consulta
        .where(
          'validadeAteDia',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            DataCivil.inicioDiaUtc(dataCivil),
          ),
        )
        .orderBy('validadeAteDia')
        .get();
    return snapshot.docs
        .map(
          (documento) => PedidoDto.fromDocument(documento.id, documento.data()),
        )
        .toList();
  }

  @override
  Future<void> publicar(Pedido pedido) async {
    final documento = pedido.id.isEmpty
        ? _firestore.collection('requests').doc()
        : _firestore.collection('requests').doc(pedido.id);
    await documento.set(PedidoDto.toDocument(pedido));
  }

  @override
  Future<List<Pedido>> listarGerenciaveis({required String uid}) async {
    final consultas = await Future.wait([
      _firestore
          .collection('requests')
          .where('contratanteUid', isEqualTo: uid)
          .get(),
      _firestore
          .collection('requests')
          .where('prestadorEscolhidoUid', isEqualTo: uid)
          .where('estado', isEqualTo: 'em_andamento')
          .get(),
    ]);
    final documentos = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final consulta in consultas) {
      for (final documento in consulta.docs) {
        documentos[documento.id] = documento;
      }
    }
    return documentos.values
        .map(
          (documento) => PedidoDto.fromDocument(documento.id, documento.data()),
        )
        .toList();
  }

  @override
  Future<Pedido?> buscar({required String pedidoId}) async {
    final documento = await _firestore
        .collection('requests')
        .doc(pedidoId)
        .get();
    final dados = documento.data();
    return dados == null ? null : PedidoDto.fromDocument(documento.id, dados);
  }

  @override
  Future<void> atualizar({
    required Pedido pedido,
    required String editorUid,
    required DateTime agoraUtc,
  }) async {
    final referencia = _firestore.collection('requests').doc(pedido.id);
    await _firestore.runTransaction((transacao) async {
      final documento = await transacao.get(referencia);
      final dados = documento.data();
      if (dados == null) throw const PedidoPermissaoErro();
      final atual = PedidoDto.fromDocument(documento.id, dados);
      if (!PedidoPermissions.podeEditarOuCancelar(
        pedido: atual,
        uid: editorUid,
        agoraUtc: agoraUtc,
      )) {
        throw const PedidoPermissaoErro();
      }
      transacao.update(referencia, {
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
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> cancelar({
    required String pedidoId,
    required String editorUid,
    required DateTime agoraUtc,
  }) async {
    final referencia = _firestore.collection('requests').doc(pedidoId);
    await _firestore.runTransaction((transacao) async {
      final documento = await transacao.get(referencia);
      final dados = documento.data();
      if (dados == null) throw const PedidoPermissaoErro();
      final pedido = PedidoDto.fromDocument(documento.id, dados);
      if (!PedidoPermissions.podeEditarOuCancelar(
        pedido: pedido,
        uid: editorUid,
        agoraUtc: agoraUtc,
      )) {
        throw const PedidoPermissaoErro();
      }
      transacao.update(referencia, {
        'estado': 'cancelado',
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    });
  }
}
