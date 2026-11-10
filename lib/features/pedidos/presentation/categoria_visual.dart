import 'package:flutter/material.dart';

import '../domain/categoria.dart';

/// Ícone e cores de cada categoria. Só afeta a apresentação.
class CategoriaVisual {
  const CategoriaVisual._(this.icone, this.cor, this.fundo);

  final IconData icone;

  /// Cor do ícone, sobre [fundo].
  final Color cor;
  final Color fundo;

  static const _conhecidas = {
    'limpeza': CategoriaVisual._(
      Icons.cleaning_services,
      Color(0xFF00658F),
      Color(0xFFD6EEF8),
    ),
    'pintura': CategoriaVisual._(
      Icons.format_paint,
      Color(0xFF7B3D93),
      Color(0xFFF1E1F7),
    ),
    'jardinagem': CategoriaVisual._(
      Icons.yard,
      Color(0xFF2E6B30),
      Color(0xFFDCF2DC),
    ),
    'reparos': CategoriaVisual._(
      Icons.home_repair_service,
      Color(0xFF9A4600),
      Color(0xFFFFE0C7),
    ),
  };

  static const _padrao = CategoriaVisual._(
    Icons.work_outline,
    Color(0xFF44505F),
    Color(0xFFE3E7EE),
  );

  /// Procura pelo id e, se não achar, pelo nome da categoria.
  static CategoriaVisual de({required String id, String? nome}) =>
      _conhecidas[_normalizar(id)] ??
      (nome == null ? null : _conhecidas[_normalizar(nome)]) ??
      _padrao;

  static CategoriaVisual daCategoria(Categoria categoria) =>
      de(id: categoria.id, nome: categoria.nome);

  static String _normalizar(String texto) {
    const acentos = {
      'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'é': 'e', 'ê': 'e', //
      'í': 'i', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ú': 'u', 'ç': 'c',
    };
    final minusculo = texto.trim().toLowerCase();
    return minusculo.split('').map((letra) => acentos[letra] ?? letra).join();
  }
}

/// Ícone da categoria dentro de um círculo colorido.
class IconeCategoria extends StatelessWidget {
  const IconeCategoria({super.key, required this.visual, this.raio = 24});

  final CategoriaVisual visual;
  final double raio;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: raio,
    backgroundColor: visual.fundo,
    child: Icon(visual.icone, color: visual.cor, size: raio),
  );
}
