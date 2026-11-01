import 'perfil.dart';

class CadastroValidator {
  static Map<String, String> validar({
    required String email,
    required String senha,
    required String nome,
    required String cidade,
    required String bairro,
    required Perfil? perfil,
  }) {
    final erros = <String, String>{};
    final emailLimpo = email.trim();

    if (emailLimpo.isEmpty) {
      erros['email'] = 'Informe seu e-mail.';
    } else if (!emailValido(emailLimpo)) {
      erros['email'] = 'Informe um e-mail válido.';
    }
    if (senha.trim().isEmpty) erros['senha'] = 'Informe sua senha.';
    if (nome.trim().isEmpty) erros['nome'] = 'Informe seu nome.';
    if (cidade.trim().isEmpty) erros['cidade'] = 'Informe sua cidade.';
    if (bairro.trim().isEmpty) erros['bairro'] = 'Informe seu bairro.';
    if (perfil == null) erros['perfil'] = 'Escolha um perfil.';
    return erros;
  }

  static bool emailValido(String email) {
    final separador = email.indexOf('@');
    return separador > 0 &&
        separador < email.length - 1 &&
        !email.contains(' ');
  }
}
