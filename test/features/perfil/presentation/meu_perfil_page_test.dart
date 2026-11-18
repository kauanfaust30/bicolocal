import 'dart:async';

import 'package:bicolocal/core/app.dart';
import 'package:bicolocal/features/avaliacoes/domain/avaliacao.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:bicolocal/features/perfil/domain/perfil_publico.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/builders/test_data.dart';
import '../../../support/fakes/fake_repositories.dart';

/// Meu perfil com reputação e avaliações recentes (FR-008 a FR-012).
void main() {
  final conta = criarContaTeste(
    uid: 'ana',
    nome: 'Ana Silva',
    cidade: 'Rio do Sul',
    bairro: 'Bairro Secreto',
    email: 'ana@example.com',
    perfil: Perfil.prestador,
  );

  Future<FakeAvaliacaoRepository> abrir(
    WidgetTester tester, {
    PerfilPublico? perfil,
    List<Avaliacao> avaliacoes = const [],
    FakeAvaliacaoRepository? repositorio,
    bool aguardar = true,
  }) async {
    final avaliacoesRepo = (repositorio ?? FakeAvaliacaoRepository())
      ..avaliacoes.addAll(avaliacoes);
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: conta),
        pedidoRepository: FakePedidoRepository(),
        candidaturaRepository: FakeCandidaturaRepository(),
        perfilRepository: FakePerfilRepository(
          perfis: {'ana': ?perfil},
          fotoPropria: criarFotoTeste(),
        ),
        avaliacaoRepository: avaliacoesRepo,
        seletorFoto: FakeSeletorFoto(),
        initialLocation: '/perfil',
      ),
    );
    if (aguardar) await tester.pumpAndSettle();
    return avaliacoesRepo;
  }

  PerfilPublico perfilAna({int soma = 0, int total = 0}) => criarPerfilTeste(
    uid: 'ana',
    nome: 'Ana Silva',
    cidade: 'Rio do Sul',
    perfil: Perfil.prestador,
    somaNotas: soma,
    totalAvaliacoes: total,
  );

  testWidgets('mostra nome, cidade, tipo, média e total', (tester) async {
    await abrir(
      tester,
      perfil: perfilAna(soma: 56, total: 12),
      avaliacoes: [criarAvaliacaoTeste(avaliadoUid: 'ana')],
    );

    expect(find.text('Ana Silva'), findsOneWidget);
    expect(find.text('Rio do Sul'), findsOneWidget);
    expect(find.text('Prestador'), findsOneWidget);
    expect(find.text('4,7 ★'), findsOneWidget);
    expect(find.text('12 avaliações'), findsOneWidget);
  });

  testWidgets('uma avaliação usa o singular', (tester) async {
    await abrir(
      tester,
      perfil: perfilAna(soma: 5, total: 1),
      avaliacoes: [criarAvaliacaoTeste(avaliadoUid: 'ana')],
    );

    expect(find.text('5,0 ★'), findsOneWidget);
    expect(find.text('1 avaliação'), findsOneWidget);
  });

  testWidgets('mostra as 5 mais recentes com nota, comentário, nome e data', (
    tester,
  ) async {
    await abrir(
      tester,
      perfil: perfilAna(soma: 24, total: 6),
      avaliacoes: [
        for (var dia = 1; dia <= 6; dia++)
          criarAvaliacaoTeste(
            pedidoId: 'p$dia',
            avaliadoUid: 'ana',
            avaliadorNome: 'Pessoa $dia',
            nota: dia == 6 ? 5 : 4,
            comentario: dia == 6 ? 'Muito caprichosa' : '',
            criadaEm: DateTime.utc(2026, 11, dia, 15),
          ),
      ],
    );

    // A mais nova vem primeiro.
    await tester.scrollUntilVisible(find.text('Pessoa 6'), 100);
    expect(find.text('Muito caprichosa'), findsOneWidget);
    expect(find.text('06/11/2026'), findsOneWidget);
    expect(find.bySemanticsLabel('Nota 5 de 5'), findsOneWidget);

    for (var dia = 5; dia >= 2; dia--) {
      await tester.scrollUntilVisible(find.text('Pessoa $dia'), 100);
      expect(find.text('Pessoa $dia'), findsOneWidget);
    }
    expect(find.text('Pessoa 1'), findsNothing);
    expect(find.text('Ainda sem avaliações'), findsNothing);
  });

  testWidgets('data da avaliação usa o fuso de São Paulo (FR-008)', (
    tester,
  ) async {
    await abrir(
      tester,
      perfil: perfilAna(soma: 5, total: 1),
      avaliacoes: [
        // 01h UTC do dia 10 ainda é dia 9 em São Paulo.
        criarAvaliacaoTeste(
          avaliadoUid: 'ana',
          criadaEm: DateTime.utc(2026, 11, 10, 1),
        ),
      ],
    );

    expect(find.text('09/11/2026'), findsOneWidget);
  });

  testWidgets('sem avaliações mostra "Ainda sem avaliações"', (tester) async {
    await abrir(tester, perfil: perfilAna());

    expect(find.text('Ainda sem avaliações'), findsOneWidget);
    expect(find.textContaining('★'), findsNothing);
  });

  testWidgets('enquanto carrega mostra o indicador', (tester) async {
    final repositorio = FakeAvaliacaoRepository()
      ..bloquearListagem = Completer<void>();
    await abrir(
      tester,
      perfil: perfilAna(soma: 5, total: 1),
      repositorio: repositorio,
      aguardar: false,
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Carregando avaliações…'), findsOneWidget);

    repositorio.bloquearListagem!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Carregando avaliações…'), findsNothing);
  });

  testWidgets('erro mostra a mensagem e "Tentar novamente"', (tester) async {
    final repositorio = FakeAvaliacaoRepository()..falhasListagem = 1;
    await abrir(
      tester,
      perfil: perfilAna(soma: 5, total: 1),
      avaliacoes: [
        criarAvaliacaoTeste(avaliadoUid: 'ana', avaliadorNome: 'Bruno'),
      ],
      repositorio: repositorio,
    );

    expect(
      find.text('Não foi possível carregar as avaliações.'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Tentar novamente'));
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Bruno'), findsOneWidget);
  });

  testWidgets('nunca mostra bairro nem e-mail (FR-010)', (tester) async {
    await abrir(
      tester,
      perfil: perfilAna(soma: 5, total: 1),
      avaliacoes: [criarAvaliacaoTeste(avaliadoUid: 'ana')],
    );

    expect(find.textContaining('Bairro Secreto'), findsNothing);
    expect(find.textContaining('ana@example.com'), findsNothing);
  });
}
