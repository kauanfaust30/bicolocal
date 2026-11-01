enum EstadoPedido { aberto, emAndamento, cancelado }

class Pedido {
  const Pedido({
    required this.id,
    required this.contratanteUid,
    required this.titulo,
    required this.categoriaId,
    required this.categoriaNome,
    required this.descricao,
    required this.cidade,
    required this.local,
    required this.dataDesejada,
    required this.validadeAte,
    required this.valorCentavos,
    this.estado = EstadoPedido.aberto,
    this.prestadorEscolhidoUid,
  });

  final String id;
  final String contratanteUid;
  final String titulo;
  final String categoriaId;
  final String categoriaNome;
  final String descricao;
  final String cidade;
  final String local;
  final DateTime dataDesejada;
  final DateTime validadeAte;
  final int valorCentavos;
  final EstadoPedido estado;
  final String? prestadorEscolhidoUid;

  Pedido copyWith({
    String? titulo,
    String? categoriaId,
    String? categoriaNome,
    String? descricao,
    String? cidade,
    String? local,
    DateTime? dataDesejada,
    DateTime? validadeAte,
    int? valorCentavos,
    EstadoPedido? estado,
    String? prestadorEscolhidoUid,
  }) => Pedido(
    id: id,
    contratanteUid: contratanteUid,
    titulo: titulo ?? this.titulo,
    categoriaId: categoriaId ?? this.categoriaId,
    categoriaNome: categoriaNome ?? this.categoriaNome,
    descricao: descricao ?? this.descricao,
    cidade: cidade ?? this.cidade,
    local: local ?? this.local,
    dataDesejada: dataDesejada ?? this.dataDesejada,
    validadeAte: validadeAte ?? this.validadeAte,
    valorCentavos: valorCentavos ?? this.valorCentavos,
    estado: estado ?? this.estado,
    prestadorEscolhidoUid: prestadorEscolhidoUid ?? this.prestadorEscolhidoUid,
  );
}
