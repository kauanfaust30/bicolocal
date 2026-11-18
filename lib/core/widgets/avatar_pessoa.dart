import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Foto da pessoa ou, quando não há foto visível (FR-020), a inicial do nome.
/// Rótulos acessíveis "Foto de {nome}" e "Inicial de {nome}" (FR-024).
class AvatarPessoa extends StatelessWidget {
  const AvatarPessoa({
    super.key,
    required this.nome,
    this.bytes,
    this.tamanho = 48,
  });

  final String nome;
  final Uint8List? bytes;
  final double tamanho;

  String get _inicial {
    final texto = nome.trim();
    return texto.isEmpty ? '?' : texto.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final lado = math.max(tamanho, 48.0);
    final cores = Theme.of(context).colorScheme;
    final foto = bytes;
    return Semantics(
      // Nó próprio: o rótulo não se mistura ao texto ao lado (nome, botões).
      container: true,
      label: foto == null ? 'Inicial de $nome' : 'Foto de $nome',
      image: foto != null,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: lado,
        child: CircleAvatar(
          backgroundColor: cores.secondaryContainer,
          foregroundColor: cores.onSecondaryContainer,
          child: foto == null
              ? Text(
                  _inicial,
                  style: TextStyle(
                    fontSize: lado * 0.42,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : ClipOval(
                  child: Image.memory(
                    foto,
                    width: lado,
                    height: lado,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
        ),
      ),
    );
  }
}
