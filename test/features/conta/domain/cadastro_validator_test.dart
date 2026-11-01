import 'package:bicolocal/features/conta/domain/cadastro_validator.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CadastroValidator', () {
    test('aceita todos os campos válidos', () {
      final erros = CadastroValidator.validar(
        email: 'ana@example.com',
        senha: 'senha-segura',
        nome: 'Ana Silva',
        cidade: 'São Paulo',
        bairro: 'Centro',
        perfil: Perfil.contratante,
      );

      expect(erros, isEmpty);
    });

    test('indica cada campo obrigatório ausente ou inválido', () {
      final erros = CadastroValidator.validar(
        email: 'invalido',
        senha: '',
        nome: ' ',
        cidade: '',
        bairro: '',
        perfil: null,
      );

      expect(
        erros.keys,
        containsAll(['email', 'senha', 'nome', 'cidade', 'bairro', 'perfil']),
      );
      expect(erros.values.every((mensagem) => mensagem.isNotEmpty), isTrue);
    });
  });
}
