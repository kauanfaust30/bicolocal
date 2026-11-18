import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/registro_falha.dart';
import '../../conta/domain/perfil.dart';
import '../domain/foto_erro.dart';
import '../domain/foto_perfil.dart';
import '../domain/perfil_publico.dart';
import '../domain/perfil_repository.dart';

class FirestorePerfilRepository implements PerfilRepository {
  FirestorePerfilRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> _fotoPrivada(String uid) =>
      _firestore.collection('users').doc(uid).collection('private').doc('foto');

  @override
  Future<PerfilPublico?> carregarPerfil(String uid) async {
    final documento = await _firestore.collection('profiles').doc(uid).get();
    final dados = documento.data();
    if (dados == null) return null;
    return PerfilPublico(
      uid: uid,
      nome: dados['nome'] as String? ?? '',
      cidade: dados['cidade'] as String? ?? '',
      perfil:
          PerfilLabel.fromValue(dados['perfil'] as String?) ?? Perfil.prestador,
      somaNotas: (dados['somaNotas'] as num?)?.toInt() ?? 0,
      totalAvaliacoes: (dados['totalAvaliacoes'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<FotoPerfil?> carregarFotoPropria() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final dados = (await _fotoPrivada(uid).get()).data();
    final imagem = dados?['imagem'];
    return imagem is Blob ? FotoPerfil(imagem.bytes) : null;
  }

  @override
  Future<void> salvarFotoPropria(FotoPerfil foto) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw FotoErro.envioFalhou;
    try {
      await _fotoPrivada(uid).set({
        'imagem': Blob(foto.bytes),
        'atualizadaEm': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (falha) {
      registrarFalha('Falha ao trocar foto no Firestore', falha);
      throw FotoErro.envioFalhou;
    }
  }
}
