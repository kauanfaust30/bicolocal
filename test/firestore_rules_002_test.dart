import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Verificação estática de `firestore.rules` para a 002 (perfil com foto e
/// avaliações). Não executa as regras (isso exigiria o emulador); confere o
/// texto contra `specs/002-perfil-e-avaliacoes/contracts/firestore-security.md`.
void main() {
  final regras = File('firestore.rules').readAsStringSync();

  /// Texto do bloco `match <caminho> { ... }`, a partir de [desde].
  String bloco(String caminho, {int desde = 0}) {
    final inicio = regras.indexOf('match $caminho', desde);
    expect(inicio, isNot(-1), reason: 'bloco $caminho não encontrado');
    var nivel = 0;
    // ' {' abre o bloco; o '{' sem espaço é o curinga do caminho ({uid}).
    for (var i = regras.indexOf(' {', inicio) + 1; i < regras.length; i++) {
      if (regras[i] == '{') nivel++;
      if (regras[i] == '}' && --nivel == 0) {
        return regras.substring(inicio, i + 1);
      }
    }
    fail('bloco $caminho sem fechamento');
  }

  String regra(String texto, String operacao) {
    final inicio = texto.indexOf('allow $operacao');
    expect(inicio, isNot(-1), reason: 'allow $operacao não encontrado');
    final fim = texto.indexOf(';', inicio);
    return texto.substring(inicio, fim + 1);
  }

  group('users/{uid}/private/foto', () {
    late String foto;
    setUp(() {
      foto = bloco(
        '/private/foto',
        desde: regras.indexOf('match /users/{uid}'),
      );
    });

    test('só o dono lê e grava', () {
      expect(regra(foto, 'get'), contains('request.auth.uid == uid'));
      expect(
        regra(foto, 'create, update'),
        contains('request.auth.uid == uid'),
      );
    });

    test('limita a foto a 1 a 204 800 bytes', () {
      expect(foto, contains('fotoValida('));
      expect(regras, contains('data.imagem.size() <= 204800'));
      expect(regras, contains('data.imagem.size() > 0'));
    });

    test('não pode ser apagada', () {
      expect(foto, contains('allow delete: if false;'));
    });
  });

  group('requests/{id}/applications/{providerUid}/private/foto', () {
    late String foto;
    setUp(() {
      foto = bloco(
        '/private/foto',
        desde: regras.indexOf('match /applications/{providerUid}'),
      );
    });

    test('contratante só lê a foto do prestador escolhido', () {
      final leitura = regra(foto, 'get');
      expect(leitura, contains('request.auth.uid == providerUid'));
      expect(leitura, contains('prestadorEscolhidoUid == providerUid'));
      expect(leitura, contains('aceito('));
    });

    test(
      'cópia gravada pelo dono, igual à foto privada, com candidatura pendente',
      () {
        final criacao = regra(foto, 'create');
        expect(criacao, contains('request.auth.uid == providerUid'));
        expect(
          criacao,
          contains('get(privateFotoPath(providerUid)).data.imagem'),
        );
        expect(criacao, contains("'pendente'"));
      },
    );

    test('cópia nunca é alterada nem apagada', () {
      expect(foto, contains('allow update, delete: if false;'));
      expect(foto, contains('allow list: if false;'));
    });
  });

  group('requests/{id}/fotos/{contratanteUid}', () {
    late String foto;
    setUp(() => foto = bloco('/fotos/{contratanteUid}'));

    test('só as partes leem, com o pedido aceito', () {
      final leitura = regra(foto, 'get');
      expect(leitura, contains('aceito('));
      expect(leitura, contains('ehParte('));
    });

    test('cópia gravada pelo contratante no aceite, igual à foto privada', () {
      final criacao = regra(foto, 'create');
      expect(criacao, contains('isContractor(contratanteUid)'));
      expect(
        criacao,
        contains('get(privateFotoPath(contratanteUid)).data.imagem'),
      );
      expect(criacao, contains("'em_andamento'"));
    });

    test('cópia nunca é alterada nem apagada', () {
      expect(foto, contains('allow update, delete: if false;'));
      expect(foto, contains('allow list: if false;'));
    });
  });

  test(
    'pedido cancelado não libera fotos: aceito() só em andamento ou concluído',
    () {
      final funcao = regras.substring(regras.indexOf('function aceito('));
      expect(
        funcao.substring(0, funcao.indexOf('}')),
        contains("['em_andamento', 'concluido']"),
      );
    },
  );

  group('profiles/{uid}', () {
    test('criado pelo dono com reputação zerada e dados de users/{uid}', () {
      final criacao = regra(bloco('/profiles/{uid}'), 'create');
      expect(criacao, contains('request.auth.uid == uid'));
      expect(criacao, contains('totalAvaliacoes == 0'));
      expect(criacao, contains('somaNotas == 0'));
      expect(criacao, contains('ultimaAvaliacaoId == null'));
      expect(criacao, contains('getAfter('));
    });
  });

  group('concluir pedido (FR-001, FR-002)', () {
    late String atualizacao;
    setUp(() => atualizacao = regra(bloco('/requests/{requestId}'), 'update'));

    test('ramo "concluir" exige contratante e pedido em andamento', () {
      final inicio = atualizacao.indexOf(
        "request.resource.data.estado == 'concluido'",
      );
      expect(inicio, isNot(-1), reason: 'ramo concluir não encontrado');
      final ramo = atualizacao.substring(
        atualizacao.lastIndexOf('||', inicio),
        atualizacao.indexOf(')', inicio),
      );
      expect(ramo, contains('isContractor(resource.data.contratanteUid)'));
      expect(ramo, contains("resource.data.estado == 'em_andamento'"));
      expect(
        atualizacao,
        contains("affectedKeys().hasOnly(['estado', 'atualizadoEm'])"),
      );
    });

    test(
      'prestador escolhido lê o pedido concluído (get e list separados)',
      () {
        final pedidos = bloco('/requests/{requestId}');
        for (final operacao in ['get', 'list']) {
          final texto = regra(pedidos, operacao);
          expect(texto, contains('aceito(resource.data)'), reason: operacao);
          expect(texto, isNot(contains('allow get, list')));
        }
      },
    );
  });

  group('profiles/{uid}/avaliacoes/{requestId}', () {
    late String avaliacoes;
    late String criacao;
    setUp(() {
      avaliacoes = bloco('/avaliacoes/{requestId}');
      criacao = regra(avaliacoes, 'create');
    });

    String funcaoPartes() {
      final inicio = regras.indexOf('function avaliaOutraParte(');
      expect(inicio, isNot(-1));
      return regras.substring(inicio, regras.indexOf('}', inicio));
    }

    test('create usa o pedido e o avaliado do caminho', () {
      expect(
        criacao,
        contains('avaliaOutraParte(get(requestPath(requestId)).data, uid)'),
      );
    });

    test('só em pedido concluído', () {
      expect(funcaoPartes(), contains("r.estado == 'concluido'"));
    });

    test('partes cruzadas: cada uma avalia a outra', () {
      final partes = funcaoPartes();
      expect(partes, contains('request.auth.uid == r.contratanteUid'));
      expect(partes, contains('avaliadoUid == r.prestadorEscolhidoUid'));
      expect(partes, contains('request.auth.uid == r.prestadorEscolhidoUid'));
      expect(partes, contains('avaliadoUid == r.contratanteUid'));
    });

    test('campos, autor, nota de 1 a 5 e teto do comentário', () {
      expect(criacao, contains('avaliadorUid == request.auth.uid'));
      expect(criacao, contains('get(profilePath(request.auth.uid)).data.nome'));
      expect(criacao, contains('nota is int'));
      expect(criacao, contains('nota >= 1'));
      expect(criacao, contains('nota <= 5'));
      expect(criacao, contains('comentario.size() <= 1200'));
      expect(criacao, contains('criadaEm == request.time'));
    });

    test('reputação muda na mesma operação (getAfter do perfil)', () {
      expect(
        criacao,
        contains('getAfter(profilePath(uid)).data.ultimaAvaliacaoId'),
      );
      expect(
        criacao,
        contains('getAfter(profilePath(uid)).data.totalAvaliacoes'),
      );
    });

    test('avaliação nunca é alterada nem apagada (FR-006)', () {
      expect(avaliacoes, contains('allow update, delete: if false;'));
    });
  });

  group('integridade da reputação (FR-027)', () {
    late String perfis;
    setUp(() => perfis = bloco('/profiles/{uid}'));

    test('profiles não tem allow list', () {
      final semAvaliacoes = perfis.replaceAll(
        bloco('/avaliacoes/{requestId}'),
        '',
      );
      expect(semAvaliacoes, contains('allow list: if false;'));
    });

    test('update só no ramo de avaliação, com avaliação nova', () {
      final atualizacao = regra(perfis, 'update');
      expect(
        atualizacao,
        contains(
          "affectedKeys().hasOnly([\n"
          "          'totalAvaliacoes', 'somaNotas', 'notaMedia', "
          "'ultimaAvaliacaoId'\n"
          "        ])",
        ),
      );
      expect(atualizacao, contains('!exists('));
      expect(atualizacao, contains('existsAfter('));
      expect(atualizacao, contains('avaliadorUid == request.auth.uid'));
      expect(
        atualizacao,
        contains(
          'request.resource.data.totalAvaliacoes == '
          'resource.data.totalAvaliacoes + 1',
        ),
      );
      expect(atualizacao, contains('math.abs('));
    });

    test('nenhum outro bloco grava os campos de reputação', () {
      final fora = regras.replaceAll(perfis, '');
      for (final campo in ['totalAvaliacoes', 'somaNotas', 'notaMedia']) {
        expect(fora, isNot(contains(campo)), reason: campo);
      }
    });
  });
}
