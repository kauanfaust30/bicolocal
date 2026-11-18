import 'dart:async';

import 'package:bicolocal/features/conta/domain/conta.dart';
import 'package:bicolocal/features/conta/domain/conta_erro.dart';
import 'package:bicolocal/features/conta/domain/conta_repository.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:bicolocal/features/candidaturas/domain/candidatura.dart';
import 'package:bicolocal/features/candidaturas/domain/candidatura_repository.dart';
import 'package:bicolocal/features/pedidos/domain/categoria.dart';
import 'package:bicolocal/features/pedidos/domain/data_civil.dart';
import 'package:bicolocal/features/pedidos/domain/pedido.dart';
import 'package:bicolocal/features/pedidos/domain/pedido_repository.dart';
import 'package:bicolocal/features/avaliacoes/domain/avaliacao.dart';
import 'package:bicolocal/features/avaliacoes/domain/avaliacao_erro.dart';
import 'package:bicolocal/features/avaliacoes/domain/avaliacao_repository.dart';
import 'package:bicolocal/features/perfil/domain/foto_erro.dart';
import 'package:bicolocal/features/perfil/domain/foto_perfil.dart';
import 'package:bicolocal/features/perfil/domain/perfil_publico.dart';
import 'package:bicolocal/features/perfil/domain/perfil_repository.dart';
import 'package:bicolocal/features/perfil/domain/seletor_foto.dart';

/// Seletor de foto falso: devolve `foto`, `null` (cancelou) ou lança `erro`.
class FakeSeletorFoto implements SeletorFoto {
  FakeSeletorFoto({this.foto, this.erro});

  FotoPerfil? foto;
  FotoErro? erro;
  final List<OrigemFoto> origensPedidas = [];

  @override
  Future<FotoPerfil?> escolher(OrigemFoto origem) async {
    origensPedidas.add(origem);
    if (erro case final falha?) throw falha;
    return foto;
  }
}

class FakePerfilRepository implements PerfilRepository {
  FakePerfilRepository({
    Map<String, PerfilPublico> perfis = const {},
    this.fotoPropria,
  }) : perfis = Map.of(perfis);

  final Map<String, PerfilPublico> perfis;
  FotoPerfil? fotoPropria;

  /// Quando verdadeiro, `salvarFotoPropria` falha uma vez e a foto não muda.
  bool falharProximoEnvio = false;
  int fotosSalvas = 0;

  @override
  Future<PerfilPublico?> carregarPerfil(String uid) async => perfis[uid];

  @override
  Future<FotoPerfil?> carregarFotoPropria() async => fotoPropria;

  @override
  Future<void> salvarFotoPropria(FotoPerfil foto) async {
    if (falharProximoEnvio) {
      falharProximoEnvio = false;
      throw FotoErro.envioFalhou;
    }
    fotosSalvas++;
    fotoPropria = foto;
  }
}

class FakeAvaliacaoRepository implements AvaliacaoRepository {
  /// Avaliações já feitas, por `pedidoId:avaliadoUid`.
  final Set<String> avaliadas = {};
  final List<Avaliacao> avaliacoes = [];

  /// Quando verdadeiro, `avaliar` falha uma vez e nada é registrado.
  bool falharProximoEnvio = false;

  @override
  Future<bool> jaAvaliou({
    required String pedidoId,
    required String avaliadoUid,
  }) async => avaliadas.contains('$pedidoId:$avaliadoUid');

  @override
  Future<void> avaliar(Avaliacao avaliacao) async {
    if (falharProximoEnvio) {
      falharProximoEnvio = false;
      throw Exception('Falha de teste ao avaliar');
    }
    final chave = '${avaliacao.pedidoId}:${avaliacao.avaliadoUid}';
    // Como a regra: criar sobre avaliação existente é recusado.
    if (!avaliadas.add(chave)) throw const AvaliacaoPermissaoErro();
    avaliacoes.add(avaliacao);
  }
}

class FakeContaRepository implements ContaRepository {
  FakeContaRepository({this.contaInicial})
    : _sessao = StreamController<Conta?>.broadcast(sync: true);

  Conta? contaInicial;
  final StreamController<Conta?> _sessao;

  /// Simula falha ao gravar a foto no cadastro (FR-017): nada é criado.
  bool falharFotoNoCadastro = false;

  /// Simula uma falha em Adicionar foto (FR-018).
  bool falharProximaFoto = false;
  FotoPerfil? fotoCadastrada;
  FotoPerfil? fotoAdicionada;

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
    required FotoPerfil foto,
  }) async {
    if (falharFotoNoCadastro) throw ContaErro.fotoNaoEnviada();
    fotoCadastrada = foto;
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
  Future<void> adicionarFoto(FotoPerfil foto) async {
    if (falharProximaFoto) {
      falharProximaFoto = false;
      throw FotoErro.envioFalhou;
    }
    fotoAdicionada = foto;
    publicarConta(contaInicial?.copyWith(temFoto: true));
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

  /// Quando verdadeiro, `concluir` falha e o pedido não muda.
  bool falharConclusao = false;
  final List<String> concluidos = [];

  @override
  Future<void> concluir({
    required String pedidoId,
    required String editorUid,
  }) async {
    if (falharConclusao) throw Exception('Falha de teste ao concluir');
    final index = pedidos.indexWhere((item) => item.id == pedidoId);
    if (index >= 0) {
      pedidos[index] = pedidos[index].copyWith(estado: EstadoPedido.concluido);
      concluidos.add(pedidoId);
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

  /// Cópias da foto do prestador, por `pedidoId:prestadorUid`.
  final Map<String, FotoPerfil> copiasFotoPrestador = {};

  /// Cópias da foto do contratante, por `pedidoId`.
  final Map<String, FotoPerfil> copiasFotoContratante = {};

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
    FotoPerfil? foto,
  }) async {
    candidaturasCriadas++;
    itens.add(candidatura);
    final chave = '${candidatura.pedidoId}:${candidatura.prestadorUid}';
    emailsPrestadores[chave] = emailPrestador;
    if (foto != null) copiasFotoPrestador[chave] = foto;
  }

  @override
  Future<void> aceitar({
    required String pedidoId,
    required String prestadorUid,
    required String emailContratante,
    required DateTime agoraUtc,
    FotoPerfil? fotoContratante,
  }) async {
    emailsContratantes[pedidoId] = emailContratante;
    if (fotoContratante != null) {
      copiasFotoContratante[pedidoId] = fotoContratante;
    }
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

  @override
  Future<FotoPerfil?> carregarFotoDoPrestador({
    required String pedidoId,
    required String prestadorUid,
  }) async => copiasFotoPrestador['$pedidoId:$prestadorUid'];

  @override
  Future<FotoPerfil?> carregarFotoDoContratante({
    required String pedidoId,
    required String contratanteUid,
  }) async => copiasFotoContratante[pedidoId];
}
