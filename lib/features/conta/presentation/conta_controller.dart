import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/registro_falha.dart';
import '../../perfil/domain/foto_erro.dart';
import '../../perfil/domain/foto_perfil.dart';
import '../domain/conta.dart';
import '../domain/conta_erro.dart';
import '../domain/conta_repository.dart';
import '../domain/conta_service.dart';
import '../domain/perfil.dart';

class ContaController extends ChangeNotifier {
  ContaController(ContaRepository repository)
    : _service = ContaService(repository) {
    _sessao = repository.observarSessao().listen(
      (conta) {
        _conta = conta;
        _carregandoSessao = false;
        notifyListeners();
      },
      onError: (_) {
        _carregandoSessao = false;
        erro = 'Não foi possível carregar sua conta. Tente novamente.';
        notifyListeners();
      },
    );
  }

  final ContaService _service;
  late final StreamSubscription<Conta?> _sessao;

  Conta? _conta;
  Conta? get conta => _conta;
  bool _carregandoSessao = true;
  bool get carregandoSessao => _carregandoSessao;
  bool carregando = false;
  String? erro;
  Map<String, String> errosCampos = {};

  Future<void> cadastrar({
    required String email,
    required String senha,
    required String nome,
    required String cidade,
    required String bairro,
    required Perfil? perfil,
    required FotoPerfil? foto,
  }) async {
    await _executar(
      () => _service.cadastrar(
        email: email,
        senha: senha,
        nome: nome,
        cidade: cidade,
        bairro: bairro,
        perfil: perfil,
        foto: foto,
      ),
    );
  }

  bool enviandoFoto = false;
  String? erroFoto;

  /// Adicionar foto (FR-018). Em caso de falha, a pessoa continua na tela,
  /// vê o motivo e pode tentar de novo.
  Future<void> adicionarFoto(FotoPerfil foto) async {
    enviandoFoto = true;
    erroFoto = null;
    notifyListeners();
    try {
      await _service.adicionarFoto(foto);
      final conta = _conta;
      if (conta != null) _conta = conta.copyWith(temFoto: true);
    } on FotoErro catch (falha) {
      erroFoto = falha.mensagem;
    } catch (falha) {
      registrarFalha('Falha inesperada ao adicionar foto', falha);
      erroFoto = FotoErro.envioFalhou.mensagem;
    } finally {
      enviandoFoto = false;
      notifyListeners();
    }
  }

  Future<void> entrar({required String email, required String senha}) async {
    await _executar(() => _service.entrar(email: email, senha: senha));
  }

  Future<void> sair() async {
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      await _service.sair();
      _conta = null;
    } on ContaErro catch (falha) {
      erro = falha.mensagem;
    } catch (_) {
      erro = 'Não foi possível sair da conta. Tente novamente.';
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<void> _executar(Future<Conta> Function() operacao) async {
    carregando = true;
    erro = null;
    errosCampos = {};
    notifyListeners();
    try {
      _conta = await operacao();
    } on ContaValidacaoErro catch (falha) {
      errosCampos = falha.campos;
    } on ContaErro catch (falha) {
      erro = falha.mensagem;
    } catch (falha) {
      registrarFalha('Falha inesperada no cadastro ou na entrada', falha);
      erro = 'Não foi possível concluir agora. Confira os dados e tente novamente.';
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sessao.cancel();
    super.dispose();
  }
}
