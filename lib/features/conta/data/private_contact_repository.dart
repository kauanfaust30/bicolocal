import 'package:cloud_firestore/cloud_firestore.dart';

class PrivateContactRepository {
  const PrivateContactRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> emailPrestador({
    required String pedidoId,
    required String prestadorUid,
  }) => _firestore
      .collection('requests')
      .doc(pedidoId)
      .collection('applications')
      .doc(prestadorUid)
      .collection('private')
      .doc('contact');

  DocumentReference<Map<String, dynamic>> emailContratante({
    required String pedidoId,
    required String contratanteUid,
  }) => _firestore
      .collection('requests')
      .doc(pedidoId)
      .collection('privateContacts')
      .doc(contratanteUid);

  Future<String?> carregarEmailPrestador({
    required String pedidoId,
    required String prestadorUid,
  }) async =>
      (await emailPrestador(
            pedidoId: pedidoId,
            prestadorUid: prestadorUid,
          ).get()).data()?['email']
          as String?;

  Future<String?> carregarEmailContratante({
    required String pedidoId,
    required String contratanteUid,
  }) async =>
      (await emailContratante(
            pedidoId: pedidoId,
            contratanteUid: contratanteUid,
          ).get()).data()?['email']
          as String?;
}
