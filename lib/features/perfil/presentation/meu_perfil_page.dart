import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/avatar_pessoa.dart';
import '../../conta/presentation/conta_controller.dart';
import '../domain/perfil_repository.dart';
import 'escolher_foto.dart';
import 'foto_propria_controller.dart';

/// Meu perfil: nesta etapa, a própria foto e a troca de foto (História 1).
/// Nome, reputação e avaliações recentes entram na História 3 (T058).
class MeuPerfilPage extends StatelessWidget {
  const MeuPerfilPage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) =>
        FotoPropriaController(context.read<PerfilRepository>())..carregar(),
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
    final nome = context.watch<ContaController>().conta?.nome ?? '';
    final controller = context.watch<FotoPropriaController>();
    if (controller.carregando) {
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
          Center(
            child: AvatarPessoa(
              nome: nome,
              bytes: controller.foto?.bytes,
              tamanho: 112,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nome,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
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
      ],
    );
  }
}
