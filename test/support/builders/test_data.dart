import 'package:bicolocal/features/conta/domain/conta.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:bicolocal/features/pedidos/domain/pedido.dart';

Conta criarContaTeste({
  String uid = 'conta-teste',
  String email = 'pessoa@example.com',
  String nome = 'Pessoa Teste',
  String cidade = 'São Paulo',
  String bairro = 'Centro',
  Perfil perfil = Perfil.prestador,
}) {
  return Conta(
    uid: uid,
    email: email,
    nome: nome,
    cidade: cidade,
    bairro: bairro,
    perfil: perfil,
  );
}

Pedido criarPedidoTeste({
  String id = 'pedido-teste',
  String contratanteUid = 'contratante-teste',
  String titulo = 'Montar uma estante',
  String categoriaId = 'reparos',
  String categoriaNome = 'Reparos',
  String descricao = 'Montagem de estante pequena',
  String cidade = 'São Paulo',
  String local = 'Centro',
  DateTime? dataDesejada,
  DateTime? validadeAte,
  int valorCentavos = 12000,
}) {
  return Pedido(
    id: id,
    contratanteUid: contratanteUid,
    titulo: titulo,
    categoriaId: categoriaId,
    categoriaNome: categoriaNome,
    descricao: descricao,
    cidade: cidade,
    local: local,
    dataDesejada: dataDesejada ?? DateTime.utc(2026, 10, 27),
    validadeAte: validadeAte ?? DateTime.utc(2026, 10, 26),
    valorCentavos: valorCentavos,
  );
}
