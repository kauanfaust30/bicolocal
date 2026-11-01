import '../../conta/domain/conta.dart';
import '../../conta/domain/perfil.dart';
import '../../pedidos/domain/data_civil.dart';
import '../../pedidos/domain/pedido.dart';
import 'candidatura.dart';
import 'candidatura_error.dart';
import 'candidatura_repository.dart';

export 'candidatura_error.dart';

class CandidaturaService {
  const CandidaturaService(this._repository);

  final CandidaturaRepository _repository;

  Future<void> candidatar({
    required Pedido pedido,
    required Conta prestador,
    required DateTime agoraUtc,
  }) async {
    if (prestador.perfil != Perfil.prestador ||
        !_pedidoDisponivel(pedido, agoraUtc)) {
      throw const CandidaturaPermissaoErro(
        'Este pedido não está disponível para candidatura.',
      );
    }
    final existente = await _repository.buscar(
      pedidoId: pedido.id,
      prestadorUid: prestador.uid,
    );
    if (existente != null) throw const CandidaturaDuplicadaErro();

    await _repository.candidatar(
      Candidatura(
        pedidoId: pedido.id,
        prestadorUid: prestador.uid,
        estado: EstadoCandidatura.pendente,
      ),
      emailPrestador: prestador.email,
    );
  }

  Future<List<Candidatura>> listar({
    required Pedido pedido,
    required Conta solicitante,
  }) {
    if (pedido.contratanteUid != solicitante.uid) {
      throw const CandidaturaPermissaoErro(
        'Somente quem publicou o pedido pode revisar candidaturas.',
      );
    }
    return _repository.listar(pedidoId: pedido.id);
  }

  Future<void> aceitar({
    required Pedido pedido,
    required Candidatura candidatura,
    required Conta contratante,
    required DateTime agoraUtc,
  }) async {
    if (pedido.contratanteUid != contratante.uid ||
        candidatura.pedidoId != pedido.id ||
        candidatura.estado != EstadoCandidatura.pendente ||
        !_pedidoDisponivel(pedido, agoraUtc)) {
      throw const CandidaturaPermissaoErro(
        'Não é possível aceitar esta candidatura. Atualize o pedido e tente novamente.',
      );
    }
    await _repository.aceitar(
      pedidoId: pedido.id,
      prestadorUid: candidatura.prestadorUid,
      emailContratante: contratante.email,
      agoraUtc: agoraUtc,
    );
  }

  bool _pedidoDisponivel(Pedido pedido, DateTime agoraUtc) =>
      pedido.estado == EstadoPedido.aberto &&
      DataCivil.chave(pedido.validadeAte)
              .compareTo(DataCivil.chave(DataCivil.hojeEmSaoPaulo(agoraUtc))) >=
          0;
}
