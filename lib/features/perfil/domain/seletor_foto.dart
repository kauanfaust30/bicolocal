import 'foto_perfil.dart';

/// Abre a câmera ou a galeria e devolve a foto já reduzida.
///
/// Devolve `null` quando a pessoa cancela a escolha e lança `FotoErro`
/// quando o acesso é negado ou a imagem não serve.
abstract interface class SeletorFoto {
  Future<FotoPerfil?> escolher(OrigemFoto origem);
}
