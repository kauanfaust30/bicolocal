import 'package:flutter/material.dart';

/// Ilustração feita de ícones grandes, com título, texto e ação opcional.
/// Usada nos estados de carregando, vazio e erro das listas.
class EstadoIlustrado extends StatelessWidget {
  const EstadoIlustrado({
    super.key,
    required this.icone,
    required this.titulo,
    this.mensagem,
    this.iconeDetalhe,
    this.carregando = false,
    this.erro = false,
    this.acao,
  });

  const EstadoIlustrado.carregando({super.key, required this.titulo})
    : icone = Icons.travel_explore,
      mensagem = null,
      iconeDetalhe = null,
      carregando = true,
      erro = false,
      acao = null;

  final IconData icone;
  final IconData? iconeDetalhe;
  final String titulo;
  final String? mensagem;
  final bool carregando;
  final bool erro;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;
    final fundo = erro ? cores.errorContainer : cores.primaryContainer;
    final frente = erro ? cores.onErrorContainer : cores.onPrimaryContainer;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: SizedBox(
                key: const Key('ilustracao-estado'),
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: fundo,
                      child: Icon(icone, size: 56, color: frente),
                    ),
                    if (iconeDetalhe != null)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: cores.secondary,
                          child: Icon(
                            iconeDetalhe,
                            size: 22,
                            color: cores.onSecondary,
                          ),
                        ),
                      ),
                    if (carregando)
                      const SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(titulo, textAlign: TextAlign.center, style: texto.titleMedium),
            if (mensagem != null) ...[
              const SizedBox(height: 8),
              Text(
                mensagem!,
                textAlign: TextAlign.center,
                style: texto.bodyMedium?.copyWith(
                  color: cores.onSurfaceVariant,
                ),
              ),
            ],
            if (acao != null) ...[const SizedBox(height: 16), acao!],
          ],
        ),
      ),
    );
  }
}
