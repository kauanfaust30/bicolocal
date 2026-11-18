import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Imprime no console (só em modo debug) o tipo, o código e a mensagem de
/// uma falha capturada, sem mudar o que é mostrado ao usuário.
void registrarFalha(String contexto, Object falha) {
  if (!kDebugMode) return;
  final codigo = falha is FirebaseException ? falha.code : '-';
  final mensagem = falha is FirebaseException ? falha.message : '$falha';
  debugPrint('$contexto: ${falha.runtimeType} (código: $codigo) - $mensagem');
}
