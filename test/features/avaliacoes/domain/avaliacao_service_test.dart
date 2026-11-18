import 'package:bicolocal/features/avaliacoes/domain/avaliacao_erro.dart';
import 'package:bicolocal/features/avaliacoes/domain/avaliacao_service.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:bicolocal/features/pedidos/domain/pedido.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/builders/test_data.dart';
import '../../../support/fakes/fake_repositories.dart';

void main() {
  final contratante = criarContaTeste(
    uid: 'contratante-1',
    nome: 'Ana Contratante',
    perfil: Perfil.contratante,
  );
  final prestador = criarContaTeste(
    uid: 'prestador-1',
    nome: 'Bruno Prestador',
    perfil: Perfil.prestador,
  );
  final concluido =
      criarPedidoTeste(
        id: 'pedido-1',
        contratanteUid: contratante.uid,
      ).copyWith(
        estado: EstadoPedido.concluido,
        prestadorEscolhidoUid: prestador.uid,
      );

  late FakeAvaliacaoRepository repository;
  late AvaliacaoService service;

  setUp(() {
    repository = FakeAvaliacaoRepository();
    service = AvaliacaoService(repository);
  });

  test('contratante avalia o prestador escolhido', () async {
    await service.avaliar(
      pedido: concluido,
      avaliador: contratante,
      nota: 5,
      comentario: '  Ótimo trabalho  ',
    );

    final avaliacao = repository.avaliacoes.single;
    expect(avaliacao.pedidoId, 'pedido-1');
    expect(avaliacao.avaliadorUid, contratante.uid);
    expect(avaliacao.avaliadoUid, prestador.uid);
    expect(avaliacao.nota, 5);
    expect(avaliacao.comentario, 'Ótimo trabalho');
  });

  test('prestador avalia o contratante', () async {
    await service.avaliar(
      pedido: concluido,
      avaliador: prestador,
      nota: 4,
      comentario: '',
    );

    expect(repository.avaliacoes.single.avaliadoUid, contratante.uid);
  });

  test('avaliadorNome é o nome no momento da avaliação', () async {
    await service.avaliar(
      pedido: concluido,
      avaliador: prestador,
      nota: 4,
      comentario: '',
    );

    expect(repository.avaliacoes.single.avaliadorNome, 'Bruno Prestador');
  });

  test('recusa pedido não concluído', () async {
    for (final estado in [
      EstadoPedido.aberto,
      EstadoPedido.emAndamento,
      EstadoPedido.cancelado,
    ]) {
      await expectLater(
        service.avaliar(
          pedido: concluido.copyWith(estado: estado),
          avaliador: contratante,
          nota: 5,
          comentario: '',
        ),
        throwsA(isA<AvaliacaoPermissaoErro>()),
        reason: estado.name,
      );
    }
    expect(repository.avaliacoes, isEmpty);
  });

  test('recusa quem não é parte do pedido', () async {
    await expectLater(
      service.avaliar(
        pedido: concluido,
        avaliador: criarContaTeste(uid: 'outra-pessoa'),
        nota: 5,
        comentario: '',
      ),
      throwsA(isA<AvaliacaoPermissaoErro>()),
    );
    expect(repository.avaliacoes, isEmpty);
  });

  test('recusa segunda avaliação da mesma parte', () async {
    await service.avaliar(
      pedido: concluido,
      avaliador: contratante,
      nota: 5,
      comentario: '',
    );

    await expectLater(
      service.avaliar(
        pedido: concluido,
        avaliador: contratante,
        nota: 1,
        comentario: '',
      ),
      throwsA(isA<AvaliacaoPermissaoErro>()),
    );
    expect(repository.avaliacoes.single.nota, 5);
  });

  test('a outra parte ainda pode avaliar depois da primeira', () async {
    await service.avaliar(
      pedido: concluido,
      avaliador: contratante,
      nota: 5,
      comentario: '',
    );
    await service.avaliar(
      pedido: concluido,
      avaliador: prestador,
      nota: 4,
      comentario: '',
    );

    expect(repository.avaliacoes, hasLength(2));
  });

  test('nota inválida não é registrada', () async {
    await expectLater(
      service.avaliar(
        pedido: concluido,
        avaliador: contratante,
        nota: null,
        comentario: '',
      ),
      throwsA(
        isA<AvaliacaoValidacaoErro>().having(
          (erro) => erro.campos['nota'],
          'nota',
          'Escolha uma nota de 1 a 5.',
        ),
      ),
    );
    expect(repository.avaliacoes, isEmpty);
  });
}
