import '../../perfil/domain/foto_perfil.dart';
import 'candidatura.dart';

abstract interface class CandidaturaRepository {
  Future<Candidatura?> buscar({
    required String pedidoId,
    required String prestadorUid,
  });

  Future<List<Candidatura>> listar({required String pedidoId});

  /// Grava a candidatura, o contato e, se houver, a cópia da foto do
  /// prestador em `applications/{uid}/private/foto`, na mesma transação.
  Future<void> candidatar(
    Candidatura candidatura, {
    required String emailPrestador,
    FotoPerfil? foto,
  });

  /// Aceita a candidatura e grava, se houver, a cópia da foto do contratante
  /// em `fotos/{contratanteUid}`, na mesma transação.
  Future<void> aceitar({
    required String pedidoId,
    required String prestadorUid,
    required String emailContratante,
    required DateTime agoraUtc,
    FotoPerfil? fotoContratante,
  });

  /// Cópia da foto do prestador neste pedido; só legível pelo contratante
  /// depois do aceite (FR-020).
  Future<FotoPerfil?> carregarFotoDoPrestador({
    required String pedidoId,
    required String prestadorUid,
  });

  /// Cópia da foto do contratante neste pedido; só legível pelas partes
  /// depois do aceite (FR-020).
  Future<FotoPerfil?> carregarFotoDoContratante({
    required String pedidoId,
    required String contratanteUid,
  });

  Future<String?> carregarEmailPrestador({
    required String pedidoId,
    required String prestadorUid,
  });

  Future<String?> carregarEmailContratante({
    required String pedidoId,
    required String contratanteUid,
  });
}
