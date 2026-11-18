import 'dart:convert';
import 'dart:typed_data';

import 'package:bicolocal/features/conta/domain/conta.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:bicolocal/features/pedidos/domain/pedido.dart';
import 'package:bicolocal/features/perfil/domain/foto_perfil.dart';
import 'package:bicolocal/features/perfil/domain/perfil_publico.dart';

/// PNG de 1×1 px válido, para testes que mostram a foto.
final Uint8List _pngMinimo = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==',
);

/// Foto de teste; `marca` muda o último byte para distinguir fotos.
FotoPerfil criarFotoTeste({int marca = 0}) {
  return FotoPerfil(Uint8List.fromList([..._pngMinimo, if (marca != 0) marca]));
}

PerfilPublico criarPerfilTeste({
  String uid = 'conta-teste',
  String nome = 'Pessoa Teste',
  String cidade = 'São Paulo',
  Perfil perfil = Perfil.prestador,
  int somaNotas = 0,
  int totalAvaliacoes = 0,
}) => PerfilPublico(
  uid: uid,
  nome: nome,
  cidade: cidade,
  perfil: perfil,
  somaNotas: somaNotas,
  totalAvaliacoes: totalAvaliacoes,
);

Conta criarContaTeste({
  String uid = 'conta-teste',
  String email = 'pessoa@example.com',
  String nome = 'Pessoa Teste',
  String cidade = 'São Paulo',
  String bairro = 'Centro',
  Perfil perfil = Perfil.prestador,
  bool temFoto = true,
}) {
  return Conta(
    uid: uid,
    email: email,
    nome: nome,
    cidade: cidade,
    bairro: bairro,
    perfil: perfil,
    temFoto: temFoto,
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
