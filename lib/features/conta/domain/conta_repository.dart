import '../../perfil/domain/foto_perfil.dart';
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
    required FotoPerfil foto,
  });

  /// Grava a foto de uma conta existente sem foto e cria o perfil público se
  /// faltar. Lança `FotoErro.envioFalhou` se não conseguir.
  Future<void> adicionarFoto(FotoPerfil foto);

  Future<Conta> entrar({required String email, required String senha});

  Future<void> sair();
}
