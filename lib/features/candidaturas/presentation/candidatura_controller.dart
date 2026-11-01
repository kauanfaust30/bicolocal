import 'package:flutter/foundation.dart';

import '../../conta/domain/contact_access_policy.dart';
import '../../conta/domain/conta.dart';
import '../../pedidos/domain/pedido.dart';
import '../domain/candidatura.dart';
import '../domain/candidatura_repository.dart';
import '../domain/candidatura_service.dart';

class CandidaturaController extends ChangeNotifier {
  CandidaturaController(CandidaturaRepository repository)
    : _repository = repository,
      _service = CandidaturaService(repository);

  final CandidaturaRepository _repository;
  final CandidaturaService _service;

  List<Candidatura> candidaturas = const [];
  bool carregando = false;
  bool executando = false;
  String? erro;
  String? mensagem;
  String? emailContato;

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
      if (pedido.estado == EstadoPedido.emAndamento &&
          pedido.prestadorEscolhidoUid != null) {
        await carregarContato(pedido: pedido, visualizador: contratante);
      }
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
      );
      await carregarContato(
        pedido: pedido.copyWith(
          estado: EstadoPedido.emAndamento,
          prestadorEscolhidoUid: candidatura.prestadorUid,
        ),
        visualizador: contratante,
      );
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
