import 'package:bicolocal/features/candidaturas/domain/candidatura.dart';
import 'package:bicolocal/features/candidaturas/domain/candidatura_repository.dart';
import 'package:bicolocal/features/candidaturas/domain/candidatura_service.dart';
import 'package:bicolocal/features/conta/domain/conta.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:bicolocal/features/pedidos/domain/pedido.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CandidaturaService', () {
    test(
      'prestador pode candidatar-se uma vez a pedido aberto e vigente',
      () async {
        final repository = _CandidaturaRepositoryFalso();
        final service = CandidaturaService(repository);
        final agora = DateTime.utc(2026, 10, 27, 12);

        await service.candidatar(
          pedido: _pedido(),
          prestador: _prestador,
          agoraUtc: agora,
        );

        expect(repository.candidaturas, hasLength(1));
        expect(repository.candidaturas.single.prestadorUid, _prestador.uid);
        expect(
          repository.candidaturas.single.estado,
          EstadoCandidatura.pendente,
        );
      },
    );

    test('recusa perfil contratante, pedido expirado e duplicidade', () async {
      final repository = _CandidaturaRepositoryFalso();
      final service = CandidaturaService(repository);
      final agora = DateTime.utc(2026, 10, 27, 12);

      await expectLater(
        service.candidatar(
          pedido: _pedido(),
          prestador: _contratante,
          agoraUtc: agora,
        ),
        throwsA(isA<CandidaturaPermissaoErro>()),
      );
      await expectLater(
        service.candidatar(
          pedido: _pedido(validadeAte: DateTime.utc(2026, 10, 26)),
          prestador: _prestador,
          agoraUtc: agora,
        ),
        throwsA(isA<CandidaturaPermissaoErro>()),
      );

      await service.candidatar(
        pedido: _pedido(),
        prestador: _prestador,
        agoraUtc: agora,
      );
      await expectLater(
        service.candidatar(
          pedido: _pedido(),
          prestador: _prestador,
          agoraUtc: agora,
        ),
        throwsA(isA<CandidaturaDuplicadaErro>()),
      );
    });

    test(
      'somente o contratante autor aceita candidatura pendente uma vez',
      () async {
        final repository = _CandidaturaRepositoryFalso();
        final service = CandidaturaService(repository);
        final pedido = _pedido();
        final candidatura = Candidatura(
          pedidoId: pedido.id,
          prestadorUid: _prestador.uid,
          estado: EstadoCandidatura.pendente,
        );
        repository.candidaturas.add(candidatura);
        repository.candidaturas.add(
          const Candidatura(
            pedidoId: 'pedido-1',
            prestadorUid: 'prestador-2',
            estado: EstadoCandidatura.pendente,
          ),
        );

        await expectLater(
          service.aceitar(
            pedido: pedido,
            candidatura: candidatura,
            contratante: const Conta(
              uid: 'intruso',
              email: 'intruso@example.com',
              nome: 'Intruso',
              cidade: 'São Paulo',
              bairro: 'Centro',
              perfil: Perfil.contratante,
            ),
            agoraUtc: DateTime.utc(2026, 10, 27, 12),
          ),
          throwsA(isA<CandidaturaPermissaoErro>()),
        );
        await service.aceitar(
          pedido: pedido,
          candidatura: candidatura,
          contratante: _contratante,
          agoraUtc: DateTime.utc(2026, 10, 27, 12),
        );
        expect(repository.pedidoAceito, pedido.id);
        expect(repository.prestadorAceito, _prestador.uid);
        expect(
          repository.candidaturas
              .where((item) => item.estado == EstadoCandidatura.aceita)
              .map((item) => item.prestadorUid),
          [_prestador.uid],
        );
        expect(
          repository.candidaturas
              .where((item) => item.estado == EstadoCandidatura.recusada)
              .map((item) => item.prestadorUid),
          ['prestador-2'],
        );
      },
    );
  });
}

class _CandidaturaRepositoryFalso implements CandidaturaRepository {
  final List<Candidatura> candidaturas = [];
  String? pedidoAceito;
  String? prestadorAceito;

  @override
  Future<Candidatura?> buscar({
    required String pedidoId,
    required String prestadorUid,
  }) async {
    for (final candidatura in candidaturas) {
      if (candidatura.pedidoId == pedidoId &&
          candidatura.prestadorUid == prestadorUid) {
        return candidatura;
      }
    }
    return null;
  }

  @override
  Future<List<Candidatura>> listar({required String pedidoId}) async =>
      candidaturas.where((c) => c.pedidoId == pedidoId).toList();

  @override
  Future<void> candidatar(
    Candidatura candidatura, {
    required String emailPrestador,
  }) async {
    candidaturas.add(candidatura);
  }

  @override
  Future<void> aceitar({
    required String pedidoId,
    required String prestadorUid,
    required String emailContratante,
    required DateTime agoraUtc,
  }) async {
    pedidoAceito = pedidoId;
    prestadorAceito = prestadorUid;
    for (var index = 0; index < candidaturas.length; index++) {
      candidaturas[index] = candidaturas[index].copyWith(
        estado: candidaturas[index].prestadorUid == prestadorUid
            ? EstadoCandidatura.aceita
            : EstadoCandidatura.recusada,
      );
    }
  }

  @override
  Future<String?> carregarEmailPrestador({
    required String pedidoId,
    required String prestadorUid,
  }) async => null;

  @override
  Future<String?> carregarEmailContratante({
    required String pedidoId,
    required String contratanteUid,
  }) async => null;
}

const _contratante = Conta(
  uid: 'contratante-1',
  email: 'ana@example.com',
  nome: 'Ana',
  cidade: 'São Paulo',
  bairro: 'Centro',
  perfil: Perfil.contratante,
);
const _prestador = Conta(
  uid: 'prestador-1',
  email: 'joao@example.com',
  nome: 'João',
  cidade: 'São Paulo',
  bairro: 'Centro',
  perfil: Perfil.prestador,
);

Pedido _pedido({DateTime? validadeAte}) => Pedido(
  id: 'pedido-1',
  contratanteUid: _contratante.uid,
  titulo: 'Montagem',
  categoriaId: 'reparos',
  categoriaNome: 'Reparos',
  descricao: 'Montar estante',
  cidade: 'São Paulo',
  local: 'Centro',
  dataDesejada: DateTime.utc(2026, 10, 30),
  validadeAte: validadeAte ?? DateTime.utc(2026, 10, 28),
  valorCentavos: 12000,
);
