import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Verificação estática de `firestore.rules`: estes testes não executam as
/// regras (isso exigiria o emulador do Firebase), só conferem o texto da
/// regra de `update` em `users/{uid}`.
void main() {
  String regraUpdateUsuarios() {
    final regras = File('firestore.rules').readAsStringSync();
    final inicioBloco = regras.indexOf('match /users/{uid}');
    expect(inicioBloco, isNot(-1), reason: 'bloco users/{uid} não encontrado');
    final inicio = regras.indexOf('allow update:', inicioBloco);
    final fim = regras.indexOf('allow delete:', inicio);
    expect(inicio, isNot(-1), reason: 'regra de update não encontrada');
    expect(fim, isNot(-1), reason: 'fim da regra de update não encontrado');
    return regras.substring(inicio, fim);
  }

  test('update de users/{uid} não lista perfil entre os campos editáveis', () {
    final regra = regraUpdateUsuarios();
    final campos = RegExp(r'affectedKeys\(\)\.hasOnly\(\[([^\]]*)\]\)')
        .firstMatch(regra);

    expect(campos, isNotNull);
    expect(campos!.group(1), isNot(contains("'perfil'")));
  });

  test('update de users/{uid} exige que o perfil continue o mesmo', () {
    expect(
      regraUpdateUsuarios(),
      contains('request.resource.data.perfil == resource.data.perfil'),
    );
  });
}
