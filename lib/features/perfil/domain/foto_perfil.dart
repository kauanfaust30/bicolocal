import 'dart:typed_data';

enum OrigemFoto { camera, galeria }

/// Foto de perfil já reduzida (cerca de 300 px, JPEG).
class FotoPerfil {
  const FotoPerfil(this.bytes);

  /// Limite aceito pelas regras de `users/{uid}/private/foto`.
  static const tamanhoMaximoBytes = 204800;

  final Uint8List bytes;
}
