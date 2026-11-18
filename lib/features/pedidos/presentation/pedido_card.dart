import 'package:flutter/material.dart';

import '../domain/data_civil.dart';
import '../domain/pedido.dart';
import 'categoria_visual.dart';

/// Cartão de pedido usado em "Pedidos por cidade" e "Meus pedidos".
class PedidoCard extends StatelessWidget {
  const PedidoCard({
    super.key,
    required this.pedido,
    this.detalhes = false,
    this.acoes = const [],
  });

  final Pedido pedido;

  /// Mostra descrição, local e data desejada.
  final bool detalhes;
  final List<Widget> acoes;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final cores = Theme.of(context).colorScheme;
    final visual = CategoriaVisual.de(
      id: pedido.categoriaId,
      nome: pedido.categoriaNome,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconeCategoria(visual: visual),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pedido.titulo, style: texto.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        pedido.categoriaNome,
                        style: texto.bodyMedium?.copyWith(
                          color: cores.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                EstadoPedidoSelo(
                  key: Key('estado-${pedido.id}'),
                  estado: pedido.estado,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              DataCivil.formatarValor(pedido.valorCentavos),
              style: texto.headlineSmall?.copyWith(color: cores.primary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(icone: Icons.place_outlined, texto: pedido.cidade),
                _InfoChip(
                  icone: Icons.event_available_outlined,
                  texto: 'Válido até ${DataCivil.formatar(pedido.validadeAte)}',
                ),
              ],
            ),
            if (detalhes) ...[
              const SizedBox(height: 12),
              Text(pedido.descricao),
              const SizedBox(height: 8),
              Text('Local: ${pedido.local}'),
              Text('Data desejada: ${DataCivil.formatar(pedido.dataDesejada)}'),
            ],
            if (acoes.isNotEmpty) ...[const SizedBox(height: 12), ...acoes],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icone, size: 18),
    label: Text(texto),
    visualDensity: VisualDensity.compact,
    shape: const StadiumBorder(),
  );
}

/// Selo colorido com o estado do pedido.
class EstadoPedidoSelo extends StatelessWidget {
  const EstadoPedidoSelo({super.key, required this.estado});

  final EstadoPedido estado;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final (rotulo, fundo, frente) = switch (estado) {
      EstadoPedido.aberto => (
        'Aberto',
        cores.secondaryContainer,
        cores.onSecondaryContainer,
      ),
      EstadoPedido.emAndamento => (
        'Em andamento',
        cores.primaryContainer,
        cores.onPrimaryContainer,
      ),
      EstadoPedido.concluido => (
        'Concluído',
        cores.tertiaryContainer,
        cores.onTertiaryContainer,
      ),
      EstadoPedido.cancelado => (
        'Cancelado',
        cores.errorContainer,
        cores.onErrorContainer,
      ),
    };
    return Semantics(
      label: 'Estado: $rotulo',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: fundo,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Text(
          rotulo,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: frente),
        ),
      ),
    );
  }
}
