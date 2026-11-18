import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:bicolocal/features/perfil/domain/perfil_publico.dart';
import 'package:flutter_test/flutter_test.dart';

PerfilPublico _perfil({required int soma, required int total}) => PerfilPublico(
  uid: 'pessoa-1',
  nome: 'Ana Souza',
  cidade: 'Rio do Sul',
  perfil: Perfil.prestador,
  somaNotas: soma,
  totalAvaliacoes: total,
);

void main() {
  test('sem avaliações não tem nota exibida', () {
    final perfil = _perfil(soma: 0, total: 0);

    expect(perfil.semAvaliacoes, isTrue);
    expect(perfil.notaExibida, isNull);
  });

  test('nota média com uma casa decimal, meio para cima e vírgula', () {
    expect(_perfil(soma: 93, total: 20).notaExibida, '4,7'); // 4,65
    expect(_perfil(soma: 9, total: 2).notaExibida, '4,5');
    expect(_perfil(soma: 14, total: 3).notaExibida, '4,7'); // 4,666…
    expect(_perfil(soma: 5, total: 1).notaExibida, '5,0');
    expect(_perfil(soma: 61, total: 20).notaExibida, '3,1'); // 3,05
  });

  test('com avaliações não está vazio', () {
    expect(_perfil(soma: 4, total: 1).semAvaliacoes, isFalse);
  });
}
