import 'package:bicolocal/core/app.dart';
import 'package:bicolocal/features/candidaturas/domain/candidatura.dart';
import 'package:bicolocal/features/candidaturas/domain/candidatura_repository.dart';
import 'package:bicolocal/features/conta/domain/conta.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:bicolocal/features/pedidos/domain/pedido.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes/fake_repositories.dart';

void main() {
  testWidgets('prestador envia candidatura pelo cartÃ£o do pedido', (
    tester,
  ) async {
    final candidaturas = _CandidaturaRepositoryFalso();
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: _prestador),
        pedidoRepository: FakePedidoRepository(pedidos: [_pedido()]),
        candidaturaRepository: candidaturas,
        initialLocation: '/pedidos',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Candidatar-se'));
    await tester.pumpAndSettle();

    expect(candidaturas.enviadas, 1);
    expect(find.text('Candidatura enviada.'), findsOneWidget);
  });

  testWidgets('contratante revisa e aceita uma candidatura', (tester) async {
    final candidaturas = _CandidaturaRepositoryFalso()..itens.add(_candidatura);
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: _contratante),
        pedidoRepository: FakePedidoRepository(pedidos: [_pedido()]),
        candidaturaRepository: candidaturas,
        initialLocation: '/inicio',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Meus pedidos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver candidaturas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aceitar candidatura'));
    await tester.pumpAndSettle();

    expect(candidaturas.prestadorAceito, _prestador.uid);
    await tester.scrollUntilVisible(
      find.textContaining(_prestador.email),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining(_prestador.email), findsOneWidget);
  });

  testWidgets('parte autorizada cancela pedido e recebe confirmaÃ§Ã£o', (
    tester,
  ) async {
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: _contratante),
        pedidoRepository: FakePedidoRepository(pedidos: [_pedido()]),
        candidaturaRepository: _CandidaturaRepositoryFalso(),
        initialLocation: '/inicio',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Meus pedidos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gerenciar pedido'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Cancelar pedido'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Cancelar pedido'), findsOneWidget);
    await tester.tap(find.text('Cancelar pedido'));
    await tester.pumpAndSettle();

    expect(find.text('Pedido cancelado.'), findsOneWidget);
  });

  testWidgets('contratante edita os dados do pedido', (tester) async {
    final pedidos = FakePedidoRepository(pedidos: [_pedido()]);
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: _contratante),
        pedidoRepository: pedidos,
        candidaturaRepository: _CandidaturaRepositoryFalso(),
        initialLocation: '/inicio',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Meus pedidos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gerenciar pedido'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Pintar a sala');
    await tester.scrollUntilVisible(
      find.text('Cancelar pedido'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    final salvar = find.byType(ElevatedButton).last;
    await tester.drag(find.byType(ListView).last, const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(salvar);
    await tester.pumpAndSettle();

    expect(pedidos.pedidos.single.titulo, 'Pintar a sala');
  });

  testWidgets('falha ao editar mostra orientaÃ§Ã£o para tentar novamente', (
    tester,
  ) async {
    final pedidos = FakePedidoRepository(pedidos: [_pedido()])
      ..falharAtualizacao = true;
    await tester.pumpWidget(
      BicoLocalApp(
        contaRepository: FakeContaRepository(contaInicial: _contratante),
        pedidoRepository: pedidos,
        candidaturaRepository: _CandidaturaRepositoryFalso(),
        initialLocation: '/inicio',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Meus pedidos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gerenciar pedido'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Cancelar pedido'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    final salvar = find.byType(ElevatedButton).last;
    await tester.drag(find.byType(ListView).last, const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(salvar);
    await tester.pumpAndSettle();

    expect(find.textContaining('Tente novamente'), findsOneWidget);
  });
}

class _CandidaturaRepositoryFalso implements CandidaturaRepository {
  final List<Candidatura> itens = [];
  int enviadas = 0;
  String? prestadorAceito;

  @override
  Future<Candidatura?> buscar({
    required String pedidoId,
    required String prestadorUid,
  }) async => itens
      .where(
        (item) =>
            item.pedidoId == pedidoId && item.prestadorUid == prestadorUid,
      )
      .firstOrNull;

  @override
  Future<List<Candidatura>> listar({required String pedidoId}) async =>
      itens.where((item) => item.pedidoId == pedidoId).toList();

  @override
  Future<void> candidatar(
    Candidatura candidatura, {
    required String emailPrestador,
  }) async {
    enviadas += 1;
    itens.add(candidatura);
  }

  @override
  Future<void> aceitar({
    required String pedidoId,
    required String prestadorUid,
    required String emailContratante,
    required DateTime agoraUtc,
  }) async {
    prestadorAceito = prestadorUid;
  }

  @override
  Future<String?> carregarEmailPrestador({
    required String pedidoId,
    required String prestadorUid,
  }) async => _prestador.email;

  @override
  Future<String?> carregarEmailContratante({
    required String pedidoId,
    required String contratanteUid,
  }) async => _contratante.email;
}

const _contratante = Conta(
  uid: 'contratante-1',
  email: 'ana@example.com',
  nome: 'Ana Silva',
  cidade: 'SÃ£o Paulo',
  bairro: 'Centro',
  perfil: Perfil.contratante,
);
const _prestador = Conta(
  uid: 'prestador-1',
  email: 'joao@example.com',
  nome: 'JoÃ£o Silva',
  cidade: 'SÃ£o Paulo',
  bairro: 'Centro',
  perfil: Perfil.prestador,
);
const _candidatura = Candidatura(
  pedidoId: 'pedido-1',
  prestadorUid: 'prestador-1',
  estado: EstadoCandidatura.pendente,
);

Pedido _pedido() => Pedido(
  id: 'pedido-1',
  contratanteUid: _contratante.uid,
  titulo: 'Montar uma estante',
  categoriaId: 'reparos',
  categoriaNome: 'Reparos',
  descricao: 'Montagem de estante',
  cidade: 'SÃ£o Paulo',
  local: 'Centro',
  dataDesejada: DateTime.utc(2099, 1, 3),
  validadeAte: DateTime.utc(2099, 1, 2),
  valorCentavos: 12000,
  estado: EstadoPedido.aberto,
);
