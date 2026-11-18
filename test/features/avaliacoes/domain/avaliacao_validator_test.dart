import 'package:bicolocal/features/avaliacoes/domain/avaliacao_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const erroNota = 'Escolha uma nota de 1 a 5.';
  const erroComentario = 'O comentário pode ter até 300 caracteres.';

  group('nota', () {
    for (final nota in [null, 0, 6]) {
      test('$nota é recusada', () {
        expect(AvaliacaoValidator.validar(nota: nota, comentario: ''), {
          'nota': erroNota,
        });
      });
    }

    for (final nota in [1, 3, 5]) {
      test('$nota é aceita', () {
        expect(AvaliacaoValidator.validar(nota: nota, comentario: ''), isEmpty);
      });
    }
  });

  group('comentário (FR-004)', () {
    test('vazio é aceito', () {
      expect(AvaliacaoValidator.validar(nota: 5, comentario: ''), isEmpty);
    });

    test('só com espaços é aceito como vazio', () {
      expect(AvaliacaoValidator.validar(nota: 5, comentario: '    '), isEmpty);
      expect(AvaliacaoValidator.comentarioLimpo('   '), '');
    });

    test('300 caracteres são aceitos e 301 recusados', () {
      expect(
        AvaliacaoValidator.validar(nota: 5, comentario: 'a' * 300),
        isEmpty,
      );
      expect(AvaliacaoValidator.validar(nota: 5, comentario: 'a' * 301), {
        'comentario': erroComentario,
      });
    });

    test('espaços no início e no fim não contam', () {
      expect(
        AvaliacaoValidator.validar(nota: 5, comentario: '  ${'a' * 300}  '),
        isEmpty,
      );
    });

    test('emoji composto e letra acentuada contam como um caractere', () {
      const familia = '👨‍👩‍👧‍👦';
      final trezentos = '$familia${'é' * 299}';
      expect(trezentos.length, greaterThan(300));
      expect(
        AvaliacaoValidator.validar(nota: 5, comentario: trezentos),
        isEmpty,
      );
      expect(
        AvaliacaoValidator.validar(
          nota: 5,
          comentario:
              '$trezentos'
              'é',
        ),
        {'comentario': erroComentario},
      );
    });

    test('indica os dois campos quando os dois estão errados', () {
      expect(AvaliacaoValidator.validar(nota: null, comentario: 'a' * 301), {
        'nota': erroNota,
        'comentario': erroComentario,
      });
    });
  });
}
