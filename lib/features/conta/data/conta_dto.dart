import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/conta.dart';
import '../domain/perfil.dart';

class ContaDto {
  const ContaDto._();

  static Conta fromDocument(
    String uid,
    Map<String, dynamic> data, {
    required String email,
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
    );
  }

  static Map<String, Object?> toDocument(Conta conta) => {
    'nome': conta.nome,
    'cidade': conta.cidade,
    'cidadeChave': conta.cidade.trim().toLowerCase(),
    'bairro': conta.bairro,
    'perfil': conta.perfil.name,
    'criadoEm': FieldValue.serverTimestamp(),
  };
}
