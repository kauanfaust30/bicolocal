import 'package:flutter/material.dart';

import '../domain/data_civil.dart';

/// Títulos e textos de ajuda compartilhados por Novo pedido e Gerenciar pedido.
abstract final class AjudaPedido {
  static const titulo = 'Ex.: Montar um guarda-roupa';
  static const descricao =
      'Conte o que precisa ser feito e o que já tem no local.';
  static const cidade = 'Prestadores desta cidade verão o pedido.';
  static const local = 'Bairro ou ponto de referência.';
  static const valor = 'Valor combinado, em reais. Ex.: 150,00';
  static const dataDesejada = 'Dia em que o serviço deve ser feito.';
  static const validade =
      'Último dia em que o pedido aparece para prestadores.';
}

/// Grupo de campos com ícone e título.
class SecaoFormulario extends StatelessWidget {
  const SecaoFormulario({
    super.key,
    required this.icone,
    required this.titulo,
    required this.children,
  });

  final IconData icone;
  final String titulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Row(
            children: [
              Icon(icone, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 8),
              Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final (indice, campo) in children.indexed) ...[
          if (indice > 0) const SizedBox(height: 12),
          campo,
        ],
      ],
    ),
  );
}

/// Campo que abre o seletor de data, com a mesma aparência dos demais.
class CampoData extends StatelessWidget {
  const CampoData({
    super.key,
    required this.rotulo,
    required this.icone,
    required this.data,
    required this.aoSelecionar,
    this.ajuda,
    this.erro,
  });

  final String rotulo;
  final IconData icone;
  final DateTime? data;
  final VoidCallback aoSelecionar;
  final String? ajuda;
  final String? erro;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: aoSelecionar,
    borderRadius: const BorderRadius.all(Radius.circular(12)),
    child: InputDecorator(
      isEmpty: false,
      decoration: InputDecoration(
        labelText: rotulo,
        prefixIcon: Icon(icone),
        suffixIcon: const Icon(Icons.arrow_drop_down),
        helperText: ajuda,
        errorText: erro,
      ),
      child: Text(data == null ? 'Selecionar data' : DataCivil.formatar(data!)),
    ),
  );
}

/// Barra fixa no rodapé com a ação principal do formulário.
class BarraAcaoFixa extends StatelessWidget {
  const BarraAcaoFixa({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    key: const Key('barra-acao'),
    elevation: 8,
    color: Theme.of(context).colorScheme.surfaceContainer,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}
