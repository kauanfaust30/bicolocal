---

description: "Lista de tarefas da 002 – perfil com foto e avaliações"
---

# Tasks: Perfil com foto e avaliações

**Input**: Documentos de `specs/002-perfil-e-avaliacoes/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Pedidos explicitamente (constituição §II e pedido do usuário): em cada fase, os testes
vêm antes da implementação, devem ser executados com `flutter test` e falhar antes do código.
Testes usam repositórios falsos e nunca acessam o Firebase real.

**Organization**: Por história: US1 Foto (P1), US2 Concluir e avaliar (P2), US3 Perfil (P3).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: pode rodar em paralelo (arquivos diferentes, sem dependência de tarefa incompleta)
- **[Story]**: US1, US2 ou US3
- Caminhos relativos à raiz do repositório

---

## Phase 1: Setup

**Purpose**: Dependência nova e estrutura de pastas

- [X] T001 Pedir confirmação ao usuário e então adicionar `image_picker` com versão fixa e declarar `characters: 1.4.1` (versão já resolvida no `pubspec.lock`) em `pubspec.yaml`, e rodar `flutter pub get` (justificativa em plan.md §Dependências novas)
- [X] T002 [P] Adicionar `NSCameraUsageDescription` e `NSPhotoLibraryUsageDescription` em português em `ios/Runner/Info.plist`
- [X] T003 [P] Criar as pastas `lib/features/perfil/{data,domain,presentation}`, `lib/features/avaliacoes/{data,domain,presentation}`, `test/features/perfil/` e `test/features/avaliacoes/`

---

## Phase 2: Foundational

**Purpose**: Entidades, contratos de repositório, fakes e o avatar usados pelas três histórias

**⚠️ CRITICAL**: Nenhuma história começa antes desta fase

### Testes (escrever primeiro e ver falhar)

- [X] T004 [P] Teste de `PerfilPublico` em `test/features/perfil/domain/perfil_publico_test.dart`: `semAvaliacoes` quando `totalAvaliacoes == 0`; média exibida calculada de `somaNotas` e `totalAvaliacoes` com inteiros, "arredondada para uma casa decimal meio para cima" e com vírgula (93/20 → "4,7"; 9/2 → "4,5"; 14/3 → "4,7"; 5/1 → "5,0")
- [X] T005 [P] Teste de `AvatarPessoa` em `test/core/widgets/avatar_pessoa_test.dart`: com bytes mostra a foto com rótulo "Foto de {nome}"; sem bytes mostra a inicial do nome com rótulo "Inicial de {nome}"; tamanho mínimo de 48 dp
- [X] T006 [P] Ampliar `test/features/pedidos/domain/pedido_permissions_test.dart`: `EstadoPedido.concluido` existe; `podeVerFotoDaParte` é verdadeiro só para contratante e prestador escolhido com pedido em andamento ou concluído e falso em pedido cancelado (FR-020)

### Implementação

- [X] T007 [P] Criar `PerfilPublico(uid, nome, cidade, perfil, somaNotas, totalAvaliacoes)` com `semAvaliacoes` e `notaExibida` em `lib/features/perfil/domain/perfil_publico.dart`
- [X] T008 [P] Criar `FotoPerfil(bytes)`, `OrigemFoto { camera, galeria }` e `FotoErro` (`semPermissao(origem)`, `naoImagem`, `grandeDemais`, `envioFalhou`) com mensagens de `contracts/telas-e-rotas.md` em `lib/features/perfil/domain/foto_perfil.dart` e `lib/features/perfil/domain/foto_erro.dart`
- [X] T009 [P] Criar interface `SeletorFoto` (`Future<FotoPerfil?> escolher(OrigemFoto origem)`, `null` quando a pessoa cancela) em `lib/features/perfil/domain/seletor_foto.dart`
- [X] T010 Criar interface `PerfilRepository` (`carregarPerfil(uid)`, `carregarFotoPropria()`, `salvarFotoPropria(FotoPerfil)`) em `lib/features/perfil/domain/perfil_repository.dart`; criar também a interface `AvaliacaoRepository` (`avaliar`, `jaAvaliou`, `listarRecentes`) em `lib/features/avaliacoes/domain/avaliacao_repository.dart` e `FakeAvaliacaoRepository`
- [X] T011 [P] Criar `AvatarPessoa(nome, bytes?)` em `lib/core/widgets/avatar_pessoa.dart`
- [X] T012 Adicionar `EstadoPedido.concluido` em `lib/features/pedidos/domain/pedido.dart`, o mapeamento `'concluido'` em `lib/features/pedidos/data/pedido_dto.dart`, o selo "Concluído" em `lib/features/pedidos/presentation/pedido_card.dart` e `PedidoPermissions.podeVerFotoDaParte` em `lib/features/pedidos/domain/pedido_permissions.dart`
- [X] T013 Criar `FakeSeletorFoto` (devolve foto, `null` ou lança `FotoErro`) e `FakePerfilRepository` em `test/support/fakes/fake_repositories.dart`, e `criarPerfilTeste`/`criarFotoTeste` em `test/support/builders/test_data.dart`
- [X] T014 Receber `PerfilRepository`, `AvaliacaoRepository` e `SeletorFoto` em `BicoLocalApp` (`lib/core/app.dart`) e em `lib/main.dart`, e atualizar de uma vez todas as construções de `BicoLocalApp` nos testes existentes com os fakes

**Checkpoint**: `flutter test` e `flutter analyze` passam; histórias podem começar

---

## Phase 3: User Story 1 – Foto de perfil obrigatória (Priority: P1) 🎯 MVP

**Goal**: Foto obrigatória no cadastro, Adicionar foto para contas antigas, troca de foto e foto
revelada só entre contratante e prestador escolhido depois do aceite.

**Independent Test**: Cadastrar com foto; ver a própria foto em Meu perfil; candidatar-se e
aceitar; contratante vê a foto do escolhido, a dos não escolhidos nunca; simular falha de envio e ver o
cadastro não terminar.

### Testes (escrever primeiro e ver falhar)

- [X] T015 [P] [US1] Ampliar `test/features/conta/presentation/cadastro_page_test.dart`: sem foto mostra "Adicione uma foto para concluir o cadastro."; "Tirar foto"/"Escolher da galeria" levam à prévia com "Usar esta foto" e "Escolher outra"; cancelar a escolha mantém os dados; permissão negada mostra a mensagem e oferece a outra origem; falha de envio mantém os dados e mostra "Não foi possível enviar sua foto. Seus dados continuam preenchidos. Verifique a conexão e toque em Criar conta de novo."; arquivo que não é imagem mostra "Esse arquivo não é uma foto. Escolha uma imagem."; foto acima do limite mostra "Essa foto ficou grande demais. Escolha outra." (FR-021)
- [X] T016 [P] [US1] Ampliar `test/features/conta/domain/conta_service_test.dart`: `cadastrar` exige foto; falha ao gravar a foto não cria conta (FR-017)
- [X] T017 [P] [US1] Criar `test/core/redirect_foto_test.dart`: conta com `temFoto == false` em qualquer rota autenticada vai para `/foto`; com `temFoto == true`, `/foto` vai para `/inicio` (FR-018)
- [X] T018 [P] [US1] Criar `test/features/perfil/presentation/adicionar_foto_page_test.dart`: enviar foto leva ao início; falha mostra "Não foi possível enviar sua foto. Verifique a conexão e tente de novo."; as mensagens de `FotoErro.naoImagem`, `FotoErro.grandeDemais` e `FotoErro.semPermissao` também aparecem em Adicionar foto (FR-021, FR-022)
- [X] T019 [P] [US1] Criar `test/features/perfil/presentation/trocar_foto_test.dart`: em Meu perfil, "Trocar foto" com prévia; falha mantém a foto anterior (FR-019)
- [X] T020 [P] [US1] Ampliar `test/features/candidaturas/domain/candidatura_service_test.dart`: candidatar grava a cópia da foto do prestador; aceitar grava a cópia da foto do contratante; trocar a foto depois não altera cópias existentes (FR-019)
- [X] T021 [P] [US1] Criar `test/features/candidaturas/presentation/revisar_candidaturas_page_test.dart`: candidaturas pendentes e recusadas mostram a inicial; a aceita mostra a foto do prestador
- [X] T022 [P] [US1] Ampliar `test/features/pedidos/presentation/gerenciar_pedido_page_test.dart`: em andamento, cada parte vê o avatar com a foto da outra; pedido cancelado volta a mostrar a inicial; candidatura anterior à 002 sem cópia mostra a inicial
- [X] T023 [P] [US1] Criar `test/firestore_rules_002_test.dart` (estático) com as garantias de foto de `contracts/firestore-security.md`: `users/{uid}/private/foto` só do dono e "1 a 204 800 bytes"; `applications/{providerUid}/private/foto` legível pelo contratante só com `prestadorEscolhidoUid == providerUid`; `fotos/{contratanteUid}`; cópias com `imagem == get(privateFotoPath(...)).imagem`; `update, delete: if false` nas cópias; `profiles` create com `totalAvaliacoes == 0` e `somaNotas == 0` (FR-026, FR-028)

### Implementação

- [X] T024 [US1] Implementar `ImagePickerSeletorFoto` em `lib/features/perfil/data/image_picker_seletor_foto.dart`: `maxWidth: 300`, `maxHeight: 300`, `imageQuality: 70`; se passar de 204 800 bytes, tentar com `imageQuality: 50`; ainda maior → `FotoErro.grandeDemais`; `camera_access_denied`/`photo_access_denied` → `FotoErro.semPermissao`
- [X] T025 [US1] Adicionar `temFoto` em `lib/features/conta/domain/conta.dart`, o parâmetro `foto` em `cadastrar` e o método `adicionarFoto` em `lib/features/conta/domain/conta_repository.dart`, `lib/features/conta/domain/conta_service.dart` e no fake
- [X] T026 [US1] Em `lib/features/conta/data/firebase_conta_repository.dart`: cadastro grava num único batch `users/{uid}`, `private/contact`, `private/foto` e `profiles/{uid}` ("totalAvaliacoes 0, somaNotas 0, notaMedia 0, ultimaAvaliacaoId null") e apaga o usuário do Auth se falhar; `observarSessao` calcula `temFoto` pela existência de `private/foto` e `profiles/{uid}`; `adicionarFoto` grava a foto e cria `profiles/{uid}` se faltar (research D7, D8)
- [X] T027 [US1] Implementar `FirestorePerfilRepository.carregarFotoPropria`/`salvarFotoPropria` em `lib/features/perfil/data/firestore_perfil_repository.dart`
- [X] T028 [US1] Criar o widget `EscolherFoto` (dois botões, prévia circular, mensagens de `FotoErro`) em `lib/features/perfil/presentation/escolher_foto.dart`
- [X] T029 [US1] Incluir a seção "Foto" com `EscolherFoto` em `lib/features/conta/presentation/cadastro_page.dart`
- [X] T030 [US1] Criar `AdicionarFotoPage` em `lib/features/perfil/presentation/adicionar_foto_page.dart`, a rota `/foto` e o redirect por `temFoto` em `lib/core/router.dart`
- [X] T031 [US1] Criar `MeuPerfilPage` com foto própria e "Trocar foto" em `lib/features/perfil/presentation/meu_perfil_page.dart`, a rota `/perfil` e o cartão "Meu perfil" em `lib/features/conta/presentation/inicio_page.dart`
- [X] T032 [US1] Em `lib/features/candidaturas/data/firestore_candidatura_repository.dart` (e interface/fake): `candidatar` grava `applications/{uid}/private/foto` na mesma transação; `aceitar` grava `fotos/{contratanteUid}` na transação atual; criar `carregarFotoDaParte(pedidoId, uid)` que lê a cópia certa
- [X] T033 [US1] Mostrar `AvatarPessoa` em `lib/features/candidaturas/presentation/revisar_candidaturas_page.dart` e `lib/features/pedidos/presentation/gerenciar_pedido_page.dart`, usando `podeVerFotoDaParte`
- [X] T034 [US1] Em `firestore.rules`: blocos `users/{uid}/private/foto`, `applications/{providerUid}/private/foto`, `fotos/{contratanteUid}` e `profiles/{uid}` create, conforme `contracts/firestore-security.md`

**Checkpoint**: US1 funciona sozinha; `flutter test` e `flutter analyze` passam

---

## Phase 4: User Story 2 – Concluir o pedido e avaliar a outra parte (Priority: P2)

**Goal**: Contratante conclui pedido em andamento; cada parte avalia a outra uma vez, de forma
definitiva, com reputação atualizada na mesma operação.

**Independent Test**: Concluir como contratante; avaliar dos dois lados; segunda avaliação, edição
e avaliação por terceiro recusadas; pedido mostra "Você já avaliou".

### Testes (escrever primeiro e ver falhar)

- [X] T035 [P] [US2] Ampliar `test/features/pedidos/domain/pedido_permissions_test.dart`: `podeConcluir` só para o contratante com pedido em andamento; `podeAvaliar` só para as partes com pedido concluído; pedido concluído não pode ser editado nem cancelado (FR-001, FR-002)
- [X] T036 [P] [US2] Criar `test/features/avaliacoes/domain/avaliacao_validator_test.dart`: nota ausente, 0 ou 6 → "Escolha uma nota de 1 a 5."; comentário com 301 caracteres → "O comentário pode ter até 300 caracteres."; 300 e vazio aceitos; comentário só com espaços é aceito como vazio; 300 caracteres visíveis com emoji composto (por exemplo, família) e acento é aceito; 301 é recusado; a contagem usa `characters` (FR-004) (contar caracteres visíveis com `texto.trim().characters.length`, importando `package:characters/characters.dart`, declarado no `pubspec.yaml`; ver plan.md §Dependências novas)
- [X] T037 [P] [US2] Criar `test/features/avaliacoes/domain/avaliacao_service_test.dart`: recusa pedido não concluído, quem não é parte e segunda avaliação; avaliado é sempre a outra parte; `avaliadorNome` é o nome no momento da avaliação
- [X] T038 [P] [US2] Criar `test/features/pedidos/domain/pedido_concluir_test.dart`: `PedidoService.concluir` só do contratante e só de em andamento
- [X] T039 [P] [US2] Criar `test/features/pedidos/presentation/concluir_pedido_page_test.dart`: aviso "Depois de concluído, o pedido não pode mais ser editado nem cancelado. Você e o prestador poderão se avaliar."; sucesso mostra "Pedido concluído."; recusa mostra "Este pedido não pode ser concluído agora."
- [X] T040 [P] [US2] Criar `test/features/avaliacoes/presentation/avaliar_page_test.dart`: estrelas com rótulos "1 estrela"…"5 estrelas"; contador "0/300"; falha preserva nota e comentário; toque duplo gera uma só avaliação; depois de enviar, o pedido mostra "Você já avaliou"
- [X] T041 [P] [US2] Ampliar `test/features/pedidos/presentation/meus_pedidos_page_test.dart`: em andamento, só o contratante vê "Concluir pedido"; concluído mostra "Avaliar" ou "Você já avaliou" para cada parte
- [X] T042 [P] [US2] Ampliar `test/firestore_rules_002_test.dart`: ramo "concluir" exige `em_andamento`; avaliação create exige `concluido`, partes cruzadas, `nota` "1 a 5", `comentario.size() <= 1200` (teto de segurança; os 300 visíveis são validados no app), `getAfter` do perfil; `update, delete: if false` em avaliações; `totalAvaliacoes`, `somaNotas`, `notaMedia` só no ramo de avaliação (FR-027)

### Implementação

- [X] T043 [US2] Adicionar `concluir(pedidoId)` em `lib/features/pedidos/domain/pedido_repository.dart`, `pedido_service.dart`, `lib/features/pedidos/data/firestore_pedido_repository.dart` (só `estado` e `atualizadoEm`) e no fake; `PedidoPermissions.podeConcluir`/`podeAvaliar`
- [X] T044 [P] [US2] Criar `Avaliacao` e `AvaliacaoValidator` em `lib/features/avaliacoes/domain/avaliacao.dart` e `avaliacao_validator.dart` (contar caracteres visíveis com `texto.trim().characters.length`, importando `package:characters/characters.dart`, declarado no `pubspec.yaml`; ver plan.md §Dependências novas)
- [X] T045 [US2] Criar `AvaliacaoService` em `lib/features/avaliacoes/domain/avaliacao_service.dart`
- [X] T046 [US2] Implementar `FirestoreAvaliacaoRepository.avaliar` como transação que cria `profiles/{avaliado}/avaliacoes/{requestId}` e atualiza `totalAvaliacoes + 1`, `somaNotas + nota`, `notaMedia` e `ultimaAvaliacaoId`, e `jaAvaliou`, em `lib/features/avaliacoes/data/firestore_avaliacao_repository.dart` (research D6)
- [X] T047 [US2] Criar `AvaliacaoController` em `lib/features/avaliacoes/presentation/avaliacao_controller.dart`
- [X] T048 [US2] Criar `ConcluirPedidoPage` em `lib/features/pedidos/presentation/concluir_pedido_page.dart` e a rota `/pedidos/:pedidoId/concluir` (somente contratante) em `lib/core/router.dart`
- [X] T049 [US2] Criar `AvaliarPage` em `lib/features/avaliacoes/presentation/avaliar_page.dart` e a rota `/pedidos/:pedidoId/avaliar` (quem não é parte → `/inicio`)
- [X] T050 [US2] Em `firestore.rules`: ramo "concluir"; leitura de `concluido` pelo prestador escolhido em `allow get` e `allow list` separados; `profiles/{avaliadoUid}/avaliacoes/{requestId}` create; ramo de avaliação no update de `profiles/{uid}`
- [X] T051 [US2] Ações "Concluir pedido", "Avaliar" e "Você já avaliou" em `lib/features/pedidos/presentation/meus_pedidos_page.dart` e `gerenciar_pedido_page.dart`; a consulta do prestador em Meus pedidos inclui `concluido` (depende de T050)

**Checkpoint**: US1 e US2 funcionam; `flutter test` e `flutter analyze` passam

---

## Phase 5: User Story 3 – Consultar perfil e reputação (Priority: P3)

**Goal**: Meu perfil e Perfil de outra pessoa com reputação e avaliações recentes, abertos a partir
do início, das candidaturas e do pedido.

**Independent Test**: Com avaliações registradas, abrir Meu perfil pelo início e o perfil de um
candidato pelas candidaturas; conferir média, total, avaliações recentes e ausência de bairro e
e-mail.

### Testes (escrever primeiro e ver falhar)

- [ ] T052 [P] [US3] Criar `test/features/perfil/presentation/meu_perfil_page_test.dart`: "4,7", "12 avaliações"/"1 avaliação", 5 avaliações recentes com nota, comentário, nome e data dd/MM/aaaa; "Ainda sem avaliações"; estados de carregando, vazio e erro com "Tentar novamente"; nenhum bairro nem e-mail; data no fuso `America/Sao_Paulo` (FR-008)
- [ ] T053 [P] [US3] Criar `test/features/perfil/presentation/perfil_pessoa_page_test.dart`: contratante abre candidato pelas candidaturas e vê a inicial; após o aceite vê a foto; prestador vê o contratante pela lista com a inicial; sem `pedido` na rota vai para `/inicio`; nenhum bairro nem e-mail
- [ ] T054 [P] [US3] Ampliar `test/features/pedidos/presentation/lista_pedidos_page_test.dart`: ação "Ver contratante" no cartão abre o perfil do contratante
- [ ] T055 [P] [US3] Ampliar `test/firestore_rules_002_test.dart`: `profiles` get para autenticados e sem `allow list`; avaliações get e list para autenticados; `users/{uid}` continua só do dono

### Implementação

- [ ] T056 [US3] Implementar `carregarPerfil` e `listarRecentes` ("5 mais recentes, `orderBy('criadaEm', descending)`, `limit(5)`") em `lib/features/perfil/data/firestore_perfil_repository.dart` e `lib/features/avaliacoes/data/firestore_avaliacao_repository.dart`, e nos fakes
- [ ] T057 [US3] Criar `PerfilController` em `lib/features/perfil/presentation/perfil_controller.dart`
- [ ] T058 [US3] Completar `MeuPerfilPage` com nome, cidade, selo do tipo, média, total e avaliações recentes em `lib/features/perfil/presentation/meu_perfil_page.dart`
- [ ] T059 [US3] Criar `PerfilPessoaPage` em `lib/features/perfil/presentation/perfil_pessoa_page.dart` e a rota `/perfis/:uid?pedido=:pedidoId` em `lib/core/router.dart`
- [ ] T060 [US3] Pontos de entrada: toque no candidato em `revisar_candidaturas_page.dart`, "Ver contratante" em `lista_pedidos_page.dart` e avatar da outra parte em `gerenciar_pedido_page.dart`
- [ ] T061 [US3] Em `firestore.rules`: `profiles/{uid}` get (sem list) e `avaliacoes` get/list

**Checkpoint**: as três histórias funcionam de forma independente

---

## Phase 6: Polish & Cross-Cutting

- [ ] T062 [P] Incluir Adicionar foto, Meu perfil, Perfil de outra pessoa, Concluir pedido e Avaliar em `test/core/acessibilidade_layout_test.dart` (48 dp e rótulos)
- [ ] T063 Registrar em `specs/001-cadastro-e-pedidos/data-model.md` que a retenção de pedidos deve apagar também `fotos/*` e `applications/*/private/foto` (FR-028), sem implementar o processo
- [ ] T064 Pedir confirmação e publicar regras e índices (`firebase deploy --only firestore:rules,firestore:indexes --project bicolocal-35534`); executar o roteiro de `specs/002-perfil-e-avaliacoes/quickstart.md`
- [ ] T065 Rodar `flutter analyze` e `flutter test` e informar os resultados

---

## Dependencies & Execution Order

- **Setup (T001–T003)** → **Foundational (T004–T014)** → histórias.
- **US1** não depende de outras histórias.
- **US2** usa `profiles/{uid}`, criado em T026 (US1). Para testar US2 sozinha com fakes, basta o
  `FakePerfilRepository` da Foundational; no Firebase real, US1 precisa estar publicada antes.
- **US3** usa avaliações de US2 para ter conteúdo, mas funciona sem elas ("Ainda sem avaliações")
  e é testável só com fakes.
- Dentro de cada história: testes → domínio → dados → telas → regras.
- `firestore.rules` é editado em T034, T050 e T061, em sequência (mesmo arquivo).

## Parallel Example

```text
# US1, testes em paralelo:
T015 cadastro_page_test   T016 conta_service_test   T017 redirect_foto_test
T018 adicionar_foto_page_test   T020 candidatura_service_test   T023 firestore_rules_002_test

# US2, testes em paralelo:
T035 pedido_permissions_test   T036 avaliacao_validator_test   T037 avaliacao_service_test
T039 concluir_pedido_page_test   T040 avaliar_page_test
```

## Implementation Strategy

1. **MVP**: Setup + Foundational + US1 → validar foto obrigatória e privacidade da foto.
2. **Incremento 2**: US2 → conclusão e avaliações.
3. **Incremento 3**: US3 → perfis com reputação.
4. Ao fim de cada fase: `flutter analyze` e `flutter test` limpos antes de seguir.
