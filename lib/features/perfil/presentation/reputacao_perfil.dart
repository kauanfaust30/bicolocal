import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/async/async_state.dart';
import '../../../core/widgets/avatar_pessoa.dart';
import '../../avaliacoes/domain/avaliacao.dart';
import '../../conta/domain/perfil.dart';
import '../../pedidos/domain/data_civil.dart';
import 'perfil_controller.dart';

/// Foto (ou inicial), nome, cidade e selo do tipo. Nunca bairro nem e-mail
/// (FR-010).
class CabecalhoPerfil extends StatelessWidget {
  const CabecalhoPerfil({
    super.key,
    required this.nome,
    required this.cidade,
    required this.perfil,
    this.foto,
  });

  final String nome;
  final String cidade;
  final Perfil perfil;
  final Uint8List? foto;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Column(
      children: [
        AvatarPessoa(nome: nome, bytes: foto, tamanho: 112),
        const SizedBox(height: 12),
        Text(nome, textAlign: TextAlign.center, style: texto.titleLarge),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on_outlined, size: 18),
            const SizedBox(width: 4),
            Text(cidade, style: texto.bodyMedium),
          ],
        ),
        const SizedBox(height: 8),
        Chip(label: Text(perfil.rotulo)),
      ],
    );
  }
}

/// Nota média, total e as 5 avaliações recentes, com os estados de
/// carregando, vazio e erro (FR-008, FR-009, FR-011). Lê o
/// [PerfilController] do contexto.
class ReputacaoPerfil extends StatelessWidget {
  const ReputacaoPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PerfilController>();
    final perfil = controller.perfil;
    final avaliacoes = controller.avaliacoes;
    if (perfil.status == AsyncStatus.erro ||
        avaliacoes.status == AsyncStatus.erro) {
      return _Erro(
        mensagem: perfil.status == AsyncStatus.erro
            ? perfil.mensagemErro!
            : avaliacoes.mensagemErro!,
        aoTentarNovamente: controller.tentarNovamente,
      );
    }
    final dados = perfil.data;
    if (dados == null) return const _Carregando();
    if (dados.semAvaliacoes) return const _SemAvaliacoes();
    final texto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${dados.notaExibida} ★', style: texto.headlineSmall),
            const SizedBox(width: 12),
            Text(dados.totalExibido, style: texto.bodyLarge),
          ],
        ),
        const SizedBox(height: 20),
        Text('Avaliações recentes', style: texto.titleMedium),
        const SizedBox(height: 8),
        if (avaliacoes.status != AsyncStatus.sucesso)
          const _Carregando()
        else if (avaliacoes.data!.isEmpty)
          const _SemAvaliacoes()
        else
          for (final avaliacao in avaliacoes.data!)
            _CartaoAvaliacao(avaliacao: avaliacao),
      ],
    );
  }
}

class _CartaoAvaliacao extends StatelessWidget {
  const _CartaoAvaliacao({required this.avaliacao});

  final Avaliacao avaliacao;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final data = avaliacao.criadaEm;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Semantics(
                  container: true,
                  label: 'Nota ${avaliacao.nota} de 5',
                  excludeSemantics: true,
                  child: Text('${avaliacao.nota} ★', style: texto.titleMedium),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(avaliacao.avaliadorNome)),
                if (data != null)
                  // Data no fuso de São Paulo, dd/MM/aaaa (FR-008).
                  Text(DataCivil.formatar(DataCivil.hojeEmSaoPaulo(data))),
              ],
            ),
            if (avaliacao.comentario.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(avaliacao.comentario),
            ],
          ],
        ),
      ),
    );
  }
}

class _SemAvaliacoes extends StatelessWidget {
  const _SemAvaliacoes();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 16),
    child: Text('Ainda sem avaliações', textAlign: TextAlign.center),
  );
}

class _Carregando extends StatelessWidget {
  const _Carregando();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 16),
    child: Column(
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 8),
        Text('Carregando avaliações…'),
      ],
    ),
  );
}

class _Erro extends StatelessWidget {
  const _Erro({required this.mensagem, required this.aoTentarNovamente});

  final String mensagem;
  final VoidCallback aoTentarNovamente;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Column(
      children: [
        Text(
          mensagem,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: aoTentarNovamente,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      ],
    ),
  );
}
