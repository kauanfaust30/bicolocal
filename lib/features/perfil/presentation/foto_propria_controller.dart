import 'package:flutter/foundation.dart';

import '../../../core/registro_falha.dart';
import '../domain/foto_erro.dart';
import '../domain/foto_perfil.dart';
import '../domain/perfil_repository.dart';

/// Carrega e troca a foto da própria pessoa (FR-019).
class FotoPropriaController extends ChangeNotifier {
  FotoPropriaController(this._repository);

  final PerfilRepository _repository;

  FotoPerfil? foto;
  bool carregando = true;
  bool enviando = false;
  String? erro;
  String? mensagem;

  Future<void> carregar() async {
    carregando = true;
    notifyListeners();
    try {
      foto = await _repository.carregarFotoPropria();
    } catch (_) {
      erro = 'Não foi possível carregar sua foto. Tente novamente.';
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  /// Se o envio falhar, a foto anterior continua valendo.
  Future<void> trocar(FotoPerfil nova) async {
    enviando = true;
    erro = null;
    mensagem = null;
    notifyListeners();
    try {
      await _repository.salvarFotoPropria(nova);
      foto = nova;
      mensagem = 'Foto atualizada.';
    } on FotoErro catch (falha) {
      erro = falha.mensagem;
    } catch (falha) {
      registrarFalha('Falha inesperada ao trocar foto', falha);
      erro = FotoErro.envioFalhou.mensagem;
    } finally {
      enviando = false;
      notifyListeners();
    }
  }
}
