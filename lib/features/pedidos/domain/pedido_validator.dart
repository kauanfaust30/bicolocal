import 'data_civil.dart';

class PedidoValidator {
  static Map<String, String> validar({
    required String titulo,
    required String categoriaId,
    required String descricao,
    required String cidade,
    required String local,
    required DateTime dataDesejada,
    required DateTime validadeAte,
    required int valorCentavos,
    required DateTime agoraUtc,
  }) {
    final erros = <String, String>{};
    final hojeChave = DataCivil.chave(DataCivil.hojeEmSaoPaulo(agoraUtc));
    final desejadaChave = DataCivil.chave(dataDesejada);
    final validadeChave = DataCivil.chave(validadeAte);

    if (titulo.trim().isEmpty) erros['titulo'] = 'Informe o título do pedido.';
    if (categoriaId.trim().isEmpty) {
      erros['categoriaId'] = 'Escolha uma categoria.';
    }
    if (descricao.trim().isEmpty) {
      erros['descricao'] = 'Descreva o serviço.';
    }
    if (cidade.trim().isEmpty) erros['cidade'] = 'Informe sua cidade.';
    if (local.trim().isEmpty) erros['local'] = 'Informe o local do serviço.';
    if (valorCentavos <= 0) {
      erros['valorCentavos'] = 'Informe um valor maior que zero.';
    }
    if (desejadaChave.compareTo(hojeChave) < 0) {
      erros['dataDesejada'] = 'Escolha hoje ou uma data futura.';
    }
    if (validadeChave.compareTo(hojeChave) < 0 ||
        validadeChave.compareTo(desejadaChave) > 0) {
      erros['validadeAte'] =
          'A validade deve ser hoje ou futura e não passar da data do serviço.';
    }
    return erros;
  }
}
