import 'package:bicolocal/core/app.dart';
import 'package:bicolocal/features/candidaturas/domain/candidatura.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/builders/test_data.dart';
import '../../../support/fakes/fake_repositories.dart';

/// Foto nas candidaturas só depois do aceite (FR-013, FR-020, SC-008).
void main() {
  final contratante = criarContaTeste(
    uid: 'contratante-1',
    nome: 'Ana Silva',
    perfil: Perfil.contratante,
  );
  final pedido = criarPedidoTeste(
    id: 'pedido-1',
    contratanteUid: contratante.uid,
    dataDesejada: DateTime.utc(2099, 1, 3),
    validadeAte: DateTime.utc(2099, 1, 2),
  );
  late FakeCandidaturaRepository candidaturas;

  Future<void> abrir(WidgetTester tester) async {
    candidaturas =
        FakeCandidaturaRepository(
            itens: const [
              Candidatura(
                pedidoId: 'pedido-1',
                prestadorUid: 'prestador-1',
                estado: EstadoCandidatura.pendente,
              ),
              Candidatura(
                pedidoId: 'pedido-1',
                prestadorUid: 'prestador-2',
                estado: EstadoCandidatura.pendente,
              ),
            ],
          )
          ..copiasFotoPrestador['pedido-1:prestador-1'] = criarFotoTeste(
            marca: 1,
          )
          ..copiasFotoPrestador['pedido-1:prestador-2'] = criarFotoTeste(
            marca: 2,
          );
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: contratante),
        pedidoRepository: FakePedidoRepository(pedidos: [pedido]),
        candidaturaRepository: candidaturas,
        perfilRepository: FakePerfilRepository(
          perfis: {
            'prestador-1': criarPerfilTeste(
              uid: 'prestador-1',
              nome: 'Bruno Lima',
            ),
            'prestador-2': criarPerfilTeste(
              uid: 'prestador-2',
              nome: 'Carla Dias',
            ),
          },
          fotoPropria: criarFotoTeste(marca: 9),
        ),
        avaliacaoRepository: FakeAvaliacaoRepository(),
        seletorFoto: FakeSeletorFoto(),
        initialLocation: '/pedidos/pedido-1/candidaturas',
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('candidaturas pendentes mostram nome e inicial, sem foto', (
    tester,
  ) async {
    await abrir(tester);

    expect(find.text('Bruno Lima'), findsOneWidget);
    expect(find.text('Carla Dias'), findsOneWidget);
    expect(find.bySemanticsLabel('Inicial de Bruno Lima'), findsOneWidget);
    expect(find.bySemanticsLabel('Inicial de Carla Dias'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Foto de')), findsNothing);
  });

  testWidgets('após aceitar, só o escolhido mostra a foto', (tester) async {
    await abrir(tester);

    await tester.tap(find.text('Aceitar candidatura').first);
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Foto de Bruno Lima'), findsOneWidget);
    expect(find.bySemanticsLabel('Inicial de Carla Dias'), findsOneWidget);
    expect(find.bySemanticsLabel('Foto de Carla Dias'), findsNothing);
    expect(candidaturas.copiasFotoContratante['pedido-1'], isNotNull);
  });
}
