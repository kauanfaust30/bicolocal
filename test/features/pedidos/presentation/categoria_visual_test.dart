import 'package:bicolocal/features/pedidos/domain/categoria.dart';
import 'package:bicolocal/features/pedidos/presentation/categoria_visual.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cada categoria conhecida tem ícone próprio', () {
    final esperados = {
      'limpeza': Icons.cleaning_services,
      'pintura': Icons.format_paint,
      'jardinagem': Icons.yard,
      'reparos': Icons.home_repair_service,
    };

    for (final MapEntry(key: id, value: icone) in esperados.entries) {
      expect(CategoriaVisual.de(id: id).icone, icone, reason: id);
    }
  });

  test('reconhece a categoria pelo nome quando o id é diferente', () {
    expect(
      CategoriaVisual.de(id: 'cat-7', nome: 'Jardinagem').icone,
      Icons.yard,
    );
    expect(
      CategoriaVisual.de(id: 'x', nome: 'Pintura').icone,
      Icons.format_paint,
    );
  });

  test('categoria desconhecida usa o ícone padrão', () {
    expect(CategoriaVisual.de(id: 'mudanca').icone, Icons.work_outline);
  });

  test('categorias diferentes têm cores diferentes e com contraste', () {
    final visuais = [
      for (final id in ['limpeza', 'pintura', 'jardinagem', 'reparos', 'x'])
        CategoriaVisual.de(id: id),
    ];

    expect(visuais.map((v) => v.cor).toSet(), hasLength(visuais.length));
    for (final visual in visuais) {
      final claro = visual.fundo.computeLuminance();
      final escuro = visual.cor.computeLuminance();
      expect((claro + 0.05) / (escuro + 0.05), greaterThan(3));
    }
  });

  test('aceita uma Categoria diretamente', () {
    const categoria = Categoria(id: 'limpeza', nome: 'Limpeza');

    expect(
      CategoriaVisual.daCategoria(categoria).icone,
      Icons.cleaning_services,
    );
  });
}
