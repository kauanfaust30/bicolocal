import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/conta.dart';
import '../domain/perfil.dart';

class ContaDto {
  const ContaDto._();

  static Conta fromDocument(
    String uid,
    Map<String, dynamic> data, {
    required String email,
    bool temFoto = true,
  }) {
    final perfil = PerfilLabel.fromValue(data['perfil'] as String?);
    if (perfil == null) throw const FormatException('Perfil inválido.');
    return Conta(
      uid: uid,
      email: email,
      nome: data['nome'] as String? ?? '',
      cidade: data['cidade'] as String? ?? '',
      bairro: data['bairro'] as String? ?? '',
      perfil: perfil,
      temFoto: temFoto,
    );
  }

  /// `profiles/{uid}` recém-criado: sem foto, bairro nem e-mail, com
  /// reputação zerada (contracts/firestore-security.md).
  static Map<String, Object?> perfilPublicoNovo({
    required String nome,
    required String cidade,
    required String perfil,
  }) => {
    'nome': nome,
    'cidade': cidade,
    'perfil': perfil,
    'notaMedia': 0,
    'totalAvaliacoes': 0,
    'somaNotas': 0,
    'ultimaAvaliacaoId': null,
  };

  static Map<String, Object?> toDocument(Conta conta) => {
    'nome': conta.nome,
    'cidade': conta.cidade,
    'cidadeChave': conta.cidade.trim().toLowerCase(),
    'bairro': conta.bairro,
    'perfil': conta.perfil.name,
    'criadoEm': FieldValue.serverTimestamp(),
  };
}
