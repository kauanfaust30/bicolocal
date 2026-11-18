import '../../perfil/domain/foto_perfil.dart';
import 'cadastro_validator.dart';
import 'conta.dart';
import 'conta_erro.dart';
import 'conta_repository.dart';
import 'perfil.dart';

class ContaService {
  const ContaService(this._repository);

  final ContaRepository _repository;

  Future<Conta> cadastrar({
    required String email,
    required String senha,
    required String nome,
    required String cidade,
    required String bairro,
    required Perfil? perfil,
    required FotoPerfil? foto,
  }) async {
    final erros = CadastroValidator.validar(
      email: email,
      senha: senha,
      nome: nome,
      cidade: cidade,
      bairro: bairro,
      perfil: perfil,
      foto: foto,
    );
    if (erros.isNotEmpty) throw ContaValidacaoErro(erros);

    return _repository.cadastrar(
      email: email.trim(),
      senha: senha,
      nome: nome.trim(),
      cidade: cidade.trim(),
      bairro: bairro.trim(),
      perfil: perfil!,
      foto: foto!,
    );
  }

  Future<void> adicionarFoto(FotoPerfil foto) =>
      _repository.adicionarFoto(foto);

  Future<Conta> entrar({required String email, required String senha}) {
    final erros = <String, String>{};
    if (email.trim().isEmpty || !CadastroValidator.emailValido(email.trim())) {
      erros['email'] = 'Informe um e-mail válido.';
    }
    if (senha.trim().isEmpty) erros['senha'] = 'Informe sua senha.';
    if (erros.isNotEmpty) throw ContaValidacaoErro(erros);
    return _repository.entrar(email: email.trim(), senha: senha);
  }

  Future<void> sair() => _repository.sair();
}
