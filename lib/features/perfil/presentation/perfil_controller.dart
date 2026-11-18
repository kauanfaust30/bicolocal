import 'package:flutter/foundation.dart';

import '../../../core/async/async_state.dart';
import '../../../core/registro_falha.dart';
import '../../avaliacoes/domain/avaliacao.dart';
import '../../avaliacoes/domain/avaliacao_repository.dart';
import '../../candidaturas/domain/candidatura_repository.dart';
import '../../conta/domain/conta.dart';
import '../../pedidos/domain/pedido.dart';
import '../../pedidos/domain/pedido_permissions.dart';
import '../domain/foto_perfil.dart';
import '../domain/perfil_publico.dart';
import '../domain/perfil_repository.dart';

/// Perfil público e avaliações recentes de uma pessoa (FR-009 a FR-015).
/// Criado por tela: Meu perfil e Perfil de outra pessoa.
class PerfilController extends ChangeNotifier {
  PerfilController(this._perfis, this._avaliacoes, this._candidaturas);

  static const recentes = 5;

  final PerfilRepository _perfis;
  final AvaliacaoRepository _avaliacoes;
  final CandidaturaRepository _candidaturas;

  String? _uid;
  AsyncState<PerfilPublico> perfil = const AsyncState.inicial();
  AsyncState<List<Avaliacao>> avaliacoes = const AsyncState.inicial();

  /// Foto da outra parte, só quando o FR-020 permite; senão, a inicial.
  FotoPerfil? foto;

  Future<void> carregar(String uid) async {
    _uid = uid;
    await Future.wait([carregarPerfil(), carregarAvaliacoes()]);
  }

  Future<void> carregarPerfil() async {
    final uid = _uid;
    if (uid == null) return;
    perfil = const AsyncState.carregando();
    notifyListeners();
    try {
      final dados = await _perfis.carregarPerfil(uid);
      perfil = dados == null
          ? const AsyncState.erro('Não foi possível carregar o perfil.')
          : AsyncState.sucesso(dados);
    } catch (falha) {
      registrarFalha('Falha ao carregar perfil', falha);
      perfil = const AsyncState.erro('Não foi possível carregar o perfil.');
    }
    notifyListeners();
  }

  Future<void> carregarAvaliacoes() async {
    final uid = _uid;
    if (uid == null) return;
    avaliacoes = const AsyncState.carregando();
    notifyListeners();
    try {
      final lista = await _avaliacoes.listarRecentes(uid);
      avaliacoes = AsyncState.sucesso(lista.take(recentes).toList());
    } catch (falha) {
      registrarFalha('Falha ao carregar avaliações', falha);
      avaliacoes = const AsyncState.erro(
        'Não foi possível carregar as avaliações.',
      );
    }
    notifyListeners();
  }

  Future<void> tentarNovamente() => Future.wait([
    if (perfil.status == AsyncStatus.erro) carregarPerfil(),
    if (avaliacoes.status == AsyncStatus.erro) carregarAvaliacoes(),
  ]);

  /// Carrega a cópia da foto de [uid] guardada no pedido, se [visualizador]
  /// for a outra parte de um pedido aceito (FR-020). Em qualquer outro caso
  /// a foto fica oculta.
  Future<void> carregarFotoDaParte({
    required Pedido pedido,
    required Conta visualizador,
    required String uid,
  }) async {
    foto = null;
    if (!PedidoPermissions.podeVerFotoDaParte(
          pedido: pedido,
          uid: visualizador.uid,
        ) ||
        PedidoPermissions.outraParte(pedido: pedido, uid: visualizador.uid) !=
            uid) {
      return;
    }
    try {
      foto = uid == pedido.contratanteUid
          ? await _candidaturas.carregarFotoDoContratante(
              pedidoId: pedido.id,
              contratanteUid: uid,
            )
          : await _candidaturas.carregarFotoDoPrestador(
              pedidoId: pedido.id,
              prestadorUid: uid,
            );
    } catch (falha) {
      registrarFalha('Falha ao carregar foto da outra parte', falha);
    }
    notifyListeners();
  }
}
