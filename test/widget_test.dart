import 'package:bicolocal/core/app.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes/fake_repositories.dart';

void main() {
  testWidgets('abre a tela de cadastro do BicoLocal', (tester) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(),
        pedidoRepository: FakePedidoRepository(),
        candidaturaRepository: FakeCandidaturaRepository(),
        perfilRepository: FakePerfilRepository(),
        avaliacaoRepository: FakeAvaliacaoRepository(),
        seletorFoto: FakeSeletorFoto(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Cadastro'), findsOneWidget);
    expect(find.text('Serviços rápidos perto de você'), findsOneWidget);
  });
}
