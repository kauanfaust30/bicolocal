import 'perfil.dart';

class Conta {
  const Conta({
    required this.uid,
    required this.email,
    required this.nome,
    required this.cidade,
    required this.bairro,
    required this.perfil,
    this.temFoto = true,
  });

  final String uid;
  final String email;
  final String nome;
  final String cidade;
  final String bairro;
  final Perfil perfil;

  /// Falso quando faltam a foto privada ou o perfil público (contas da 001);
  /// a pessoa é levada a Adicionar foto (FR-018).
  final bool temFoto;

  Conta copyWith({Perfil? perfil, bool? temFoto}) => Conta(
    uid: uid,
    email: email,
    nome: nome,
    cidade: cidade,
    bairro: bairro,
    perfil: perfil ?? this.perfil,
    temFoto: temFoto ?? this.temFoto,
  );
}
