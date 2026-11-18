import 'package:characters/characters.dart';

class AvaliacaoValidator {
  const AvaliacaoValidator._();

  static const comentarioMaximo = 300;

  /// Comentário sem espaços no início e no fim; só espaços vira vazio (FR-004).
  static String comentarioLimpo(String comentario) => comentario.trim();

  /// Caracteres visíveis: emoji composto e letra acentuada contam como um.
  static int tamanhoComentario(String comentario) =>
      comentarioLimpo(comentario).characters.length;

  /// Erros por campo (`nota`, `comentario`); vazio quando está tudo certo.
  static Map<String, String> validar({
    required int? nota,
    required String comentario,
  }) => {
    if (nota == null || nota < 1 || nota > 5)
      'nota': 'Escolha uma nota de 1 a 5.',
    if (tamanhoComentario(comentario) > comentarioMaximo)
      'comentario': 'O comentário pode ter até 300 caracteres.',
  };
}
