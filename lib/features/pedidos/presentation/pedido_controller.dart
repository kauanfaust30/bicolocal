import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/async/async_state.dart';
import '../../conta/domain/conta.dart';
import '../../conta/domain/perfil.dart';
import '../domain/categoria.dart';
import '../domain/data_civil.dart';
import '../domain/pedido.dart';
import '../domain/pedido_permissions.dart';
import '../domain/pedido_repository.dart';
import '../domain/pedido_service.dart';
import '../domain/pedido_validacao_erro.dart';

class PedidoController extends ChangeNotifier {
  PedidoController(PedidoRepository repository)
    : _repository = repository,
      _service = PedidoService(repository);

  final PedidoRepository _repository;
  final PedidoService _service;

  AsyncState<List<Pedido>> estadoLista = const AsyncState.inicial();
  AsyncState<List<Pedido>> estadoGerenciaveis = const AsyncState.inicial();
  List<Categoria> categorias = const [];
  Categoria? categoriaSelecionada;
  String? cidadeSelecionada;
  bool carregandoCategorias = false;
  String? erroCategorias;
  bool publicando = false;
  String? erro;
  String? mensagem;
  Map<String, String> errosCampos = {};

  Future<void> carregar(Conta? conta, {DateTime? agoraUtc}) async {
    if (conta == null || conta.perfil != Perfil.prestador) {
      estadoLista = const AsyncState.erro(
        'Entre como prestador para consultar os pedidos locais.',
      );
      notifyListeners();
      return;
    }
    estadoLista = const AsyncState.carregando();
    notifyListeners();
    try {
      final pedidos = await _service.listarAbertos(
        cidade: cidadeSelecionada ?? conta.cidade,
        agoraUtc: agoraUtc ?? DateTime.now().toUtc(),
        categoriaId: categoriaSelecionada?.id,
      );
      estadoLista = AsyncState.sucesso(pedidos);
    } on FirebaseException catch (falha) {
      if (kDebugMode) {
        debugPrint(
          'Falha ao carregar pedidos no Firestore: ${falha.code} - '
          '${falha.message}',
        );
      }
      estadoLista = AsyncState.erro(_mensagemErroFirestore(falha.code));
    } on TypeError catch (falha) {
      if (kDebugMode) {
        debugPrint('Formato inválido ao ler pedido: ${falha.runtimeType}');
      }
      estadoLista = const AsyncState.erro(
        'Os dados de um pedido estão inválidos. Confira os campos de data no Firestore.',
      );
    } on FormatException catch (falha) {
      if (kDebugMode) {
        debugPrint('Formato inválido ao ler pedido: ${falha.runtimeType}');
      }
      estadoLista = const AsyncState.erro(
        'Os dados de um pedido estão inválidos. Confira os campos de data no Firestore.',
      );
    } catch (falha) {
      if (kDebugMode) {
        debugPrint(
          'Falha inesperada ao carregar pedidos: ${falha.runtimeType}',
        );
      }
      estadoLista = const AsyncState.erro(
        'Não foi possível carregar os pedidos.',
      );
    }
    notifyListeners();
  }

  Future<void> tentarNovamente(Conta? conta) => carregar(conta);

  Future<void> carregarGerenciaveis(Conta? conta) async {
    if (conta == null) {
      estadoGerenciaveis = const AsyncState.erro(
        'Entre na sua conta para ver seus pedidos.',
      );
      notifyListeners();
      return;
    }
    estadoGerenciaveis = const AsyncState.carregando();
    notifyListeners();
    try {
      final itens = await _service.listarGerenciaveis(uid: conta.uid);
      estadoGerenciaveis = AsyncState.sucesso(itens);
    } catch (_) {
      estadoGerenciaveis = const AsyncState.erro(
        'Não foi possível carregar seus pedidos. Tente novamente.',
      );
    }
    notifyListeners();
  }

  Future<Pedido?> buscar({required String pedidoId}) =>
      _repository.buscar(pedidoId: pedidoId);

  Future<bool> atualizarPedido({
    required Conta? editor,
    required Pedido original,
    required Pedido alterado,
  }) async {
    if (editor == null) {
      erro = 'Entre na sua conta para alterar o pedido.';
      notifyListeners();
      return false;
    }
    publicando = true;
    erro = null;
    errosCampos = {};
    notifyListeners();
    try {
      await _service.atualizar(
        original: original,
        alterado: alterado,
        editorUid: editor.uid,
        agoraUtc: DateTime.now().toUtc(),
      );
      await carregarGerenciaveis(editor);
      return true;
    } on PedidoPermissaoErro {
      erro = 'Você não tem autorização para alterar este pedido.';
    } on PedidoValidacaoErro catch (falha) {
      errosCampos = falha.campos;
    } catch (_) {
      erro = 'Não foi possível alterar. Seus dados foram mantidos. Tente novamente.';
    } finally {
      publicando = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> cancelarPedido({
    required Conta? editor,
    required Pedido pedido,
  }) async {
    if (editor == null) {
      erro = 'Entre na sua conta para cancelar o pedido.';
      notifyListeners();
      return false;
    }
    publicando = true;
    erro = null;
    notifyListeners();
    try {
      await _service.cancelar(
        pedido: pedido,
        editorUid: editor.uid,
        agoraUtc: DateTime.now().toUtc(),
      );
      mensagem = 'Pedido cancelado.';
      await carregarGerenciaveis(editor);
      return true;
    } on PedidoPermissaoErro {
      erro = 'Você não tem autorização para cancelar este pedido.';
    } catch (_) {
      erro = 'Não foi possível cancelar. Tente novamente.';
    } finally {
      publicando = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> carregarCategorias() async {
    carregandoCategorias = true;
    erroCategorias = null;
    notifyListeners();
    try {
      categorias = await _repository.carregarCategorias();
    } catch (_) {
      erroCategorias = 'Não foi possível carregar as categorias.';
    } finally {
      carregandoCategorias = false;
      notifyListeners();
    }
  }

  Future<void> selecionarCategoria({
    required Conta? conta,
    required Categoria? categoria,
  }) async {
    categoriaSelecionada = categoria;
    await carregar(conta);
  }

  Future<void> limparFiltroCategoria({required Conta? conta}) =>
      selecionarCategoria(conta: conta, categoria: null);

  Future<void> selecionarCidade({
    required Conta? conta,
    required String cidade,
  }) async {
    final cidadeInformada = cidade.trim();
    cidadeSelecionada = cidadeInformada.isEmpty ? null : cidadeInformada;
    await carregar(conta);
  }

  Future<void> limparFiltroCidade({required Conta? conta}) =>
      selecionarCidade(conta: conta, cidade: '');

  Future<bool> publicar({
    required Conta? conta,
    required String titulo,
    required Categoria? categoria,
    required String descricao,
    required String cidade,
    required String local,
    required DateTime? dataDesejada,
    required DateTime? validadeAte,
    required int? valorCentavos,
  }) async {
    final atual = conta;
    if (atual == null || atual.perfil != Perfil.contratante) {
      erro = 'Troque para o perfil Contratante para publicar um pedido.';
      notifyListeners();
      return false;
    }
    if (categoria == null || dataDesejada == null || validadeAte == null) {
      errosCampos = {
        if (categoria == null) 'categoriaId': 'Escolha uma categoria.',
        if (dataDesejada == null) 'dataDesejada': 'Escolha a data do serviço.',
        if (validadeAte == null) 'validadeAte': 'Escolha a validade do pedido.',
      };
      notifyListeners();
      return false;
    }
    if (valorCentavos == null) {
      errosCampos = {'valorCentavos': 'Informe um valor maior que zero.'};
      notifyListeners();
      return false;
    }

    final pedido = Pedido(
      id: '',
      contratanteUid: atual.uid,
      titulo: titulo.trim(),
      categoriaId: categoria.id,
      categoriaNome: categoria.nome,
      descricao: descricao.trim(),
      cidade: cidade.trim(),
      local: local.trim(),
      dataDesejada: dataDesejada,
      validadeAte: validadeAte,
      valorCentavos: valorCentavos,
    );
    publicando = true;
    erro = null;
    errosCampos = {};
    notifyListeners();
    try {
      await _service.publicar(
        contratante: atual,
        pedido: pedido,
        agoraUtc: DateTime.now().toUtc(),
      );
      return true;
    } on PedidoValidacaoErro catch (falha) {
      errosCampos = falha.campos;
    } catch (_) {
      erro = 'Não foi possível publicar. Seus dados foram mantidos. Tente novamente.';
    } finally {
      publicando = false;
      notifyListeners();
    }
    return false;
  }

  String formatarData(DateTime? data) =>
      data == null ? 'Selecionar data' : DataCivil.formatar(data);

  String _mensagemErroFirestore(String codigo) => switch (codigo) {
    'permission-denied' || 'failed-precondition' => 'Não foi possível carregar os pedidos agora. Tente novamente em instantes.',
    'unauthenticated' =>
      'Sua sessão expirou. Entre novamente para ver pedidos.',
    'unavailable' || 'deadline-exceeded' => 'Não foi possível conectar ao Firestore. Verifique a conexão e tente novamente.',
    _ => 'Não foi possível carregar os pedidos.',
  };
}
