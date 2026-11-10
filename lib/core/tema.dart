import 'package:flutter/material.dart';

/// Tema único do BicoLocal: laranja/âmbar para destaque, verde-água para
/// ações secundárias, fundo claro e cantos arredondados.
ThemeData criarTemaBicoLocal() {
  final cores = ColorScheme.fromSeed(
    seedColor: const Color(0xFFF57C00),
    secondary: const Color(0xFF00696B),
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFB2EBEC),
    onSecondaryContainer: const Color(0xFF002020),
  );
  const raioCampo = BorderRadius.all(Radius.circular(12));
  const formatoBotao = RoundedRectangleBorder(borderRadius: raioCampo);
  const tamanhoMinimo = Size(64, 48);

  final textoBase = ThemeData(useMaterial3: true).textTheme;
  final texto = textoBase.copyWith(
    headlineSmall: textoBase.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
    ),
    titleLarge: textoBase.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    titleMedium: textoBase.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    bodyLarge: textoBase.bodyLarge?.copyWith(fontSize: 16, height: 1.4),
    bodyMedium: textoBase.bodyMedium?.copyWith(fontSize: 16, height: 1.4),
    labelLarge: textoBase.labelLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: cores,
    textTheme: texto,
    scaffoldBackgroundColor: cores.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: cores.surface,
      foregroundColor: cores.onSurface,
      centerTitle: false,
      titleTextStyle: texto.titleLarge?.copyWith(color: cores.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cores.surfaceContainerLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: cores.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cores.surfaceContainerLowest,
      border: const OutlineInputBorder(borderRadius: raioCampo),
      enabledBorder: OutlineInputBorder(
        borderRadius: raioCampo,
        borderSide: BorderSide(color: cores.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: raioCampo,
        borderSide: BorderSide(color: cores.primary, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: cores.primary,
        foregroundColor: cores.onPrimary,
        textStyle: texto.labelLarge,
        shape: formatoBotao,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: tamanhoMinimo,
        foregroundColor: cores.secondary,
        side: BorderSide(color: cores.secondary),
        textStyle: texto.labelLarge,
        shape: formatoBotao,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: tamanhoMinimo,
        foregroundColor: cores.secondary,
        textStyle: texto.labelLarge,
        shape: formatoBotao,
      ),
    ),
  );
}
