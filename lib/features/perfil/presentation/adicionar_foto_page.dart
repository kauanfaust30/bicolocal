import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../conta/presentation/conta_controller.dart';
import 'escolher_foto.dart';

/// Contas sem foto chegam aqui antes de qualquer outra tela (FR-018). Quando
/// a foto é enviada, o redirect do roteador leva ao início.
class AdicionarFotoPage extends StatelessWidget {
  const AdicionarFotoPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Adicionar foto'),
      automaticallyImplyLeading: false,
      actions: [
        TextButton(
          onPressed: () => context.read<ContaController>().sair(),
          child: const Text('Sair'),
        ),
      ],
    ),
    body: SafeArea(
      child: Consumer<ContaController>(
        builder: (context, controller, _) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Text(
              'Adicione uma foto de perfil',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'A foto ajuda a outra pessoa a saber com quem está tratando. '
              'Ela só aparece para a outra parte depois que uma candidatura é '
              'aceita.',
            ),
            const SizedBox(height: 24),
            EscolherFoto(
              nome: controller.conta?.nome ?? '',
              enviando: controller.enviandoFoto,
              aoConfirmar: controller.adicionarFoto,
            ),
            if (controller.enviandoFoto)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (controller.erroFoto case final erro?)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  erro,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
