import '../../conta/domain/perfil.dart';

/// Dados de `profiles/{uid}` que qualquer pessoa autenticada pode ler
/// (FR-015). Nunca contém foto, bairro nem e-mail.
class PerfilPublico {
  const PerfilPublico({
    required this.uid,
    required this.nome,
    required this.cidade,
    required this.perfil,
    required this.somaNotas,
    required this.totalAvaliacoes,
  });

  final String uid;
  final String nome;
  final String cidade;
  final Perfil perfil;
  final int somaNotas;
  final int totalAvaliacoes;

  bool get semAvaliacoes => totalAvaliacoes == 0;

  /// Média com uma casa decimal, arredondada meio para cima e com vírgula
  /// (FR-009). Calculada com inteiros para não sofrer erro de ponto
  /// flutuante: 4,65 vira 4,7.
  String? get notaExibida {
    if (semAvaliacoes) return null;
    final decimos = (somaNotas * 20 + totalAvaliacoes) ~/ (totalAvaliacoes * 2);
    return '${decimos ~/ 10},${decimos % 10}';
  }
}
