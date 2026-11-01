import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../conta/data/private_contact_repository.dart';
import '../../pedidos/domain/data_civil.dart';
import '../domain/candidatura.dart';
import '../domain/candidatura_error.dart';
import '../domain/candidatura_repository.dart';

class FirestoreCandidaturaRepository implements CandidaturaRepository {
  FirestoreCandidaturaRepository(this._firestore, this._auth, this._contacts);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final PrivateContactRepository _contacts;

  DocumentReference<Map<String, dynamic>> _pedido(String id) =>
      _firestore.collection('requests').doc(id);

  CollectionReference<Map<String, dynamic>> _candidaturas(String id) =>
      _pedido(id).collection('applications');

  @override
  Future<Candidatura?> buscar({
    required String pedidoId,
    required String prestadorUid,
  }) async {
    final documento = await _candidaturas(pedidoId).doc(prestadorUid).get();
    final dados = documento.data();
    return dados == null ? null : _fromData(pedidoId, documento.id, dados);
  }

  @override
  Future<List<Candidatura>> listar({required String pedidoId}) async {
    final snapshot = await _candidaturas(pedidoId).orderBy('criadaEm').get();
    return snapshot.docs
        .map((doc) => _fromData(pedidoId, doc.id, doc.data()))
        .toList();
  }

  @override
  Future<void> candidatar(
    Candidatura candidatura, {
    required String emailPrestador,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != candidatura.prestadorUid) {
      throw const CandidaturaPermissaoErro(
        'Entre na sua conta para enviar uma candidatura.',
      );
    }
    final pedidoRef = _pedido(candidatura.pedidoId);
    final candidaturaRef = _candidaturas(candidatura.pedidoId)
        .doc(candidatura.prestadorUid);
    final contatoRef = _contacts.emailPrestador(
      pedidoId: candidatura.pedidoId,
      prestadorUid: candidatura.prestadorUid,
    );

    await _firestore.runTransaction((transaction) async {
      final pedidoDoc = await transaction.get(pedidoRef);
      final candidaturaDoc = await transaction.get(candidaturaRef);
      final pedidoData = pedidoDoc.data();
      if (pedidoData == null ||
          !_disponivel(pedidoData) ||
          candidaturaDoc.exists) {
        if (candidaturaDoc.exists) throw const CandidaturaDuplicadaErro();
        throw const CandidaturaPermissaoErro(
          'Este pedido não está mais disponível para candidatura.',
        );
      }
      transaction.set(candidaturaRef, {
        'prestadorUid': candidatura.prestadorUid,
        'estado': 'pendente',
        'criadaEm': FieldValue.serverTimestamp(),
        'atualizadaEm': FieldValue.serverTimestamp(),
      });
      transaction.set(contatoRef, {'email': emailPrestador});
    });
  }

  @override
  Future<void> aceitar({
    required String pedidoId,
    required String prestadorUid,
    required String emailContratante,
    required DateTime agoraUtc,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _auth.currentUser?.email != emailContratante) {
      throw const CandidaturaPermissaoErro(
        'Entre na conta que publicou o pedido para aceitar a candidatura.',
      );
    }
    final pedidoRef = _pedido(pedidoId);
    final candidaturas = await _candidaturas(pedidoId).get();
    final candidaturaRefs = candidaturas.docs
        .map((doc) => doc.reference)
        .toList();
    final escolhidaRef = _candidaturas(pedidoId).doc(prestadorUid);
    final emailContratanteRef = _contacts.emailContratante(
      pedidoId: pedidoId,
      contratanteUid: uid,
    );

    await _firestore.runTransaction((transaction) async {
      final pedidoDoc = await transaction.get(pedidoRef);
      final escolhidaDoc = await transaction.get(escolhidaRef);
      final outrasDocs = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final ref in candidaturaRefs) {
        if (ref.id != prestadorUid) {
          outrasDocs.add(await transaction.get(ref));
        }
      }

      final pedidoData = pedidoDoc.data();
      final escolhidaData = escolhidaDoc.data();
      if (uid != pedidoData?['contratanteUid'] ||
          pedidoData == null ||
          !_disponivel(pedidoData, agoraUtc: agoraUtc) ||
          escolhidaData?['estado'] != 'pendente') {
        throw const CandidaturaPermissaoErro(
          'Não foi possível aceitar. Atualize o pedido e tente novamente.',
        );
      }

      transaction.update(pedidoRef, {
        'estado': 'em_andamento',
        'prestadorEscolhidoUid': prestadorUid,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
      transaction.update(escolhidaRef, {
        'estado': 'aceita',
        'atualizadaEm': FieldValue.serverTimestamp(),
      });
      for (var index = 0; index < outrasDocs.length; index++) {
        final outra = outrasDocs[index];
        if (outra.data()?['estado'] == 'pendente') {
          transaction.update(
            candidaturaRefs
                .where((ref) => ref.id != prestadorUid)
                .elementAt(index),
            {
              'estado': 'recusada',
              'atualizadaEm': FieldValue.serverTimestamp(),
            },
          );
        }
      }
      transaction.set(emailContratanteRef, {
        'email': emailContratante,
        'contratanteUid': uid,
      });
    });
  }

  @override
  Future<String?> carregarEmailPrestador({
    required String pedidoId,
    required String prestadorUid,
  }) => _contacts.carregarEmailPrestador(
    pedidoId: pedidoId,
    prestadorUid: prestadorUid,
  );

  @override
  Future<String?> carregarEmailContratante({
    required String pedidoId,
    required String contratanteUid,
  }) => _contacts.carregarEmailContratante(
    pedidoId: pedidoId,
    contratanteUid: contratanteUid,
  );

  Candidatura _fromData(
    String pedidoId,
    String uid,
    Map<String, dynamic> data,
  ) => Candidatura(
    pedidoId: pedidoId,
    prestadorUid: data['prestadorUid'] as String? ?? uid,
    estado: switch (data['estado']) {
      'aceita' => EstadoCandidatura.aceita,
      'recusada' => EstadoCandidatura.recusada,
      _ => EstadoCandidatura.pendente,
    },
  );

  bool _disponivel(Map<String, dynamic> data, {DateTime? agoraUtc}) =>
      data['estado'] == 'aberto' &&
      (data['validadeAte'] as String? ?? '').compareTo(
            DataCivil.chave(
              DataCivil.hojeEmSaoPaulo(agoraUtc ?? DateTime.now().toUtc()),
            ),
          ) >=
          0;
}
