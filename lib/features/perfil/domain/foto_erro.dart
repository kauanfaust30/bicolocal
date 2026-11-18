import 'foto_perfil.dart';

/// Falhas ao escolher ou enviar a foto, com a mensagem para a pessoa
/// (contracts/telas-e-rotas.md).
class FotoErro implements Exception {
  const FotoErro._(this.mensagem, {this.origemNegada});

  factory FotoErro.semPermissao(OrigemFoto origem) => FotoErro._(
    origem == OrigemFoto.camera
        ? 'Não conseguimos acessar a câmera. Permita o acesso nas '
              'configurações do celular ou escolha uma foto da galeria.'
        : 'Não conseguimos acessar a galeria. Permita o acesso nas '
              'configurações do celular ou tire uma foto com a câmera.',
    origemNegada: origem,
  );

  static const naoImagem = FotoErro._(
    'Esse arquivo não é uma foto. Escolha uma imagem.',
  );

  static const grandeDemais = FotoErro._(
    'Essa foto ficou grande demais. Escolha outra.',
  );

  static const envioFalhou = FotoErro._(
    'Não foi possível enviar sua foto. Verifique a conexão e tente de novo.',
  );

  final String mensagem;

  /// Origem que teve o acesso negado; a tela oferece a outra.
  final OrigemFoto? origemNegada;

  @override
  String toString() => mensagem;
}
