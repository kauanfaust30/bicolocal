import 'package:bicolocal/core/registro_falha.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String?> impressas;
  late DebugPrintCallback original;

  setUp(() {
    impressas = [];
    original = debugPrint;
    debugPrint = (mensagem, {wrapWidth}) => impressas.add(mensagem);
  });

  tearDown(() => debugPrint = original);

  test('imprime tipo, código e mensagem de FirebaseException', () {
    registrarFalha(
      'Falha ao criar conta no Firestore',
      FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Missing or insufficient permissions.',
      ),
    );

    expect(impressas, hasLength(1));
    expect(impressas.single, contains('Falha ao criar conta no Firestore'));
    expect(impressas.single, contains('FirebaseException'));
    expect(impressas.single, contains('permission-denied'));
    expect(impressas.single, contains('Missing or insufficient permissions.'));
  });

  test('imprime tipo e mensagem de outras exceções, sem código', () {
    registrarFalha('Falha ao enviar foto', StateError('sem conexão'));

    expect(impressas, hasLength(1));
    expect(impressas.single, contains('StateError'));
    expect(impressas.single, contains('código: -'));
    expect(impressas.single, contains('sem conexão'));
  });
}
