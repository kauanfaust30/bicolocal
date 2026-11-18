import '../../conta/domain/conta.dart';
import '../../pedidos/domain/pedido.dart';
import '../../pedidos/domain/pedido_permissions.dart';
import 'avaliacao.dart';
import 'avaliacao_erro.dart';
import 'avaliacao_repository.dart';
import 'avaliacao_validator.dart';

class AvaliacaoService {
  const AvaliacaoService(this._repository);

  final AvaliacaoRepository _repository;

  /// Registra a avaliação de [avaliador] para a outra parte de [pedido].
  Future<void> avaliar({
    required Pedido pedido,
    required Conta avaliador,
    required int? nota,
    required String comentario,
  }) async {
    final erros = AvaliacaoValidator.validar(
      nota: nota,
      comentario: comentario,
    );
    if (erros.isNotEmpty) throw AvaliacaoValidacaoErro(erros);
    final avaliadoUid = PedidoPermissions.outraParte(
      pedido: pedido,
      uid: avaliador.uid,
    );
    if (!PedidoPermissions.podeAvaliar(pedido: pedido, uid: avaliador.uid) ||
        avaliadoUid == null) {
      throw const AvaliacaoPermissaoErro();
    }
    if (await _repository.jaAvaliou(
      pedidoId: pedido.id,
      avaliadoUid: avaliadoUid,
    )) {
      throw const AvaliacaoPermissaoErro();
    }
    await _repository.avaliar(
      Avaliacao(
        pedidoId: pedido.id,
        avaliadorUid: avaliador.uid,
        avaliadorNome: avaliador.nome,
        avaliadoUid: avaliadoUid,
        nota: nota!,
        comentario: AvaliacaoValidator.comentarioLimpo(comentario),
      ),
    );
  }

  /// Se [conta] já avaliou a outra parte de [pedido].
  Future<bool> jaAvaliou({required Pedido pedido, required Conta conta}) async {
    final avaliadoUid = PedidoPermissions.outraParte(
      pedido: pedido,
      uid: conta.uid,
    );
    if (avaliadoUid == null) return false;
    return _repository.jaAvaliou(pedidoId: pedido.id, avaliadoUid: avaliadoUid);
  }
}
