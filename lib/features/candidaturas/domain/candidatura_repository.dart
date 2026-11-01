import 'candidatura.dart';

abstract interface class CandidaturaRepository {
  Future<Candidatura?> buscar({
    required String pedidoId,
    required String prestadorUid,
  });

  Future<List<Candidatura>> listar({required String pedidoId});

  Future<void> candidatar(
    Candidatura candidatura, {
    required String emailPrestador,
  });

  Future<void> aceitar({
    required String pedidoId,
    required String prestadorUid,
    required String emailContratante,
    required DateTime agoraUtc,
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
