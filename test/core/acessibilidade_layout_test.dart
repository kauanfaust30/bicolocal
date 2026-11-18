import 'package:bicolocal/core/app.dart';
import 'package:bicolocal/features/conta/domain/conta.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:bicolocal/features/pedidos/domain/categoria.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders/test_data.dart';
import '../support/fakes/fake_repositories.dart';

void main() {
  final contratante = criarContaTeste(
    uid: 'contratante-1',
    perfil: Perfil.contratante,
  );
  final prestador = criarContaTeste(uid: 'prestador-1');
  final pedido = criarPedidoTeste(
    id: 'pedido-1',
    contratanteUid: contratante.uid,
    dataDesejada: DateTime.utc(2099, 1, 3),
    validadeAte: DateTime.utc(2099, 1, 2),
  );

  Future<void> abrir(
    WidgetTester tester, {
    required String caminho,
    Conta? conta,
  }) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: conta),
        pedidoRepository: FakePedidoRepository(
          categorias: const [
            Categoria(id: 'reparos', nome: 'Reparos'),
            Categoria(id: 'limpeza', nome: 'Limpeza'),
          ],
          pedidos: [pedido],
        ),
        candidaturaRepository: FakeCandidaturaRepository(),
        perfilRepository: FakePerfilRepository(),
        avaliacaoRepository: FakeAvaliacaoRepository(),
        seletorFoto: FakeSeletorFoto(),
        initialLocation: caminho,
      ),
    );
    await tester.pumpAndSettle();
  }

  final telas = <String, (String, Conta?)>{
    'entrada': ('/entrar', null),
    'cadastro': ('/cadastro', null),
    'início': ('/inicio', contratante),
    'novo pedido': ('/pedidos/novo', contratante),
    'meus pedidos': ('/meus-pedidos', contratante),
    'gerenciar pedido': ('/pedidos/pedido-1/gerenciar', contratante),
    'pedidos por cidade': ('/pedidos', prestador),
  };

  for (final MapEntry(key: nome, value: (caminho, conta)) in telas.entries) {
    testWidgets('$nome: alvos de toque de 48 px e com rótulo', (tester) async {
      final semantica = tester.ensureSemantics();
      await abrir(tester, caminho: caminho, conta: conta);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantica.dispose();
    });
  }

  testWidgets('em tela larga o conteúdo fica centralizado com até 600 px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await abrir(tester, caminho: '/inicio', conta: contratante);

    final conteudo = tester.getRect(find.byType(Scaffold).first);
    expect(conteudo.width, lessThanOrEqualTo(600));
    expect(conteudo.center.dx, closeTo(800, 1));
  });

  testWidgets('em celular o conteúdo usa a largura toda', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await abrir(tester, caminho: '/inicio', conta: contratante);

    expect(tester.getRect(find.byType(Scaffold).first).width, 360);
  });
}
