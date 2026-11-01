import 'package:bicolocal/features/conta/domain/conta.dart';
import 'package:bicolocal/features/conta/domain/conta_erro.dart';
import 'package:bicolocal/features/conta/domain/conta_repository.dart';
import 'package:bicolocal/features/conta/domain/conta_service.dart';
import 'package:bicolocal/features/conta/domain/perfil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContaService', () {
    test('cadastra conta e mantém o perfil escolhido', () async {
      final repositorio = _RepositorioContaFalso();
      final service = ContaService(repositorio);

      final conta = await service.cadastrar(
        email: 'ana@example.com',
        senha: 'senha-segura',
        nome: 'Ana Silva',
        cidade: 'São Paulo',
        bairro: 'Centro',
        perfil: Perfil.prestador,
      );

      expect(conta.perfil, Perfil.prestador);
      expect(conta.nome, 'Ana Silva');
      expect(repositorio.emailUsado, 'ana@example.com');
    });

    test(
      'converte e-mail já usado em orientação para entrar ou usar outro',
      () async {
        final service = ContaService(
          _RepositorioContaFalso(emailDuplicado: true),
        );

        await expectLater(
          service.cadastrar(
            email: 'ana@example.com',
            senha: 'senha-segura',
            nome: 'Ana Silva',
            cidade: 'São Paulo',
            bairro: 'Centro',
            perfil: Perfil.contratante,
          ),
          throwsA(
            isA<ContaErro>().having(
              (erro) => erro.mensagem,
              'mensagem',
              contains('Entre'),
            ),
          ),
        );
      },
    );

    test('entra na conta existente com credenciais válidas', () async {
      final repositorio = _RepositorioContaFalso();
      final service = ContaService(repositorio);

      final conta = await service.entrar(
        email: 'ana@example.com',
        senha: 'senha-segura',
      );

      expect(conta.uid, 'conta-1');
      expect(repositorio.senhaUsada, 'senha-segura');
    });

    test('altera o perfil ativo sem mudar a identidade da conta', () async {
      final repositorio = _RepositorioContaFalso();
      final dynamic service = ContaService(repositorio);
      const conta = Conta(
        uid: 'conta-1',
        email: 'ana@example.com',
        nome: 'Ana Silva',
        cidade: 'São Paulo',
        bairro: 'Centro',
        perfil: Perfil.contratante,
      );

      final Conta atualizada = await service.alterarPerfil(
        conta: conta,
        perfil: Perfil.prestador,
      );

      expect(atualizada.perfil, Perfil.prestador);
      expect(atualizada.uid, conta.uid);
      expect(atualizada.email, conta.email);
      expect(atualizada.nome, conta.nome);
      expect(repositorio.uidPerfilAlterado, conta.uid);
    });
  });
}

class _RepositorioContaFalso implements ContaRepository {
  _RepositorioContaFalso({this.emailDuplicado = false});

  final bool emailDuplicado;
  String? emailUsado;
  String? senhaUsada;
  String? uidPerfilAlterado;

  @override
  Stream<Conta?> observarSessao() => const Stream.empty();

  @override
  Future<Conta> cadastrar({
    required String email,
    required String senha,
    required String nome,
    required String cidade,
    required String bairro,
    required Perfil perfil,
  }) async {
    emailUsado = email;
    if (emailDuplicado) throw ContaErro.emailEmUso();
    return Conta(
      uid: 'conta-1',
      email: email,
      nome: nome,
      cidade: cidade,
      bairro: bairro,
      perfil: perfil,
    );
  }

  @override
  Future<Conta> entrar({required String email, required String senha}) async {
    emailUsado = email;
    senhaUsada = senha;
    return const Conta(
      uid: 'conta-1',
      email: 'ana@example.com',
      nome: 'Ana Silva',
      cidade: 'São Paulo',
      bairro: 'Centro',
      perfil: Perfil.contratante,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #alterarPerfil) {
      final argumentos = invocation.namedArguments;
      final uid = argumentos[#uid] as String;
      final perfil = argumentos[#perfil] as Perfil;
      uidPerfilAlterado = uid;
      return Future<Conta>.value(
        Conta(
          uid: uid,
          email: 'ana@example.com',
          nome: 'Ana Silva',
          cidade: 'São Paulo',
          bairro: 'Centro',
          perfil: perfil,
        ),
      );
    }
    return super.noSuchMethod(invocation);
  }
}
