import 'package:flutter/foundation.dart';

import '../../../core/registro_falha.dart';
import '../../conta/domain/conta.dart';
import '../../pedidos/domain/pedido.dart';
import '../domain/avaliacao_erro.dart';
import '../domain/avaliacao_repository.dart';
import '../domain/avaliacao_service.dart';

class AvaliacaoController extends ChangeNotifier {
  AvaliacaoController(AvaliacaoRepository repository)
    : _service = AvaliacaoService(repository);

  final AvaliacaoService _service;

  /// Por `uid:pedidoId`: se a pessoa já avaliou a outra parte do pedido.
  final Map<String, bool> _jaAvaliou = {};
  final Set<String> _verificando = {};

  bool enviando = false;
  String? erro;
  Map<String, String> errosCampos = {};

  String _chave(Conta conta, Pedido pedido) => '${conta.uid}:${pedido.id}';

  /// `null` enquanto não foi verificado.
  bool? jaAvaliou({required Conta conta, required Pedido pedido}) =>
      _jaAvaliou[_chave(conta, pedido)];

  Future<void> verificar({required Conta conta, required Pedido pedido}) async {
    final chave = _chave(conta, pedido);
    if (_jaAvaliou.containsKey(chave) || !_verificando.add(chave)) return;
    try {
      _jaAvaliou[chave] = await _service.jaAvaliou(
        pedido: pedido,
        conta: conta,
      );
    } catch (falha) {
      registrarFalha('Falha ao verificar avaliação', falha);
    } finally {
      _verificando.remove(chave);
      notifyListeners();
    }
  }

  /// Limpa os erros ao abrir o formulário.
  void iniciarFormulario() {
    erro = null;
    errosCampos = {};
  }

  /// Envia a avaliação (FR-003 a FR-005). Ignora um segundo toque enquanto
  /// o primeiro está em andamento.
  Future<bool> enviar({
    required Pedido pedido,
    required Conta avaliador,
    required int? nota,
    required String comentario,
  }) async {
    if (enviando) return false;
    enviando = true;
    erro = null;
    errosCampos = {};
    notifyListeners();
    try {
      await _service.avaliar(
        pedido: pedido,
        avaliador: avaliador,
        nota: nota,
        comentario: comentario,
      );
      _jaAvaliou[_chave(avaliador, pedido)] = true;
      return true;
    } on AvaliacaoValidacaoErro catch (falha) {
      errosCampos = falha.campos;
    } catch (falha) {
      registrarFalha('Falha ao enviar avaliação', falha);
      erro =
          'Não foi possível enviar a avaliação. Sua nota e seu comentário '
          'continuam aqui. Tente de novo.';
      if (falha is AvaliacaoPermissaoErro) {
        // Pode ter sido avaliado em outro aparelho: confere de novo.
        _jaAvaliou.remove(_chave(avaliador, pedido));
        await verificar(conta: avaliador, pedido: pedido);
      }
    } finally {
      enviando = false;
      notifyListeners();
    }
    return false;
  }
}
