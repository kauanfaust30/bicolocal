import 'perfil.dart';

class Conta {
  const Conta({
    required this.uid,
    required this.email,
    required this.nome,
    required this.cidade,
    required this.bairro,
    required this.perfil,
  });

  final String uid;
  final String email;
  final String nome;
  final String cidade;
  final String bairro;
  final Perfil perfil;

  Conta copyWith({Perfil? perfil}) => Conta(
    uid: uid,
    email: email,
    nome: nome,
    cidade: cidade,
    bairro: bairro,
    perfil: perfil ?? this.perfil,
  );
}
