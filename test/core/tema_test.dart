import 'dart:math' as math;

import 'package:bicolocal/core/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes/fake_repositories.dart';

double _contraste(Color a, Color b) {
  final claro = math.max(a.computeLuminance(), b.computeLuminance());
  final escuro = math.min(a.computeLuminance(), b.computeLuminance());
  return (claro + 0.05) / (escuro + 0.05);
}

BorderRadius? _raio(OutlinedBorder? borda) =>
    borda is RoundedRectangleBorder ? borda.borderRadius as BorderRadius : null;

void main() {
  late ThemeData tema;

  Future<void> carregarTema(WidgetTester tester) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(),
        pedidoRepository: FakePedidoRepository(),
        candidaturaRepository: FakeCandidaturaRepository(),
      ),
    );
    tema = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
  }

  testWidgets(
    'usa Material 3 com destaque quente e ação secundária verde-água',
    (tester) async {
      await carregarTema(tester);
      final cores = tema.colorScheme;

      expect(tema.useMaterial3, isTrue);
      expect(cores.brightness, Brightness.light);
      final matizPrimaria = HSVColor.fromColor(cores.primary).hue;
      expect(matizPrimaria, inInclusiveRange(15, 50), reason: 'laranja/âmbar');
      final matizSecundaria = HSVColor.fromColor(cores.secondary).hue;
      expect(matizSecundaria, inInclusiveRange(165, 195), reason: 'verde-água');
    },
  );

  testWidgets('cores de texto sobre destaque têm contraste mínimo de 4,5:1', (
    tester,
  ) async {
    await carregarTema(tester);
    final cores = tema.colorScheme;

    expect(_contraste(cores.primary, cores.onPrimary), greaterThan(4.5));
    expect(_contraste(cores.secondary, cores.onSecondary), greaterThan(4.5));
    expect(_contraste(cores.surface, cores.onSurface), greaterThan(4.5));
  });

  testWidgets('cartões, botões e campos têm cantos de 12 a 16 px', (
    tester,
  ) async {
    await carregarTema(tester);
    final faixa = inInclusiveRange(12.0, 16.0);

    final cartao = tema.cardTheme.shape as RoundedRectangleBorder;
    expect((cartao.borderRadius as BorderRadius).topLeft.x, faixa);
    final campo = tema.inputDecorationTheme.border as OutlineInputBorder;
    expect(campo.borderRadius.topLeft.x, faixa);
    for (final estilo in [
      tema.elevatedButtonTheme.style,
      tema.outlinedButtonTheme.style,
      tema.textButtonTheme.style,
    ]) {
      final raio = _raio(estilo!.shape!.resolve({}));
      expect(raio!.topLeft.x, faixa);
    }
  });

  testWidgets('botões têm altura mínima de 48 e corpo de texto de 16 px', (
    tester,
  ) async {
    await carregarTema(tester);

    for (final estilo in [
      tema.elevatedButtonTheme.style,
      tema.outlinedButtonTheme.style,
      tema.textButtonTheme.style,
    ]) {
      expect(
        estilo!.minimumSize!.resolve({})!.height,
        greaterThanOrEqualTo(48),
      );
    }
    expect(tema.textTheme.bodyMedium!.fontSize, 16);
    expect(tema.textTheme.bodyLarge!.fontSize, 16);
    expect(
      tema.textTheme.titleLarge!.fontWeight!.value,
      greaterThanOrEqualTo(FontWeight.w600.value),
    );
  });
}
