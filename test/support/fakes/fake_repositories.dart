import 'dart:async';

import 'package:bicolocal/features/conta/domain/conta.dart';
import 'package:bicolocal/features/conta/domain/conta_repository.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:bicolocal/features/candidaturas/domain/candidatura.dart';
import 'package:bicolocal/features/candidaturas/domain/candidatura_repository.dart';
import 'package:bicolocal/features/pedidos/domain/categoria.dart';
import 'package:bicolocal/features/pedidos/domain/data_civil.dart';
import 'package:bicolocal/features/pedidos/domain/pedido.dart';
import 'package:bicolocal/features/pedidos/domain/pedido_repository.dart';

class FakeContaRepository implements ContaRepository {
  FakeContaRepository({this.contaInicial})
    : _sessao = StreamController<Conta?>.broadcast(sync: true);

  Conta? contaInicial;
  final StreamController<Conta?> _sessao;

  @override
  Stream<Conta?> observarSessao() => Stream<Conta?>.multi((controller) {
    controller.add(contaInicial);
    final subscription = _sessao.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  void publicarConta(Conta? conta) {
    contaInicial = conta;
    _sessao.add(conta);
  }

  Future<void> dispose() => _sessao.close();

  @override
  Future<Conta> cadastrar({
    required String email,
    required String senha,
    required String nome,
    required String cidade,
    required String bairro,
    required Perfil perfil,
  }) async {
    contaInicial = Conta(
      uid: 'conta-falsa',
      email: email,
      nome: nome,
      cidade: cidade,
      bairro: bairro,
      perfil: perfil,
    );
    publicarConta(contaInicial);
    return contaInicial!;
  }

  @override
  Future<Conta> entrar({required String email, required String senha}) async {
    return contaInicial ??
        const Conta(
          uid: 'conta-falsa',
          email: 'teste@example.com',
          nome: 'Pessoa Teste',
          cidade: 'São Paulo',
          bairro: 'Centro',
          perfil: Perfil.prestador,
        );
  }

  @override
  Future<void> sair() async {
    publicarConta(null);
  }
}

class FakePedidoRepository implements PedidoRepository {
  FakePedidoRepository({
    List<Categoria> categorias = const [],
    List<Pedido> pedidos = const [],
    this.falhasRestantes = 0,
    this.falhaListarAbertos,
    this.falhasCategoriasRestantes = 0,
  }) : categorias = categorias.toList(),
       pedidos = pedidos.toList();

  final List<Categoria> categorias;
  final List<Pedido> pedidos;
  int falhasRestantes;
  Object? falhaListarAbertos;
  int falhasCategoriasRestantes;
  bool falharAtualizacao = false;

  @override
  Future<List<Categoria>> carregarCategorias() async {
    if (falhasCategoriasRestantes > 0) {
      falhasCategoriasRestantes -= 1;
      throw Exception('Falha de teste ao carregar categorias');
    }
    return categorias;
  }

  @override
  Future<List<Pedido>> listarAbertos({
    required String cidade,
    required String dataCivil,
    String? categoriaId,
  }) async {
    if (falhaListarAbertos case final falha?) throw falha;
    if (falhasRestantes > 0) {
      falhasRestantes -= 1;
      throw Exception('Falha de teste');
    }
    return pedidos
        .where((pedido) => pedido.cidade.toLowerCase() == cidade.toLowerCase())
        .where(
          (pedido) => categoriaId == null || pedido.categoriaId == categoriaId,
        )
        .where(
          (pedido) =>
              DataCivil.chave(pedido.validadeAte).compareTo(dataCivil) >= 0,
        )
        .toList();
  }

  @override
  Future<void> publicar(Pedido pedido) async {}

  @override
  Future<List<Pedido>> listarGerenciaveis({required String uid}) async =>
      pedidos
          .where(
            (pedido) =>
                pedido.contratanteUid == uid ||
                pedido.prestadorEscolhidoUid == uid,
          )
          .toList();

  @override
  Future<Pedido?> buscar({required String pedidoId}) async {
    for (final pedido in pedidos) {
      if (pedido.id == pedidoId) return pedido;
    }
    return null;
  }

  @override
  Future<void> atualizar({
    required Pedido pedido,
    required String editorUid,
    required DateTime agoraUtc,
  }) async {
    if (falharAtualizacao) throw Exception('Falha de teste');
    final index = pedidos.indexWhere((item) => item.id == pedido.id);
    if (index >= 0) pedidos[index] = pedido;
  }

  @override
  Future<void> cancelar({
    required String pedidoId,
    required String editorUid,
    required DateTime agoraUtc,
  }) async {
    final index = pedidos.indexWhere((item) => item.id == pedidoId);
    if (index >= 0) {
      pedidos[index] = pedidos[index].copyWith(estado: EstadoPedido.cancelado);
    }
  }
}

class FakeCandidaturaRepository implements CandidaturaRepository {
  FakeCandidaturaRepository({List<Candidatura> itens = const []})
    : itens = itens.toList();

  final List<Candidatura> itens;
  final Map<String, String> emailsPrestadores = {};
  final Map<String, String> emailsContratantes = {};
  int candidaturasCriadas = 0;

  @override
  Future<Candidatura?> buscar({
    required String pedidoId,
    required String prestadorUid,
  }) async {
    for (final candidatura in itens) {
      if (candidatura.pedidoId == pedidoId &&
          candidatura.prestadorUid == prestadorUid) {
        return candidatura;
      }
    }
    return null;
  }

  @override
  Future<List<Candidatura>> listar({required String pedidoId}) async =>
      itens.where((item) => item.pedidoId == pedidoId).toList();

  @override
  Future<void> candidatar(
    Candidatura candidatura, {
    required String emailPrestador,
  }) async {
    candidaturasCriadas++;
    itens.add(candidatura);
    emailsPrestadores['${candidatura.pedidoId}:${candidatura.prestadorUid}'] =
        emailPrestador;
  }

  @override
  Future<void> aceitar({
    required String pedidoId,
    required String prestadorUid,
    required String emailContratante,
    required DateTime agoraUtc,
  }) async {
    emailsContratantes[pedidoId] = emailContratante;
    for (var index = 0; index < itens.length; index++) {
      if (itens[index].pedidoId == pedidoId) {
        itens[index] = itens[index].copyWith(
          estado: itens[index].prestadorUid == prestadorUid
              ? EstadoCandidatura.aceita
              : EstadoCandidatura.recusada,
        );
      }
    }
  }

  @override
  Future<String?> carregarEmailPrestador({
    required String pedidoId,
    required String prestadorUid,
  }) async => emailsPrestadores['$pedidoId:$prestadorUid'];

  @override
  Future<String?> carregarEmailContratante({
    required String pedidoId,
    required String contratanteUid,
  }) async => emailsContratantes[pedidoId];
}
