import '../../conta/domain/conta.dart';
import '../../conta/domain/perfil.dart';
import 'data_civil.dart';
import 'pedido.dart';
import 'pedido_permissions.dart';
import 'pedido_repository.dart';
import 'pedido_validacao_erro.dart';
import 'pedido_validator.dart';

class PedidoService {
  const PedidoService(this._repository);

  final PedidoRepository _repository;

  Future<List<Pedido>> listarAbertos({
    required String cidade,
    required DateTime agoraUtc,
    String? categoriaId,
  }) {
    return _repository.listarAbertos(
      cidade: cidade.trim(),
      dataCivil: DataCivil.chave(DataCivil.hojeEmSaoPaulo(agoraUtc)),
      categoriaId: categoriaId,
    );
  }

  Future<void> publicar({
    required Conta contratante,
    required Pedido pedido,
    required DateTime agoraUtc,
  }) {
    if (contratante.perfil != Perfil.contratante ||
        contratante.uid != pedido.contratanteUid) {
      throw StateError('Somente o contratante pode publicar este pedido.');
    }
    final erros = PedidoValidator.validar(
      titulo: pedido.titulo,
      categoriaId: pedido.categoriaId,
      descricao: pedido.descricao,
      cidade: pedido.cidade,
      local: pedido.local,
      dataDesejada: pedido.dataDesejada,
      validadeAte: pedido.validadeAte,
      valorCentavos: pedido.valorCentavos,
      agoraUtc: agoraUtc,
    );
    if (erros.isNotEmpty) throw PedidoValidacaoErro(erros);
    return _repository.publicar(pedido);
  }

  Future<List<Pedido>> listarGerenciaveis({required String uid}) =>
      _repository.listarGerenciaveis(uid: uid);

  Future<void> atualizar({
    required Pedido original,
    required Pedido alterado,
    required String editorUid,
    required DateTime agoraUtc,
  }) {
    if (original.id != alterado.id ||
        original.contratanteUid != alterado.contratanteUid ||
        original.estado != alterado.estado ||
        original.prestadorEscolhidoUid != alterado.prestadorEscolhidoUid ||
        !PedidoPermissions.podeEditarOuCancelar(
          pedido: original,
          uid: editorUid,
          agoraUtc: agoraUtc,
        )) {
      throw const PedidoPermissaoErro();
    }
    final erros = original.estado == EstadoPedido.aberto
        ? PedidoValidator.validar(
            titulo: alterado.titulo,
            categoriaId: alterado.categoriaId,
            descricao: alterado.descricao,
            cidade: alterado.cidade,
            local: alterado.local,
            dataDesejada: alterado.dataDesejada,
            validadeAte: alterado.validadeAte,
            valorCentavos: alterado.valorCentavos,
            agoraUtc: agoraUtc,
          )
        : _validarCampos(alterado);
    if (erros.isNotEmpty) throw PedidoValidacaoErro(erros);
    return _repository.atualizar(
      pedido: alterado,
      editorUid: editorUid,
      agoraUtc: agoraUtc,
    );
  }

  Future<void> cancelar({
    required Pedido pedido,
    required String editorUid,
    required DateTime agoraUtc,
  }) {
    if (!PedidoPermissions.podeEditarOuCancelar(
      pedido: pedido,
      uid: editorUid,
      agoraUtc: agoraUtc,
    )) {
      throw const PedidoPermissaoErro();
    }
    return _repository.cancelar(
      pedidoId: pedido.id,
      editorUid: editorUid,
      agoraUtc: agoraUtc,
    );
  }

  Map<String, String> _validarCampos(Pedido pedido) => {
    if (pedido.titulo.trim().isEmpty) 'titulo': 'Informe o título do pedido.',
    if (pedido.categoriaId.trim().isEmpty)
      'categoriaId': 'Escolha uma categoria.',
    if (pedido.descricao.trim().isEmpty)
      'descricao': 'Informe a descrição do serviço.',
    if (pedido.cidade.trim().isEmpty) 'cidade': 'Informe a cidade.',
    if (pedido.local.trim().isEmpty) 'local': 'Informe o local do serviço.',
    if (pedido.validadeAte.isAfter(pedido.dataDesejada))
      'validadeAte': 'A validade não pode ultrapassar a data do serviço.',
    if (pedido.valorCentavos <= 0)
      'valorCentavos': 'Informe um valor maior que zero.',
  };
}
