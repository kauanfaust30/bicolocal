# Implementation Plan: Perfil com foto e avaliações

**Branch**: `002-perfil-e-avaliacoes` | **Date**: 2026-11-12 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-perfil-e-avaliacoes/spec.md`

## Summary

Cada pessoa ganha um perfil público (`profiles/{uid}`) com nome, cidade, tipo de perfil e
reputação (nota média, total e soma das notas), e uma foto privada (`users/{uid}/private/foto`).
O contratante passa a marcar pedidos em andamento como concluídos. Depois disso, cada parte avalia
a outra uma única vez, em `profiles/{avaliadoUid}/avaliacoes/{requestId}`, numa escrita atômica
que atualiza a reputação do avaliado. As regras do Firestore garantem sozinhas, sem Cloud
Functions, quem pode avaliar, a validade da nota e a coerência da reputação. A foto é reduzida no
aparelho para cerca de 300 px e só é revelada entre contratante e prestador escolhido, por cópias
feitas pelo próprio dono: o prestador grava a sua em
`requests/{requestId}/applications/{providerUid}/private/foto` ao se candidatar, liberada ao
contratante só depois do aceite; o contratante grava a sua em `requests/{requestId}/fotos/{uid}` no
aceite (ver [research.md](research.md), D4). Contas antigas sem foto são levadas à tela Adicionar
foto na primeira entrada.

## Technical Context

**Language/Version**: Dart 3.13 (null safety), Flutter estável

**Primary Dependencies**: Provider, go_router, firebase_core, firebase_auth, cloud_firestore (já
existentes); **nova**: `image_picker` (ver Dependências novas)

**Storage**: Cloud Firestore. Sem Firebase Storage e sem Cloud Functions.

**Testing**: `flutter test` com repositórios falsos e seletor de foto falso; testes estáticos de
`firestore.rules` e `firestore.indexes.json` (padrão da 001)

**Target Platform**: Android e iOS (celular); web para desenvolvimento (`flutter run -d chrome`)

**Project Type**: mobile-app

**Performance Goals**: perfil e avaliações recentes visíveis em até 2 s em conexão móvel comum;
foto final ≤ 200 KB (tipicamente 20–60 KB)

**Constraints**: nenhum dado privado (bairro, e-mail, foto) em documento legível por terceiros;
toda regra de negócio de avaliação e reputação imposta também em `firestore.rules`; documento do
Firestore ≤ 1 MiB

**Scale/Scope**: 5 telas novas (Meu perfil, Perfil de outra pessoa, Avaliar, Concluir pedido,
Adicionar foto), 2 coleções novas (`profiles`, `avaliacoes`) e 2 subcoleções privadas de foto

## Precedência sobre a 001

A 002 tem precedência sobre a `specs/001-cadastro-e-pedidos/spec.md` nos três pontos que altera:

| Ponto | 001 | 002 (prevalece) |
|---|---|---|
| Estado concluído | FR-008: conclusão e avaliação fora do escopo | Pedido em andamento pode ir a `concluido`, só pelo contratante; imutável depois |
| Dados visíveis a outras pessoas | FR-023: nome invisível a outros usuários | Nome, cidade, tipo e reputação legíveis por qualquer pessoa autenticada (FR-015 da 002); bairro e e-mail continuam privados; foto só entre as partes após o aceite |
| Cadastro | FR-001/FR-004: e-mail, senha, nome, cidade, bairro e perfil | Foto também obrigatória |

Os demais requisitos da 001 continuam valendo. A spec da 001 não é editada; esta tabela é a
referência em caso de conflito.

## Dependências novas

| Pacote | Finalidade | Por que não uma alternativa já disponível |
|---|---|---|
| `image_picker` | Tirar foto com a câmera ou escolher da galeria (FR-016), já reduzida e comprimida no aparelho via `maxWidth`, `maxHeight` e `imageQuality` | Flutter e Dart não acessam câmera nem galeria sem plugin nativo. O próprio `image_picker` redimensiona e comprime, por isso **nenhum pacote de redução de imagem é necessário** (research D3) |

A versão será fixada no `pubspec.yaml`, como as demais, no momento da instalação, que exige
confirmação do usuário (AGENTS.md). iOS exige `NSCameraUsageDescription` e
`NSPhotoLibraryUsageDescription` no `Info.plist`, em português.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Situação | Como o plano atende |
|---|---|---|
| I. Simplicidade e legibilidade | ✅ | Duas funcionalidades novas por pasta (`perfil`, `avaliacoes`) com `data`/`domain`/`presentation`; conclusão fica em `pedidos` |
| II. Teste primeiro | ✅ | Cada tarefa começa com teste usando `FakePerfilRepository`, `FakeAvaliacaoRepository`, `FakeSeletorFoto` e os fakes atuais; testes estáticos das regras antes de editá-las |
| III. Dependências justificadas | ✅ | Só `image_picker`, justificado acima; pacote de redução descartado |
| IV. Comunicação clara em português | ✅ | Mensagens de erro de foto, permissão e avaliação definidas em [contracts/telas-e-rotas.md](contracts/telas-e-rotas.md); datas dd/MM/aaaa |
| V. Privacidade e contato protegido | ✅ | `profiles` não contém foto, bairro nem e-mail; foto privada do dono; cópia só para as partes após o aceite; contatos da 001 inalterados |
| Restrições (repositórios, estados de lista) | ✅ | Nenhum widget acessa o Firestore; avaliações recentes e candidaturas com estados de carregando, vazio e erro |
| Fluxo (spec manda, `flutter test` e `flutter analyze`) | ✅ | Escopo limitado à spec 002; precedência sobre a 001 registrada acima |

**Re-check pós-design**: sem violações. A foto do prestador é copiada na candidatura e só lida
pelo contratante depois do aceite (research D4); candidatos recusados nunca têm a foto lida.
A troca de foto vale para candidaturas enviadas depois dela (cenário 5 da História 1 e FR-019),
coerente com a cópia feita na candidatura; a pendência de D4 está resolvida.

## Project Structure

### Documentation (this feature)

```text
specs/002-perfil-e-avaliacoes/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── firestore-security.md
│   └── telas-e-rotas.md
├── checklists/requirements.md
└── tasks.md             # gerado por $speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── router.dart                       # rotas novas + redirect para /foto
│   └── widgets/avatar_pessoa.dart        # foto ou inicial do nome, com rótulo acessível
├── features/
│   ├── conta/                            # cadastro com foto; Conta.temFoto
│   │   ├── data/firebase_conta_repository.dart
│   │   ├── domain/conta.dart
│   │   └── presentation/cadastro_page.dart
│   ├── perfil/                           # NOVO
│   │   ├── data/firestore_perfil_repository.dart
│   │   ├── data/image_picker_seletor_foto.dart
│   │   ├── domain/perfil_publico.dart
│   │   ├── domain/perfil_repository.dart
│   │   ├── domain/seletor_foto.dart
│   │   ├── domain/foto_erro.dart
│   │   └── presentation/
│   │       ├── perfil_controller.dart
│   │       ├── meu_perfil_page.dart
│   │       ├── perfil_pessoa_page.dart
│   │       ├── adicionar_foto_page.dart
│   │       └── escolher_foto.dart        # câmera/galeria + prévia (cadastro, adicionar, trocar)
│   ├── avaliacoes/                       # NOVO
│   │   ├── data/firestore_avaliacao_repository.dart
│   │   ├── domain/avaliacao.dart
│   │   ├── domain/avaliacao_repository.dart
│   │   ├── domain/avaliacao_validator.dart
│   │   └── presentation/
│   │       ├── avaliacao_controller.dart
│   │       └── avaliar_page.dart
│   ├── pedidos/                          # estado concluido
│   │   ├── domain/pedido.dart, pedido_permissions.dart
│   │   ├── data/pedido_dto.dart, firestore_pedido_repository.dart
│   │   └── presentation/concluir_pedido_page.dart
│   └── candidaturas/                     # candidatura copia a foto do prestador;
│       └── data/firestore_candidatura_repository.dart   # aceite copia a do contratante
test/
├── support/fakes/                        # FakePerfilRepository, FakeAvaliacaoRepository, FakeSeletorFoto
├── features/perfil/…
├── features/avaliacoes/…
├── features/pedidos/…                    # concluir
└── firestore_rules_002_test.dart         # verificação estática das regras novas
firestore.rules
```

**Structure Decision**: Projeto Flutter único, organizado por funcionalidade como na 001.
`perfil` concentra perfil público, foto e telas de perfil; `avaliacoes` concentra o registro e a
listagem de avaliações. A conclusão do pedido é uma transição de estado de `pedidos`.

## Fases de implementação (resumo para `$speckit-tasks`)

1. **Base**: `image_picker` (após confirmação), `SeletorFoto` e fake, `AvatarPessoa`, entidades
   e fakes de perfil e avaliação.
2. **História 1 – Foto (P1)**:
   - cadastro com foto em escrita atômica;
   - Adicionar foto e redirect para contas antigas (cria também `profiles/{uid}` se faltar);
   - trocar foto em Meu perfil;
   - candidatura grava a cópia da foto do prestador em `applications/{uid}/private/foto`, na mesma
     transação da candidatura e do contato;
   - aceite grava a cópia da foto do contratante em `fotos/{contratanteUid}`, na transação atual;
   - leitura das cópias (contratante: só a do escolhido; prestador escolhido: a do contratante);
   - regras de foto privada e das duas cópias, com testes estáticos antes.
3. **História 2 – Concluir e avaliar (P2)**: estado `concluido`; tela Concluir pedido; tela
   Avaliar com transação avaliação + reputação; "Você já avaliou"; regras.
4. **História 3 – Perfil (P3)**: Meu perfil, Perfil de outra pessoa (a partir das candidaturas e
   do pedido), avaliações recentes com estados; regras de leitura.
5. **Fechamento**: deploy de regras (com confirmação), quickstart manual, `flutter analyze` e
   `flutter test`. Registrar que o processo de retenção de pedidos encerrados da 001, que ainda não
   tem mecanismo implementado, deve apagar também as subcoleções de cópias de foto (FR-028).

## Complexity Tracking

Sem violações da constituição.
