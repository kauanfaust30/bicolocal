import 'foto_perfil.dart';
import 'perfil_publico.dart';

abstract interface class PerfilRepository {
  /// Lê `profiles/{uid}`; `null` se ainda não existir.
  Future<PerfilPublico?> carregarPerfil(String uid);

  /// Foto privada da pessoa autenticada; `null` se ainda não enviou.
  Future<FotoPerfil?> carregarFotoPropria();

  /// Grava ou troca a foto privada da pessoa autenticada. Lança
  /// `FotoErro.envioFalhou` se não conseguir; a foto anterior continua valendo.
  Future<void> salvarFotoPropria(FotoPerfil foto);
}
