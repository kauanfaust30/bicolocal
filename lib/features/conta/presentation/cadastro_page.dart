import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/bicolocal_logo.dart';
import '../../perfil/domain/foto_perfil.dart';
import '../../perfil/presentation/escolher_foto.dart';
import '../domain/perfil.dart';
import 'conta_controller.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _nome = TextEditingController();
  final _cidade = TextEditingController();
  final _bairro = TextEditingController();
  Perfil? _perfil;
  FotoPerfil? _foto;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    _nome.dispose();
    _cidade.dispose();
    _bairro.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    final controller = context.read<ContaController>();
    await controller.cadastrar(
      email: _email.text,
      senha: _senha.text,
      nome: _nome.text,
      cidade: _cidade.text,
      bairro: _bairro.text,
      perfil: _perfil,
      foto: _foto,
    );
    if (mounted && controller.conta != null && controller.erro == null) {
      context.go('/inicio');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cadastro')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Consumer<ContaController>(
            builder: (context, controller, _) => ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                const BicoLocalLogo(),
                const SizedBox(height: 24),
                const _TituloSecao(icone: Icons.lock_outline, titulo: 'Acesso'),
                _campo('E-mail', _email, 'email', controller),
                const SizedBox(height: 12),
                _campo('Senha', _senha, 'senha', controller, segredo: true),
                const SizedBox(height: 24),
                const _TituloSecao(
                  icone: Icons.person_outline,
                  titulo: 'Seus dados',
                ),
                _campo('Nome', _nome, 'nome', controller),
                const SizedBox(height: 12),
                _campo('Cidade', _cidade, 'cidade', controller),
                const SizedBox(height: 12),
                _campo('Bairro', _bairro, 'bairro', controller),
                const SizedBox(height: 24),
                const _TituloSecao(
                  icone: Icons.account_circle_outlined,
                  titulo: 'Foto de perfil',
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Sua foto só aparece para a outra pessoa depois que uma '
                    'candidatura é aceita.',
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: _nome,
                  builder: (context, valor, _) => EscolherFoto(
                    nome: valor.text,
                    fotoAtual: _foto,
                    aoConfirmar: (foto) => setState(() => _foto = foto),
                  ),
                ),
                if (controller.errosCampos['foto'] case final erro?)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12),
                    child: Text(
                      erro,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                const _TituloSecao(
                  icone: Icons.badge_outlined,
                  titulo: 'Perfil',
                ),
                _OpcaoPerfil(
                  icone: Icons.home_outlined,
                  titulo: 'Preciso de um serviço',
                  descricao: 'Contratante: publique pedidos e escolha quem vai ajudar.',
                  selecionado: _perfil == Perfil.contratante,
                  aoSelecionar: () =>
                      setState(() => _perfil = Perfil.contratante),
                ),
                const SizedBox(height: 12),
                _OpcaoPerfil(
                  icone: Icons.handyman_outlined,
                  titulo: 'Quero fazer bicos',
                  descricao: 'Prestador: encontre pedidos na sua cidade e candidate-se.',
                  selecionado: _perfil == Perfil.prestador,
                  aoSelecionar: () =>
                      setState(() => _perfil = Perfil.prestador),
                ),
                if (controller.errosCampos['perfil'] case final erro?)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12),
                    child: Text(
                      erro,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                const _AvisoPerfilDefinitivo(),
                const SizedBox(height: 16),
                if (controller.erro != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      controller.erro!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ElevatedButton(
                  onPressed: controller.carregando ? null : _cadastrar,
                  child: Text(
                    controller.carregando ? 'Criando conta…' : 'Criar conta',
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/entrar'),
                  child: const Text('Já tenho uma conta'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _campo(
    String label,
    TextEditingController textController,
    String chave,
    ContaController estado, {
    bool segredo = false,
  }) => TextFormField(
    controller: textController,
    obscureText: segredo,
    keyboardType: chave == 'email' ? TextInputType.emailAddress : null,
    decoration: InputDecoration(
      labelText: label,
      errorText: estado.errosCampos[chave],
    ),
  );
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao({required this.icone, required this.titulo});

  final IconData icone;
  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Semantics(
      header: true,
      child: Row(
        children: [
          Icon(icone, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 8),
          Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    ),
  );
}

class _OpcaoPerfil extends StatelessWidget {
  const _OpcaoPerfil({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.selecionado,
    required this.aoSelecionar,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final bool selecionado;
  final VoidCallback aoSelecionar;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final forma = RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      side: BorderSide(
        color: selecionado ? cores.primary : cores.outlineVariant,
        width: selecionado ? 2 : 1,
      ),
    );
    return Semantics(
      button: true,
      selected: selecionado,
      child: Card(
        shape: forma,
        color: selecionado ? cores.primaryContainer : null,
        child: InkWell(
          customBorder: forma,
          onTap: aoSelecionar,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: selecionado
                      ? cores.primary
                      : cores.secondaryContainer,
                  child: Icon(
                    icone,
                    color: selecionado
                        ? cores.onPrimary
                        : cores.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(descricao),
                    ],
                  ),
                ),
                Icon(
                  selecionado
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selecionado ? cores.primary : cores.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvisoPerfilDefinitivo extends StatelessWidget {
  const _AvisoPerfilDefinitivo();

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cores.tertiaryContainer,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: cores.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'O perfil escolhido não poderá ser alterado depois.',
              style: TextStyle(color: cores.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
