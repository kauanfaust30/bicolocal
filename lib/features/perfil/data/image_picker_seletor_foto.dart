import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/foto_erro.dart';
import '../domain/foto_perfil.dart';
import '../domain/seletor_foto.dart';

/// Usa o `image_picker` para tirar ou escolher a foto, já reduzida e
/// comprimida no aparelho (research D3).
class ImagePickerSeletorFoto implements SeletorFoto {
  ImagePickerSeletorFoto([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<FotoPerfil?> escolher(OrigemFoto origem) async {
    var bytes = await _escolher(origem, qualidade: 70);
    if (bytes == null) return null;
    if (bytes.length > FotoPerfil.tamanhoMaximoBytes) {
      bytes = await _escolher(origem, qualidade: 50);
      if (bytes == null) return null;
    }
    if (!_ehImagem(bytes)) throw FotoErro.naoImagem;
    if (bytes.isEmpty || bytes.length > FotoPerfil.tamanhoMaximoBytes) {
      throw FotoErro.grandeDemais;
    }
    return FotoPerfil(bytes);
  }

  Future<Uint8List?> _escolher(
    OrigemFoto origem, {
    required int qualidade,
  }) async {
    try {
      final arquivo = await _picker.pickImage(
        source: origem == OrigemFoto.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: qualidade,
        preferredCameraDevice: CameraDevice.front,
      );
      return arquivo == null ? null : await arquivo.readAsBytes();
    } on PlatformException catch (erro) {
      if (erro.code == 'camera_access_denied' ||
          erro.code == 'photo_access_denied') {
        throw FotoErro.semPermissao(origem);
      }
      throw FotoErro.naoImagem;
    }
  }

  /// JPEG, PNG, GIF ou WebP, pelos primeiros bytes do arquivo.
  static bool _ehImagem(Uint8List b) {
    bool comeca(List<int> assinatura) =>
        b.length >= assinatura.length &&
        Iterable.generate(assinatura.length)
            .every((i) => b[i] == assinatura[i]);
    return comeca(const [0xFF, 0xD8, 0xFF]) ||
        comeca(const [0x89, 0x50, 0x4E, 0x47]) ||
        comeca(const [0x47, 0x49, 0x46, 0x38]) ||
        (comeca(const [0x52, 0x49, 0x46, 0x46]) &&
            b.length >= 12 &&
            b[8] == 0x57 &&
            b[9] == 0x45 &&
            b[10] == 0x42 &&
            b[11] == 0x50);
  }
}
