import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/conta.dart';
import '../domain/conta_erro.dart';
import '../domain/conta_repository.dart';
import '../domain/perfil.dart';
import 'conta_dto.dart';

class FirebaseContaRepository implements ContaRepository {
  FirebaseContaRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usuarios =>
      _firestore.collection('users');

  @override
  Stream<Conta?> observarSessao() {
    late final StreamController<Conta?> controller;
    StreamSubscription<User?>? sessaoSubscription;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
    perfilSubscription;
    var geracao = 0;

    controller = StreamController<Conta?>(
      onListen: () {
        sessaoSubscription = _auth.authStateChanges().listen((usuario) {
          final geracaoAtual = ++geracao;
          unawaited(perfilSubscription?.cancel());
          if (usuario == null) {
            controller.add(null);
            return;
          }

          perfilSubscription = _usuarios.doc(usuario.uid).snapshots().listen((
            documento,
          ) {
            if (geracaoAtual != geracao) return;
            final dados = documento.data();
            if (dados == null) {
              controller.addError(ContaErro.indisponivel());
              return;
            }
            try {
              controller.add(
                ContaDto.fromDocument(
                  usuario.uid,
                  dados,
                  email: usuario.email ?? '',
                ),
              );
            } catch (erro, stackTrace) {
              controller.addError(erro, stackTrace);
            }
          }, onError: controller.addError);
        }, onError: controller.addError);
      },
      onCancel: () async {
        geracao++;
        await perfilSubscription?.cancel();
        await sessaoSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<Conta> cadastrar({
    required String email,
    required String senha,
    required String nome,
    required String cidade,
    required String bairro,
    required Perfil perfil,
  }) async {
    try {
      final credencial = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );
      final usuario = credencial.user;
      if (usuario == null) throw ContaErro.indisponivel();

      final conta = Conta(
        uid: usuario.uid,
        email: email,
        nome: nome,
        cidade: cidade,
        bairro: bairro,
        perfil: perfil,
      );
      try {
        await _usuarios.doc(usuario.uid).set(ContaDto.toDocument(conta));
        await _usuarios
            .doc(usuario.uid)
            .collection('private')
            .doc('contact')
            .set({'email': email});
      } catch (_) {
        await usuario.delete();
        rethrow;
      }
      return conta;
    } on FirebaseAuthException catch (erro) {
      throw _mapearErroAuth(erro);
    } on FirebaseException {
      throw ContaErro.indisponivel();
    }
  }

  @override
  Future<Conta> entrar({required String email, required String senha}) async {
    try {
      final credencial = await _auth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );
      final usuario = credencial.user;
      if (usuario == null) throw ContaErro.credenciaisInvalidas();
      return await _carregarConta(usuario);
    } on FirebaseAuthException catch (erro) {
      throw _mapearErroAuth(erro);
    } on FirebaseException {
      throw ContaErro.indisponivel();
    }
  }

  @override
  Future<void> sair() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException {
      throw ContaErro.indisponivel();
    }
  }

  @override
  Future<Conta> alterarPerfil({
    required String uid,
    required Perfil perfil,
  }) async {
    final usuario = _auth.currentUser;
    if (usuario == null || usuario.uid != uid) {
      throw ContaErro.credenciaisInvalidas();
    }
    try {
      await _usuarios.doc(uid).update({'perfil': perfil.name});
      return await _carregarConta(usuario);
    } on FirebaseException {
      throw ContaErro.indisponivel();
    }
  }

  Future<Conta> _carregarConta(User usuario) async {
    try {
      final documento = await _usuarios.doc(usuario.uid).get();
      final dados = documento.data();
      if (dados == null) throw ContaErro.indisponivel();
      return ContaDto.fromDocument(
        usuario.uid,
        dados,
        email: usuario.email ?? '',
      );
    } on FirebaseException {
      throw ContaErro.indisponivel();
    }
  }

  ContaErro _mapearErroAuth(FirebaseAuthException erro) => switch (erro.code) {
    'email-already-in-use' => ContaErro.emailEmUso(),
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => ContaErro.credenciaisInvalidas(),
    _ => ContaErro.indisponivel(),
  };
}
