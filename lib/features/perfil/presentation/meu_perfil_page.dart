import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../avaliacoes/domain/avaliacao_repository.dart';
import '../../candidaturas/domain/candidatura_repository.dart';
import '../../conta/presentation/conta_controller.dart';
import '../domain/perfil_repository.dart';
import 'escolher_foto.dart';
import 'foto_propria_controller.dart';
import 'perfil_controller.dart';
import 'reputacao_perfil.dart';

/// Meu perfil: foto própria com "Trocar foto" (FR-019), nome, cidade, tipo,
/// reputação e avaliações recentes (FR-009, FR-012). Sem bairro nem e-mail.
class MeuPerfilPage extends StatelessWidget {
  const MeuPerfilPage({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (context) =>
            FotoPropriaController(context.read<PerfilRepository>())..carregar(),
      ),
      ChangeNotifierProvider(
        create: (context) {
          final controller = PerfilController(
            context.read<PerfilRepository>(),
            context.read<AvaliacaoRepository>(),
            context.read<CandidaturaRepository>(),
          );
          final uid = context.read<ContaController>().conta?.uid;
          if (uid != null) controller.carregar(uid);
          return controller;
        },
      ),
    ],
    child: Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: const SafeArea(child: _Conteudo()),
    ),
  );
}

class _Conteudo extends StatefulWidget {
  const _Conteudo();

  @override
  State<_Conteudo> createState() => _ConteudoState();
}

class _ConteudoState extends State<_Conteudo> {
  bool _trocando = false;

  @override
  Widget build(BuildContext context) {
    final conta = context.watch<ContaController>().conta;
    final nome = conta?.nome ?? '';
    final controller = context.watch<FotoPropriaController>();
    if (controller.carregando || conta == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final cores = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        if (_trocando)
          EscolherFoto(
            nome: nome,
            fotoAtual: controller.foto,
            enviando: controller.enviando,
            aoConfirmar: (foto) async {
              await controller.trocar(foto);
              if (mounted && controller.erro == null) {
                setState(() => _trocando = false);
              }
            },
          )
        else ...[
          CabecalhoPerfil(
            nome: nome,
            cidade: conta.cidade,
            perfil: conta.perfil,
            foto: controller.foto?.bytes,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => setState(() => _trocando = true),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Trocar foto'),
          ),
        ],
        if (controller.mensagem case final mensagem?)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(mensagem, textAlign: TextAlign.center),
          ),
        if (controller.erro case final erro?)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(erro, style: TextStyle(color: cores.error)),
          ),
        const SizedBox(height: 24),
        const ReputacaoPerfil(),
      ],
    );
  }
}
