import 'package:bicolocal/core/widgets/avatar_pessoa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/builders/test_data.dart';

Future<void> _mostrar(WidgetTester tester, Widget avatar) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: Center(child: avatar)),
  ),
);

void main() {
  testWidgets('com foto mostra a imagem com rótulo "Foto de {nome}"', (
    tester,
  ) async {
    await _mostrar(
      tester,
      AvatarPessoa(nome: 'Ana Souza', bytes: criarFotoTeste().bytes),
    );

    expect(find.bySemanticsLabel('Foto de Ana Souza'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('A'), findsNothing);
  });

  testWidgets('sem foto mostra a inicial com rótulo "Inicial de {nome}"', (
    tester,
  ) async {
    await _mostrar(tester, const AvatarPessoa(nome: 'bruno lima'));

    expect(find.text('B'), findsOneWidget);
    expect(find.bySemanticsLabel('Inicial de bruno lima'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('tem pelo menos 48 dp', (tester) async {
    await _mostrar(tester, const AvatarPessoa(nome: 'Ana', tamanho: 32));

    final tamanho = tester.getSize(find.byType(AvatarPessoa));
    expect(tamanho.width, greaterThanOrEqualTo(48));
    expect(tamanho.height, greaterThanOrEqualTo(48));
  });
}
