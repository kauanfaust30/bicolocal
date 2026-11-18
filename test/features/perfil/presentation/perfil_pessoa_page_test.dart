import 'package:bicolocal/core/app.dart';
import 'package:bicolocal/features/candidaturas/domain/candidatura.dart';
import 'package:bicolocal/features/conta/domain/conta.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:bicolocal/features/pedidos/domain/pedido.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/builders/test_data.dart';
import '../../../support/fakes/fake_repositories.dart';

/// Perfil de outra pessoa, aberto a partir de um pedido (FR-013 a FR-015).
void main() {
  final contratante = criarContaTeste(
    uid: 'contratante-1',
    nome: 'Ana Silva',
    perfil: Perfil.contratante,
  );
  final prestador = criarContaTeste(
    uid: 'prestador-1',
    nome: 'Bruno Lima',
    email: 'bruno@example.com',
    bairro: 'Bairro do Bruno',
  );
  final aberto = criarPedidoTeste(
    id: 'pedido-1',
    contratanteUid: contratante.uid,
    titulo: 'Pintar a sala',
    cidade: 'São Paulo',
    dataDesejada: DateTime.utc(2099, 1, 3),
    validadeAte: DateTime.utc(2099, 1, 2),
  );
  final emAndamento = aberto.copyWith(
    estado: EstadoPedido.emAndamento,
    prestadorEscolhidoUid: prestador.uid,
  );

  Future<void> abrir(
    WidgetTester tester, {
    required Conta conta,
    required Pedido pedido,
    required String local,
    EstadoCandidatura estado = EstadoCandidatura.pendente,
  }) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: conta),
        pedidoRepository: FakePedidoRepository(pedidos: [pedido]),
        candidaturaRepository:
            FakeCandidaturaRepository(
                itens: [
                  Candidatura(
                    pedidoId: 'pedido-1',
                    prestadorUid: 'prestador-1',
                    estado: estado,
                  ),
                ],
              )
              ..copiasFotoPrestador['pedido-1:prestador-1'] = criarFotoTeste(
                marca: 1,
              )
              ..copiasFotoContratante['pedido-1'] = criarFotoTeste(marca: 2),
        perfilRepository: FakePerfilRepository(
          perfis: {
            'prestador-1': criarPerfilTeste(
              uid: 'prestador-1',
              nome: 'Bruno Lima',
              cidade: 'Rio do Sul',
              somaNotas: 9,
              totalAvaliacoes: 2,
            ),
            'contratante-1': criarPerfilTeste(
              uid: 'contratante-1',
              nome: 'Ana Silva',
              perfil: Perfil.contratante,
            ),
          },
        ),
        avaliacaoRepository: FakeAvaliacaoRepository()
          ..avaliacoes.add(
            criarAvaliacaoTeste(
              avaliadoUid: 'prestador-1',
              avaliadorNome: 'Carla Dias',
              comentario: 'Pontual',
            ),
          ),
        seletorFoto: FakeSeletorFoto(),
        initialLocation: local,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'contratante abre o candidato pelas candidaturas e vê a inicial',
    (tester) async {
      await abrir(
        tester,
        conta: contratante,
        pedido: aberto,
        local: '/pedidos/pedido-1/candidaturas',
      );

      await tester.tap(find.text('Bruno Lima'));
      await tester.pumpAndSettle();

      expect(find.text('Perfil'), findsOneWidget);
      expect(find.text('Rio do Sul'), findsOneWidget);
      expect(find.text('Prestador'), findsOneWidget);
      expect(find.text('4,5 ★'), findsOneWidget);
      expect(find.text('2 avaliações'), findsOneWidget);
      expect(find.text('Pontual'), findsOneWidget);
      expect(find.text('Carla Dias'), findsOneWidget);
      expect(find.bySemanticsLabel('Inicial de Bruno Lima'), findsOneWidget);
      expect(find.bySemanticsLabel('Foto de Bruno Lima'), findsNothing);
      expect(find.text('Trocar foto'), findsNothing);
    },
  );

  testWidgets('candidaturas mostram a nota média do candidato', (tester) async {
    await abrir(
      tester,
      conta: contratante,
      pedido: aberto,
      local: '/pedidos/pedido-1/candidaturas',
    );

    expect(find.text('4,5 ★ · 2 avaliações'), findsOneWidget);
  });

  testWidgets('após o aceite, o contratante vê a foto do escolhido', (
    tester,
  ) async {
    await abrir(
      tester,
      conta: contratante,
      pedido: emAndamento,
      estado: EstadoCandidatura.aceita,
      local: '/perfis/prestador-1?pedido=pedido-1',
    );

    expect(find.bySemanticsLabel('Foto de Bruno Lima'), findsOneWidget);
  });

  testWidgets(
    'prestador vê o contratante pela lista da cidade, com a inicial',
    (tester) async {
      await abrir(tester, conta: prestador, pedido: aberto, local: '/pedidos');

      await tester.ensureVisible(find.text('Ver contratante'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver contratante'));
      await tester.pumpAndSettle();

      expect(find.text('Ana Silva'), findsOneWidget);
      expect(find.text('Contratante'), findsOneWidget);
      expect(find.text('Ainda sem avaliações'), findsOneWidget);
      expect(find.bySemanticsLabel('Inicial de Ana Silva'), findsOneWidget);
      expect(find.bySemanticsLabel('Foto de Ana Silva'), findsNothing);
    },
  );

  testWidgets('prestador escolhido vê a foto do contratante pelo pedido', (
    tester,
  ) async {
    await abrir(
      tester,
      conta: prestador,
      pedido: emAndamento,
      local: '/pedidos/pedido-1/gerenciar',
    );

    await tester.tap(find.bySemanticsLabel(RegExp('Ana Silva')).first);
    await tester.pumpAndSettle();

    expect(find.text('Perfil'), findsOneWidget);
    expect(find.bySemanticsLabel('Foto de Ana Silva'), findsOneWidget);
  });

  testWidgets('sem pedido na rota vai para o início', (tester) async {
    await abrir(
      tester,
      conta: contratante,
      pedido: aberto,
      local: '/perfis/prestador-1',
    );

    expect(find.text('Perfil'), findsNothing);
    expect(find.text('Meu perfil'), findsOneWidget);
  });

  testWidgets('nunca mostra bairro nem e-mail (FR-010, FR-015)', (
    tester,
  ) async {
    await abrir(
      tester,
      conta: contratante,
      pedido: emAndamento,
      estado: EstadoCandidatura.aceita,
      local: '/perfis/prestador-1?pedido=pedido-1',
    );

    expect(find.textContaining('Bairro do Bruno'), findsNothing);
    expect(find.textContaining('bruno@example.com'), findsNothing);
  });
}
