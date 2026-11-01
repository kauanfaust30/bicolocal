enum Perfil { contratante, prestador }

extension PerfilLabel on Perfil {
  String get rotulo => switch (this) {
    Perfil.contratante => 'Contratante',
    Perfil.prestador => 'Prestador',
  };

  static Perfil? fromValue(String? value) {
    for (final perfil in Perfil.values) {
      if (perfil.name == value) return perfil;
    }
    return null;
  }
}
