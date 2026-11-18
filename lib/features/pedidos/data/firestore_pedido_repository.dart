import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/categoria.dart';
import '../domain/data_civil.dart';
import '../domain/pedido.dart';
import '../domain/pedido_permissions.dart';
import '../domain/pedido_repository.dart';
import 'consulta_pedidos_abertos.dart';
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
    final snapshot = await ConsultaPedidosAbertos.aplicar(
      _firestore.collection('requests'),
      ConsultaPedidosAbertos.filtros(
        cidade: cidade,
        dataCivil: dataCivil,
        categoriaId: categoriaId,
      ),
    ).get();
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
    // Prestador escolhido: em andamento e concluídos, numa consulta por
    // estado para as regras validarem cada uma pela igualdade (FR-007).
    final consultas = await Future.wait([
      _firestore
          .collection('requests')
          .where('contratanteUid', isEqualTo: uid)
          .get(),
      for (final estado in ['em_andamento', 'concluido'])
        _firestore
            .collection('requests')
            .where('prestadorEscolhidoUid', isEqualTo: uid)
            .where('estado', isEqualTo: estado)
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

  @override
  Future<void> concluir({
    required String pedidoId,
    required String editorUid,
  }) async {
    final referencia = _firestore.collection('requests').doc(pedidoId);
    await _firestore.runTransaction((transacao) async {
      final documento = await transacao.get(referencia);
      final dados = documento.data();
      if (dados == null) throw const PedidoPermissaoErro();
      final pedido = PedidoDto.fromDocument(documento.id, dados);
      if (!PedidoPermissions.podeConcluir(pedido: pedido, uid: editorUid)) {
        throw const PedidoPermissaoErro();
      }
      // Só estado e atualizadoEm, como exige o ramo "concluir" das regras.
      transacao.update(referencia, {
        'estado': 'concluido',
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    });
  }
}
