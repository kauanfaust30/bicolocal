import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/registro_falha.dart';
import '../../perfil/domain/foto_erro.dart';
import '../../perfil/domain/foto_perfil.dart';
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
          ) async {
            if (geracaoAtual != geracao) return;
            final dados = documento.data();
            if (dados == null) {
              controller.addError(ContaErro.indisponivel());
              return;
            }
            try {
              final temFoto = await _temFotoEPerfil(usuario.uid);
              if (geracaoAtual != geracao) return;
              controller.add(
                ContaDto.fromDocument(
                  usuario.uid,
                  dados,
                  email: usuario.email ?? '',
                  temFoto: temFoto,
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
    required FotoPerfil foto,
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
      // Tudo num único batch: ou a conta nasce com foto e perfil público,
      // ou nada é criado (FR-017, research D8).
      final lote = _firestore.batch()
        ..set(_usuarios.doc(usuario.uid), ContaDto.toDocument(conta))
        ..set(_privado(usuario.uid, 'contact'), {'email': email})
        ..set(_privado(usuario.uid, 'foto'), _dadosFoto(foto))
        ..set(
          _perfis.doc(usuario.uid),
          ContaDto.perfilPublicoNovo(
            nome: nome,
            cidade: cidade,
            perfil: perfil.name,
          ),
        );
      try {
        await lote.commit();
      } catch (falha) {
        registrarFalha(
          'Falha ao gravar o cadastro com foto no Firestore',
          falha,
        );
        try {
          await usuario.delete();
        } catch (falhaExclusao) {
          // Sem o usuário apagado, a próxima entrada leva a Adicionar foto.
          registrarFalha(
            'Falha ao desfazer o usuário após o cadastro',
            falhaExclusao,
          );
        }
        throw ContaErro.fotoNaoEnviada();
      }
      return conta;
    } on FirebaseAuthException catch (erro) {
      registrarFalha('Falha ao criar usuário no Firebase Auth', erro);
      throw _mapearErroAuth(erro);
    } on FirebaseException catch (erro) {
      registrarFalha('Falha ao cadastrar conta no Firebase', erro);
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
  Future<void> adicionarFoto(FotoPerfil foto) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw FotoErro.envioFalhou;
    try {
      final lote = _firestore.batch()
        ..set(_privado(uid, 'foto'), _dadosFoto(foto));
      // Contas da 001 não têm perfil público: cria a partir de users/{uid}
      // na mesma escrita (research D7).
      final perfil = await _perfis.doc(uid).get();
      if (!perfil.exists) {
        final dados = (await _usuarios.doc(uid).get()).data();
        if (dados == null) throw FotoErro.envioFalhou;
        lote.set(
          _perfis.doc(uid),
          ContaDto.perfilPublicoNovo(
            nome: dados['nome'] as String? ?? '',
            cidade: dados['cidade'] as String? ?? '',
            perfil: dados['perfil'] as String? ?? '',
          ),
        );
      }
      await lote.commit();
    } on FirebaseException catch (falha) {
      registrarFalha('Falha ao adicionar foto no Firestore', falha);
      throw FotoErro.envioFalhou;
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
        temFoto: await _temFotoEPerfil(usuario.uid),
      );
    } on FirebaseException {
      throw ContaErro.indisponivel();
    }
  }

  CollectionReference<Map<String, dynamic>> get _perfis =>
      _firestore.collection('profiles');

  DocumentReference<Map<String, dynamic>> _privado(String uid, String doc) =>
      _usuarios.doc(uid).collection('private').doc(doc);

  Map<String, Object?> _dadosFoto(FotoPerfil foto) => {
    'imagem': Blob(foto.bytes),
    'atualizadaEm': FieldValue.serverTimestamp(),
  };

  /// `temFoto` exige a foto privada e o perfil público (research D7).
  Future<bool> _temFotoEPerfil(String uid) async {
    final resultados = await Future.wait([
      _privado(uid, 'foto').get(),
      _perfis.doc(uid).get(),
    ]);
    return resultados.every((documento) => documento.exists);
  }

  ContaErro _mapearErroAuth(FirebaseAuthException erro) => switch (erro.code) {
    'email-already-in-use' => ContaErro.emailEmUso(),
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => ContaErro.credenciaisInvalidas(),
    _ => ContaErro.indisponivel(),
  };
}
