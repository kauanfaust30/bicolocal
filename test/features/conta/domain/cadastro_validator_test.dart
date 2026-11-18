import 'package:bicolocal/features/conta/domain/cadastro_validator.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/builders/test_data.dart';

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
        foto: criarFotoTeste(),
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
        foto: null,
      );

      expect(
        erros.keys,
        containsAll([
          'email',
          'senha',
          'nome',
          'cidade',
          'bairro',
          'perfil',
          'foto',
        ]),
      );
      expect(erros['foto'], 'Adicione uma foto para concluir o cadastro.');
      expect(erros.values.every((mensagem) => mensagem.isNotEmpty), isTrue);
    });
  });
}
