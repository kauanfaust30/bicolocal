import 'package:bicolocal/core/app.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/builders/test_data.dart';
import '../../../support/fakes/fake_repositories.dart';

/// Trocar a foto em Meu perfil (FR-019).
void main() {
  final fotoAntiga = criarFotoTeste(marca: 1);
  final fotoNova = criarFotoTeste(marca: 2);
  late FakePerfilRepository perfis;

  Future<void> abrir(WidgetTester tester, {required String caminho}) async {
    perfis = FakePerfilRepository(fotoPropria: fotoAntiga);
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(
          contaInicial: criarContaTeste(nome: 'Ana Silva'),
        ),
        pedidoRepository: FakePedidoRepository(),
        candidaturaRepository: FakeCandidaturaRepository(),
        perfilRepository: perfis,
        avaliacaoRepository: FakeAvaliacaoRepository(),
        seletorFoto: FakeSeletorFoto(foto: fotoNova),
        initialLocation: caminho,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Meu perfil abre pelo início e mostra a própria foto', (
    tester,
  ) async {
    await abrir(tester, caminho: '/inicio');

    await tester.tap(find.text('Meu perfil'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Foto de Ana Silva'), findsOneWidget);
    expect(find.text('Trocar foto'), findsOneWidget);
  });

  testWidgets('trocar foto com prévia grava a nova foto', (tester) async {
    await abrir(tester, caminho: '/perfil');

    await tester.tap(find.text('Trocar foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escolher da galeria'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar esta foto'));
    await tester.pumpAndSettle();

    expect(perfis.fotoPropria, same(fotoNova));
    expect(find.text('Foto atualizada.'), findsOneWidget);
  });

  testWidgets('falha na troca mantém a foto anterior', (tester) async {
    await abrir(tester, caminho: '/perfil');
    perfis.falharProximoEnvio = true;

    await tester.tap(find.text('Trocar foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escolher da galeria'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar esta foto'));
    await tester.pumpAndSettle();

    expect(perfis.fotoPropria, same(fotoAntiga));
    expect(
      find.text(
        'Não foi possível enviar sua foto. Verifique a conexão e tente de novo.',
      ),
      findsOneWidget,
    );
  });
}
