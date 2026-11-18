import 'package:bicolocal/core/app.dart';
import 'package:bicolocal/features/perfil/domain/foto_erro.dart';
import 'package:bicolocal/features/perfil/domain/foto_perfil.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/builders/test_data.dart';
import '../../../support/fakes/fake_repositories.dart';

/// Adicionar foto para contas sem foto (FR-018, FR-021, FR-022).
void main() {
  late FakeContaRepository contas;
  late FakeSeletorFoto seletor;

  Future<void> abrir(WidgetTester tester) async {
    contas = FakeContaRepository(
      contaInicial: criarContaTeste(nome: 'Ana Silva', temFoto: false),
    );
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: contas,
        pedidoRepository: FakePedidoRepository(),
        candidaturaRepository: FakeCandidaturaRepository(),
        perfilRepository: FakePerfilRepository(),
        avaliacaoRepository: FakeAvaliacaoRepository(),
        seletorFoto: seletor,
        initialLocation: '/inicio',
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => seletor = FakeSeletorFoto(foto: criarFotoTeste()));

  testWidgets('enviar a foto leva ao início', (tester) async {
    await abrir(tester);

    await tester.tap(find.text('Escolher da galeria'));
    await tester.pumpAndSettle();
    expect(find.text('Usar esta foto'), findsOneWidget);
    expect(find.text('Escolher outra'), findsOneWidget);

    await tester.tap(find.text('Usar esta foto'));
    await tester.pumpAndSettle();

    expect(contas.fotoAdicionada, isNotNull);
    expect(find.text('Olá, Ana Silva'), findsOneWidget);
  });

  testWidgets('falha no envio mantém na tela e permite tentar de novo', (
    tester,
  ) async {
    await abrir(tester);
    contas.falharProximaFoto = true;

    await tester.tap(find.text('Tirar foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar esta foto'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Não foi possível enviar sua foto. Verifique a conexão e tente de novo.',
      ),
      findsOneWidget,
    );
    expect(find.text('Usar esta foto'), findsOneWidget);

    await tester.tap(find.text('Usar esta foto'));
    await tester.pumpAndSettle();
    expect(find.text('Olá, Ana Silva'), findsOneWidget);
  });

  testWidgets('"Escolher outra" volta para as duas origens', (tester) async {
    await abrir(tester);

    await tester.tap(find.text('Escolher da galeria'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escolher outra'));
    await tester.pumpAndSettle();

    expect(find.text('Tirar foto'), findsOneWidget);
    expect(find.text('Escolher da galeria'), findsOneWidget);
    expect(find.text('Usar esta foto'), findsNothing);
  });

  final mensagens = <String, FotoErro>{
    'Esse arquivo não é uma foto. Escolha uma imagem.': FotoErro.naoImagem,
    'Essa foto ficou grande demais. Escolha outra.': FotoErro.grandeDemais,
    'Não conseguimos acessar a câmera. Permita o acesso nas configurações do '
        'celular ou escolha uma foto da galeria.': FotoErro.semPermissao(
      OrigemFoto.camera,
    ),
  };
  for (final MapEntry(key: mensagem, value: erro) in mensagens.entries) {
    testWidgets('mostra "$mensagem"', (tester) async {
      seletor = FakeSeletorFoto(erro: erro);
      await abrir(tester);

      await tester.tap(find.text('Tirar foto'));
      await tester.pumpAndSettle();

      expect(find.text(mensagem), findsOneWidget);
      expect(find.text('Escolher da galeria'), findsOneWidget);
      expect(contas.fotoAdicionada, isNull);
    });
  }
}
