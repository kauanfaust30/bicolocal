import 'conta.dart';
import 'perfil.dart';

abstract interface class ContaRepository {
  Stream<Conta?> observarSessao();

  Future<Conta> cadastrar({
    required String email,
    required String senha,
    required String nome,
    required String cidade,
    required String bairro,
    required Perfil perfil,
  });

  Future<Conta> entrar({required String email, required String senha});

  Future<void> sair();
}
