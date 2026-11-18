import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/avatar_pessoa.dart';
import '../domain/foto_erro.dart';
import '../domain/foto_perfil.dart';
import '../domain/seletor_foto.dart';

/// Tirar foto ou escolher da galeria, com prévia antes de confirmar
/// (FR-016, FR-019, FR-021, FR-022). Usado no cadastro, em Adicionar foto e
/// em Trocar foto.
class EscolherFoto extends StatefulWidget {
  const EscolherFoto({
    super.key,
    required this.nome,
    required this.aoConfirmar,
    this.fotoAtual,
    this.enviando = false,
  });

  /// Nome da pessoa, para a inicial e o rótulo acessível.
  final String nome;
  final FotoPerfil? fotoAtual;
  final ValueChanged<FotoPerfil> aoConfirmar;

  /// Enquanto verdadeiro, os botões ficam desativados.
  final bool enviando;

  @override
  State<EscolherFoto> createState() => _EscolherFotoState();
}

class _EscolherFotoState extends State<EscolherFoto> {
  FotoPerfil? _previa;
  String? _erro;

  Future<void> _escolher(OrigemFoto origem) async {
    setState(() => _erro = null);
    try {
      final foto = await context.read<SeletorFoto>().escolher(origem);
      if (!mounted || foto == null) return;
      setState(() => _previa = foto);
    } on FotoErro catch (falha) {
      if (mounted) setState(() => _erro = falha.mensagem);
    } catch (_) {
      if (mounted) setState(() => _erro = FotoErro.naoImagem.mensagem);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A prévia some quando o pai passa a usá-la como foto atual (confirmada
    // e, quando há envio, enviada com sucesso). Se o envio falhar, a prévia
    // continua para a pessoa tentar de novo.
    final previa = identical(_previa, widget.fotoAtual) ? null : _previa;
    final mostrada = previa ?? widget.fotoAtual;
    final cores = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: AvatarPessoa(
            nome: widget.nome.trim().isEmpty ? 'Você' : widget.nome,
            bytes: mostrada?.bytes,
            tamanho: 112,
          ),
        ),
        const SizedBox(height: 16),
        if (previa != null) ...[
          ElevatedButton.icon(
            onPressed: widget.enviando
                ? null
                : () {
                    widget.aoConfirmar(previa);
                  },
            icon: const Icon(Icons.check),
            label: const Text('Usar esta foto'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: widget.enviando
                ? null
                : () => setState(() {
                    _previa = null;
                    _erro = null;
                  }),
            icon: const Icon(Icons.refresh),
            label: const Text('Escolher outra'),
          ),
        ] else ...[
          OutlinedButton.icon(
            onPressed: widget.enviando
                ? null
                : () => _escolher(OrigemFoto.camera),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Tirar foto'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: widget.enviando
                ? null
                : () => _escolher(OrigemFoto.galeria),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Escolher da galeria'),
          ),
        ],
        if (_erro != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_erro!, style: TextStyle(color: cores.error)),
          ),
      ],
    );
  }
}
