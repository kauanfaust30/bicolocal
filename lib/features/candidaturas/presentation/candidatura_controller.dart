import 'package:flutter/foundation.dart';

import '../../conta/domain/contact_access_policy.dart';
import '../../conta/domain/conta.dart';
import '../../pedidos/domain/pedido.dart';
import '../../pedidos/domain/pedido_permissions.dart';
import '../../perfil/domain/foto_perfil.dart';
import '../../perfil/domain/perfil_publico.dart';
import '../../perfil/domain/perfil_repository.dart';
import '../domain/candidatura.dart';
import '../domain/candidatura_repository.dart';
import '../domain/candidatura_service.dart';

class CandidaturaController extends ChangeNotifier {
  CandidaturaController(
    CandidaturaRepository repository,
    PerfilRepository perfilRepository,
  ) : _repository = repository,
      _perfis = perfilRepository,
      _service = CandidaturaService(repository);

  final CandidaturaRepository _repository;
  final PerfilRepository _perfis;
  final CandidaturaService _service;

  List<Candidatura> candidaturas = const [];
  bool carregando = false;
  bool executando = false;
  String? erro;
  String? mensagem;
  String? emailContato;

  /// Perfis públicos dos candidatos, por uid (nome no avatar).
  Map<String, PerfilPublico> perfisCandidatos = const {};

  /// Foto do prestador escolhido, só depois do aceite (FR-020).
  FotoPerfil? fotoEscolhido;

  /// Nome e foto da outra parte de um pedido aceito, para Gerenciar pedido.
  String? nomeOutraParte;
  FotoPerfil? fotoOutraParte;

  Future<FotoPerfil?> _fotoPropria() async {
    try {
      return await _perfis.carregarFotoPropria();
    } catch (_) {
      return null;
    }
  }

  Future<PerfilPublico?> _perfil(String uid) async {
    try {
      return await _perfis.carregarPerfil(uid);
    } catch (_) {
      return null;
    }
  }

  Future<void> candidatar({
    required Pedido pedido,
    required Conta prestador,
  }) async {
    executando = true;
    erro = null;
    mensagem = null;
    notifyListeners();
    try {
      await _service.candidatar(
        pedido: pedido,
        prestador: prestador,
        agoraUtc: DateTime.now().toUtc(),
        foto: await _fotoPropria(),
      );
      mensagem = 'Candidatura enviada.';
    } on CandidaturaDuplicadaErro {
      mensagem = 'Você já se candidatou a este pedido.';
    } on CandidaturaPermissaoErro catch (falha) {
      erro = falha.mensagem;
    } catch (_) {
      erro = 'Não foi possível enviar a candidatura. Tente novamente.';
    } finally {
      executando = false;
      notifyListeners();
    }
  }

  Future<void> carregar({
    required Pedido pedido,
    required Conta contratante,
  }) async {
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      candidaturas = await _service.listar(
        pedido: pedido,
        solicitante: contratante,
      );
      final perfis = <String, PerfilPublico>{};
      for (final candidatura in candidaturas) {
        final perfil = await _perfil(candidatura.prestadorUid);
        if (perfil != null) perfis[candidatura.prestadorUid] = perfil;
      }
      perfisCandidatos = perfis;
      fotoEscolhido = null;
      if (pedido.estado == EstadoPedido.emAndamento &&
          pedido.prestadorEscolhidoUid != null) {
        await carregarContato(pedido: pedido, visualizador: contratante);
      }
      await _carregarFotoEscolhido(pedido, contratante);
    } on CandidaturaPermissaoErro catch (falha) {
      erro = falha.mensagem;
    } catch (_) {
      erro = 'Não foi possível carregar as candidaturas. Tente novamente.';
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<void> aceitar({
    required Pedido pedido,
    required Candidatura candidatura,
    required Conta contratante,
  }) async {
    executando = true;
    erro = null;
    notifyListeners();
    try {
      await _service.aceitar(
        pedido: pedido,
        candidatura: candidatura,
        contratante: contratante,
        agoraUtc: DateTime.now().toUtc(),
        fotoContratante: await _fotoPropria(),
      );
      final aceito = pedido.copyWith(
        estado: EstadoPedido.emAndamento,
        prestadorEscolhidoUid: candidatura.prestadorUid,
      );
      await carregarContato(pedido: aceito, visualizador: contratante);
      await _carregarFotoEscolhido(aceito, contratante);
      candidaturas = candidaturas
          .map(
            (item) => item.pedidoId != candidatura.pedidoId
                ? item
                : item.prestadorUid == candidatura.prestadorUid
                ? item.copyWith(estado: EstadoCandidatura.aceita)
                : item.copyWith(estado: EstadoCandidatura.recusada),
          )
          .toList();
      mensagem = 'Candidatura aceita. O pedido está em andamento.';
    } on CandidaturaPermissaoErro catch (falha) {
      erro = falha.mensagem;
    } catch (_) {
      erro = 'Não foi possível aceitar. Atualize o pedido e tente novamente.';
    } finally {
      executando = false;
      notifyListeners();
    }
  }

  Future<void> _carregarFotoEscolhido(Pedido pedido, Conta contratante) async {
    final escolhido = pedido.prestadorEscolhidoUid;
    if (escolhido == null ||
        !PedidoPermissions.podeVerFotoDaParte(
          pedido: pedido,
          uid: contratante.uid,
        )) {
      fotoEscolhido = null;
      return;
    }
    fotoEscolhido = await _repository.carregarFotoDoPrestador(
      pedidoId: pedido.id,
      prestadorUid: escolhido,
    );
  }

  /// Nome (perfil público) e, se permitido, foto da outra parte de um pedido
  /// com prestador escolhido (FR-020). Pedido cancelado volta à inicial.
  Future<void> carregarOutraParte({
    required Pedido pedido,
    required Conta visualizador,
  }) async {
    final souContratante = visualizador.uid == pedido.contratanteUid;
    final outroUid = souContratante
        ? pedido.prestadorEscolhidoUid
        : pedido.contratanteUid;
    nomeOutraParte = null;
    fotoOutraParte = null;
    if (outroUid == null) return;
    nomeOutraParte = (await _perfil(outroUid))?.nome;
    if (PedidoPermissions.podeVerFotoDaParte(
      pedido: pedido,
      uid: visualizador.uid,
    )) {
      fotoOutraParte = souContratante
          ? await _repository.carregarFotoDoPrestador(
              pedidoId: pedido.id,
              prestadorUid: outroUid,
            )
          : await _repository.carregarFotoDoContratante(
              pedidoId: pedido.id,
              contratanteUid: outroUid,
            );
    }
    notifyListeners();
  }

  Future<void> carregarContato({
    required Pedido pedido,
    required Conta visualizador,
  }) async {
    final outroUid = visualizador.uid == pedido.contratanteUid
        ? pedido.prestadorEscolhidoUid
        : pedido.contratanteUid;
    if (outroUid == null ||
        !ContactAccessPolicy.podeLerContato(
          pedido: pedido,
          leitorUid: visualizador.uid,
          donoContatoUid: outroUid,
        )) {
      emailContato = null;
      return;
    }
    emailContato = visualizador.uid == pedido.contratanteUid
        ? await _repository.carregarEmailPrestador(
            pedidoId: pedido.id,
            prestadorUid: outroUid,
          )
        : await _repository.carregarEmailContratante(
            pedidoId: pedido.id,
            contratanteUid: outroUid,
          );
  }
}
