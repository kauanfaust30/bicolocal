class DataCivil {
  static DateTime hojeEmSaoPaulo(DateTime agoraUtc) {
    final dataLocal = agoraUtc.toUtc().subtract(const Duration(hours: 3));
    return DateTime.utc(dataLocal.year, dataLocal.month, dataLocal.day);
  }

  static String chave(DateTime data) {
    final ano = data.year.toString().padLeft(4, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');
    return '$ano-$mes-$dia';
  }

  static DateTime inicioDiaUtc(String chave) {
    final partes = chave.split('-').map(int.parse).toList();
    return DateTime.utc(partes[0], partes[1], partes[2]);
  }

  static DateTime deChave(String chave) {
    final partes = chave.split('-').map(int.parse).toList();
    return DateTime(partes[0], partes[1], partes[2]);
  }

  static String formatar(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString().padLeft(4, '0');
    return '$dia/$mes/$ano';
  }

  static String formatarValor(int centavos) {
    final reais = centavos ~/ 100;
    final parteDecimal = (centavos % 100).toString().padLeft(2, '0');
    final reaisFormatados = reais.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'R\$ $reaisFormatados,$parteDecimal';
  }
}
