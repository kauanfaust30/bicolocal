import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/registro_falha.dart';
import '../domain/avaliacao.dart';
import '../domain/avaliacao_erro.dart';
import '../domain/avaliacao_repository.dart';

class FirestoreAvaliacaoRepository implements AvaliacaoRepository {
  FirestoreAvaliacaoRepository(this._firestore);

  static const recentes = 5;

  final FirebaseFirestore _firestore;

  @override
  Future<List<Avaliacao>> listarRecentes(String avaliadoUid) async {
    final consulta = await _perfil(avaliadoUid)
        .collection('avaliacoes')
        .orderBy('criadaEm', descending: true)
        .limit(recentes)
        .get();
    return consulta.docs.map((documento) {
      final dados = documento.data();
      return Avaliacao(
        pedidoId: documento.id,
        avaliadorUid: dados['avaliadorUid'] as String? ?? '',
        avaliadorNome: dados['avaliadorNome'] as String? ?? '',
        avaliadoUid: avaliadoUid,
        nota: (dados['nota'] as num?)?.toInt() ?? 0,
        comentario: dados['comentario'] as String? ?? '',
        criadaEm: (dados['criadaEm'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  DocumentReference<Map<String, dynamic>> _perfil(String uid) =>
      _firestore.collection('profiles').doc(uid);

  DocumentReference<Map<String, dynamic>> _avaliacao({
    required String avaliadoUid,
    required String pedidoId,
  }) => _perfil(avaliadoUid).collection('avaliacoes').doc(pedidoId);

  @override
  Future<bool> jaAvaliou({
    required String pedidoId,
    required String avaliadoUid,
  }) async {
    final documento = await _avaliacao(
      avaliadoUid: avaliadoUid,
      pedidoId: pedidoId,
    ).get();
    return documento.exists;
  }

  /// Transação que cria a avaliação e atualiza a reputação do avaliado
  /// juntos (research D6). As regras recusam qualquer um dos dois sozinho.
  @override
  Future<void> avaliar(Avaliacao avaliacao) async {
    final perfil = _perfil(avaliacao.avaliadoUid);
    final documento = _avaliacao(
      avaliadoUid: avaliacao.avaliadoUid,
      pedidoId: avaliacao.pedidoId,
    );
    try {
      await _firestore.runTransaction((transacao) async {
        final atual = await transacao.get(perfil);
        final dados = atual.data();
        if (dados == null) throw const AvaliacaoPermissaoErro();
        if ((await transacao.get(documento)).exists) {
          throw const AvaliacaoPermissaoErro();
        }
        final total = ((dados['totalAvaliacoes'] as num?)?.toInt() ?? 0) + 1;
        final soma =
            ((dados['somaNotas'] as num?)?.toInt() ?? 0) + avaliacao.nota;
        transacao
          ..set(documento, {
            'avaliadorUid': avaliacao.avaliadorUid,
            'avaliadorNome': avaliacao.avaliadorNome,
            'nota': avaliacao.nota,
            'comentario': avaliacao.comentario,
            'criadaEm': FieldValue.serverTimestamp(),
          })
          ..update(perfil, {
            'totalAvaliacoes': total,
            'somaNotas': soma,
            'notaMedia': soma / total,
            'ultimaAvaliacaoId': avaliacao.pedidoId,
          });
      });
    } on FirebaseException catch (falha) {
      registrarFalha('Falha ao enviar avaliação no Firestore', falha);
      rethrow;
    }
  }
}
