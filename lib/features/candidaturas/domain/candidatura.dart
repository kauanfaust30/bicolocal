enum EstadoCandidatura { pendente, aceita, recusada }

class Candidatura {
  const Candidatura({
    required this.pedidoId,
    required this.prestadorUid,
    required this.estado,
  });

  final String pedidoId;
  final String prestadorUid;
  final EstadoCandidatura estado;

  Candidatura copyWith({EstadoCandidatura? estado}) => Candidatura(
    pedidoId: pedidoId,
    prestadorUid: prestadorUid,
    estado: estado ?? this.estado,
  );
}
