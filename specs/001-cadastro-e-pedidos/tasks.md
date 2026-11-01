---
description: "Tarefas de implementação para cadastro e pedidos locais"
---

# Tasks: Cadastro e pedidos locais

**Input**: Documentos de design em `/specs/001-cadastro-e-pedidos/`

**Pré-requisitos**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/firestore-security.md`, `quickstart.md`.

**Organização**: Tarefas agrupadas por história de usuário. Para cada comportamento, escrever e executar o teste antes de implementar a mudança correspondente, conforme a constituição.

**Formato**: `- [ ] T### [P?] [US#?] descrição com caminho do arquivo`

## Phase 1: Setup

**Objetivo**: Preparar a base do projeto e registrar os pré-requisitos antes de iniciar comportamentos.

- [X] T001 Confirmar com o usuário a inclusão de `firebase_core`, `firebase_auth`, `cloud_firestore`, `provider` e `go_router` antes de editar `pubspec.yaml`, conforme `AGENTS.md` e justificativas em `research.md`
- [X] T002 Após confirmação, adicionar somente as dependências aprovadas e justificadas em `pubspec.yaml`
- [X] T003 Resolver dependências e conferir compatibilidade de Flutter/Dart e requisitos nativos Android/iOS com `flutter pub get`, registrando eventuais ajustes necessários em `specs/001-cadastro-e-pedidos/quickstart.md`
- [ ] T004 Configurar Firebase de desenvolvimento para plataformas alvo e documentar o procedimento seguro em `specs/001-cadastro-e-pedidos/quickstart.md`, sem adicionar segredos ao Git

---

## Phase 2: Foundational

**Objetivo**: Criar estrutura compartilhada necessária antes das histórias. Nenhuma tela deve acessar Firestore diretamente.

- [X] T005 Criar composição do app e inicialização Firebase em `lib/core/app.dart` e `lib/core/firebase/firebase_initializer.dart`
- [X] T006 Criar roteamento compartilhado com pontos de entrada protegidos por sessão e perfil em `lib/core/router.dart`
- [X] T007 Criar suporte comum para mensagens de erro em português e estados de operação em `lib/core/errors/app_error.dart` e `lib/core/async/async_state.dart`
- [X] T008 Registrar no guia de execução os limites de validade: pedido disponível durante todo o dia civil em `America/Sao_Paulo` e expirado às 00:00 do dia seguinte, em `specs/001-cadastro-e-pedidos/quickstart.md`
- [X] T009 Criar suporte compartilhado de repositórios falsos e builders de teste em `test/support/fakes/` e `test/support/builders/`

**Checkpoint**: composição e dependências podem ser usadas pelas histórias; sem regra de negócio de usuário introduzida nesta fase.

---

## Phase 3: User Story 1 - Publicar e encontrar pedidos locais (Priority: P1) 🎯 MVP

**Objetivo**: Permitir cadastro/entrada de contratante e prestador, publicar pedido válido e encontrá-lo como prestador da mesma cidade.

**Teste independente**: cadastrar um contratante e um prestador com fakes, publicar um pedido e verificar que ele aparece na lista do prestador da mesma cidade com os campos previstos; conta de outra cidade não o encontra; nenhuma informação de contato aparece.

### Testes da US1 — escrever e executar antes das implementações

- [X] T010 [P] [US1] Escrever testes unitários de cadastro, validação de campos obrigatórios e e-mail duplicado em `test/features/conta/domain/cadastro_validator_test.dart`
- [X] T011 [P] [US1] Escrever testes de unidade para criação de conta, entrada e mensagens de erro usando repositório falso em `test/features/conta/domain/conta_service_test.dart`
- [X] T012 [P] [US1] Escrever testes unitários para validações de pedido: campos obrigatórios, valor maior que zero, data desejada hoje/futura e validade entre hoje e data desejada no fuso `America/Sao_Paulo` em `test/features/pedidos/domain/pedido_validator_test.dart`
- [X] T013 [P] [US1] Escrever testes de repositório falso para publicação, consulta por cidade e limite de validade (visível durante todo o dia em `America/Sao_Paulo`, excluído a partir das 00:00 seguintes) em `test/features/pedidos/domain/pedido_repository_test.dart`
- [X] T014 [P] [US1] Escrever testes de widget para cadastro/entrada, alternância de perfil, formulário de publicação, lista carregando/vazia/erro e apresentação dos campos do pedido em `test/features/conta/presentation/` e `test/features/pedidos/presentation/`; cobrir também a troca de perfil no teste de serviço da conta
- [X] T015 [US1] Executar `flutter test` na raiz do projeto (`.`) e registrar a falha esperada dos novos testes antes de iniciar as implementações da US1

### Implementação da US1

- [X] T016 [P] [US1] Criar entidade `Conta`, enum `Perfil` e contratos de repositório em `lib/features/conta/domain/conta.dart` e `lib/features/conta/domain/conta_repository.dart`
- [X] T017 [US1] Implementar validação do cadastro e das mensagens em português em `lib/features/conta/domain/cadastro_validator.dart`, exigindo e-mail, senha, nome, cidade, bairro e perfil válido
- [X] T018 [US1] Implementar serviço de conta para cadastro, entrada e troca de perfil, mapeando erros em português em `lib/features/conta/domain/conta_service.dart`
- [X] T019 [US1] Implementar repositórios Firebase Authentication e perfil Firestore, persistindo troca de perfil sem expor contato no perfil público em `lib/features/conta/data/firebase_conta_repository.dart` e `lib/features/conta/data/conta_dto.dart`
- [X] T020 [P] [US1] Criar entidade `Categoria`, entidade `Pedido`, regras de validação e contratos em `lib/features/pedidos/domain/categoria.dart`, `lib/features/pedidos/domain/pedido.dart` e `lib/features/pedidos/domain/pedido_repository.dart`; persistir valor em centavos e datas em ISO 8601
- [X] T021 [US1] Implementar validação de pedido exigindo título, categoria, descrição, local, data desejada, validade e valor positivo em `lib/features/pedidos/domain/pedido_validator.dart`; comparar datas civis no fuso `America/Sao_Paulo`, validade hoje ou futura e não posterior à data desejada
- [X] T022 [US1] Implementar DTO e repositório Firestore para categorias e pedidos em `lib/features/pedidos/data/pedido_dto.dart` e `lib/features/pedidos/data/firestore_pedido_repository.dart`; consulta de prestador corresponde à cidade e exclui pedidos após 00:00 do dia seguinte à validade em `America/Sao_Paulo`
- [X] T023 [US1] Criar gerenciamento de estado Provider para conta e pedidos em `lib/features/conta/presentation/conta_controller.dart` e `lib/features/pedidos/presentation/pedido_controller.dart`, sem chamadas de banco nos widgets
- [X] T024 [US1] Criar telas de cadastro e entrada com textos em português, explicação das permissões e troca de perfil ativa em `lib/features/conta/presentation/cadastro_page.dart`, `lib/features/conta/presentation/entrada_page.dart` e tela inicial
- [X] T025 [US1] Criar formulário de publicação e lista móvel de pedidos, incluindo estados carregando, vazio, erro com nova tentativa e datas em `dd/MM/aaaa`, em `lib/features/pedidos/presentation/publicar_pedido_page.dart` e `lib/features/pedidos/presentation/lista_pedidos_page.dart`
- [X] T026 [US1] Conectar rotas de cadastro, entrada, publicação e lista à sessão/perfil ativo em `lib/core/router.dart` e composição Provider em `lib/core/app.dart`
- [X] T027 [US1] Executar `flutter test` na raiz do projeto (`.`) após a implementação da US1; testes relacionados aos critérios desta história passaram

**Checkpoint**: US1 entrega o MVP de cadastro, publicação e descoberta regional independentemente das histórias de candidatura e filtro.

---

## Phase 4: User Story 3 - Candidatar-se e gerenciar um pedido (Priority: P2)

**Objetivo**: Permitir candidatura única, aceite exclusivo, edição/cancelamento pelas partes autorizadas e revelação do e-mail de acesso conforme FR-013/FR-018.

**Teste independente**: a partir de um pedido aberto, candidatar prestadores, aceitar um deles e verificar exclusividade, permissões de edição/cancelamento e acesso ao e-mail de contato conforme a spec.

### Testes da US3 — escrever e executar antes das implementações

- [X] T028 [P] [US3] Escrever testes unitários para candidatura única, elegibilidade por perfil/estado/validade e aceite de apenas um prestador em `test/features/candidaturas/domain/candidatura_service_test.dart`
- [X] T029 [P] [US3] Escrever testes unitários para autorização de edição/cancelamento antes e depois do aceite e recusa após expiração/cancelamento em `test/features/pedidos/domain/pedido_permissions_test.dart`
- [X] T030 [P] [US3] Escrever testes de política de acesso ao e-mail de acesso antes/depois do aceite, limitados ao contratante autor e ao prestador escolhido em `test/features/conta/domain/contact_access_policy_test.dart`
- [X] T031 [P] [US3] Escrever testes de widget para candidatar, revisar/aceitar candidaturas e editar/cancelar pedido com mensagens de falha em `test/features/candidaturas/presentation/` e `test/features/pedidos/presentation/gerenciar_pedido_page_test.dart`
- [X] T032 [US3] Executar `flutter test` na raiz do projeto (`.`) e registrar a falha esperada dos testes da US3 antes de implementar candidatura, aceite, gerenciamento ou acesso ao contato

### Implementação da US3

- [X] T033 [P] [US3] Criar entidade `Candidatura`, estados e contrato de repositório em `lib/features/candidaturas/domain/candidatura.dart` e `lib/features/candidaturas/domain/candidatura_repository.dart`
- [X] T034 [US3] Implementar regras de domínio para candidatura única, elegibilidade e transições de estado em `lib/features/candidaturas/domain/candidatura_service.dart`
- [X] T035 [US3] Implementar criação de candidatura e aceite atômico no repositório Firestore em `lib/features/candidaturas/data/firestore_candidatura_repository.dart`; aceitar somente um prestador e recusar as demais candidaturas pendentes
- [X] T036 [US3] Implementar autorização de edição e cancelamento de pedido pelo contratante autor e, após aceite, pelo prestador escolhido em `lib/features/pedidos/domain/pedido_permissions.dart`
- [X] T037 [US3] Implementar edição/cancelamento no repositório de pedidos, rejeitando estado expirado ou cancelado em `lib/features/pedidos/data/firestore_pedido_repository.dart`
- [X] T038 [US3] Implementar acesso aos contatos privados vinculados à conta e ao pedido em `lib/features/conta/data/private_contact_repository.dart`, mantendo cópias por pedido fora dos documentos públicos
- [X] T039 [US3] Implementar regras Firestore para perfil, pedido, candidatura e contato conforme `specs/001-cadastro-e-pedidos/contracts/firestore-security.md` em `firestore.rules`
- [X] T040 [US3] Criar controlador e telas de candidatura, revisão/aceite, edição e cancelamento em `lib/features/candidaturas/presentation/` e `lib/features/pedidos/presentation/gerenciar_pedido_page.dart`
- [X] T041 [US3] Executar `flutter test` na raiz do projeto (`.`) após a implementação da US3 e resolver falhas relacionadas aos critérios desta história

**Checkpoint**: concorrência do aceite mantém no máximo um prestador escolhido; somente as partes permitidas gerenciam o pedido e acessam o contato.

---

## Phase 5: User Story 2 - Entrar e filtrar oportunidades (Priority: P3)

**Objetivo**: Permitir ao prestador filtrar a lista de pedidos abertos por categoria e limpar o filtro.

**Dependência**: Requer a lista regional da US1; a história é incremental sobre essa capacidade.

**Teste independente**: como prestador, com pedidos abertos de duas categorias na mesma cidade, selecionar uma categoria e obter somente seus pedidos; categoria sem resultado mostra estado vazio e permite limpar o filtro.

### Testes da US2 — escrever e executar antes das implementações

- [ ] T042 [P] [US2] Escrever testes unitários para consulta por categoria, combinação com cidade/validade e remoção do filtro em `test/features/pedidos/domain/pedido_filter_test.dart`
- [ ] T043 [P] [US2] Escrever testes de widget para seleção/limpeza de categoria e vazio sem resultados em `test/features/pedidos/presentation/filtro_pedidos_widget_test.dart`
- [ ] T044 [US2] Executar `flutter test` na raiz do projeto (`.`) e registrar a falha esperada dos testes de filtro antes de implementar a filtragem

### Implementação da US2

- [ ] T045 [US2] Estender contrato e consulta do repositório para filtro opcional por categoria em `lib/features/pedidos/domain/pedido_repository.dart` e `lib/features/pedidos/data/firestore_pedido_repository.dart`
- [ ] T046 [US2] Adicionar estado de filtro e ação para limpar seleção em `lib/features/pedidos/presentation/pedido_controller.dart`
- [ ] T047 [US2] Adicionar seletor de categoria e estado vazio com ação de limpar filtro na lista em `lib/features/pedidos/presentation/lista_pedidos_page.dart`
- [ ] T048 [US2] Executar `flutter test` na raiz do projeto (`.`) após a implementação da US2 e resolver falhas relacionadas aos critérios desta história

**Checkpoint**: filtragem por categoria é utilizável sem alterar critérios regionais, estados de lista ou privacidade da US1.

---

## Phase 6: Polish e validação transversal

**Objetivo**: Consolidar qualidade e confirmar o quickstart após as histórias desejadas.

- [ ] T049 [P] Atualizar `specs/001-cadastro-e-pedidos/quickstart.md` com configuração Firebase, plataformas efetivamente suportadas e passos finais de validação
- [ ] T050 [P] Revisar mensagens, datas e estados de carregamento/vazio/erro nas telas em `lib/features/`
- [ ] T051 Revisar regras, consultas e exposição de contato contra `specs/001-cadastro-e-pedidos/contracts/firestore-security.md` em `firestore.rules` e repositórios Firestore
- [ ] T052 Executar `flutter test` e `flutter analyze` na raiz do projeto (`.`) após concluir as histórias previstas

## Dependências e ordem de execução

### Dependências entre fases

- Setup (T001–T004) precede o uso das dependências e Firebase no app. T002–T004 aguardam a confirmação de pacotes de T001.
- Foundational (T005–T009) depende do Setup; T008 registra a regra temporal já definida na spec para orientar validação manual.
- US1 (P1) depende de Setup e Foundational e não depende das outras histórias.
- US3 (P2) depende da conta e dos pedidos abertos publicados na US1.
- US2 (P3) depende da lista regional e categorias da US1.
- Polish depende das histórias escolhidas para a entrega.

### Ordem das histórias

`Setup → Foundational → US1 (P1) → US3 (P2) → US2 (P3) → Polish`

Embora US2 e US3 possam ser desenvolvidas após US1, ambas ampliam capacidades existentes na US1; para manter uma sequência simples e prioridades da spec, concluir US3 antes de US2. Cada uma tem critério independente de aceitação.

### Paralelismo seguro

- Setup: T003 e preparação documental T004 podem ocorrer em paralelo depois da aprovação T001/T002.
- US1: T010–T014 são testes em arquivos distintos e podem ser escritos em paralelo. Após T015, T016 e T020 são modelos/contratos em arquivos distintos; interface de conta e de pedidos também pode ser trabalhada separadamente depois dos respectivos domínios/repositórios.
- US3: T028–T031 são testes em arquivos distintos. Após T032/T033, políticas de pedido e domínio de candidatura podem avançar em paralelo; mudanças compartilhadas em `firestore_pedido_repository.dart` devem ser coordenadas entre T037 e T045.
- US2: T042 e T043 podem ser escritos em paralelo; T045–T047 permanecem em sequência por dependerem do contrato, estado e interface.

### Exemplo de execução paralela por história

```text
US1, antes de qualquer implementação:
  T010 cadastro/validações de conta
  T012 validações do pedido
  T014 widgets de conta e pedidos
Depois da falha esperada em T015:
  T016 conta/domain e T020 pedidos/domain em arquivos distintos

US3, antes de qualquer implementação:
  T028 regras de candidatura
  T029 permissões do pedido
  T030 acesso ao e-mail de contato
Depois da falha esperada em T032:
  T033 domínio de candidatura e T036 política de pedido em arquivos distintos

US2, antes de qualquer implementação:
  T042 filtro de domínio e T043 widget de filtro
Depois da falha esperada em T044:
  T045 contrato/repositório → T046 estado → T047 interface
```

## Estratégia de implementação

### MVP primeiro

1. Resolver Setup e Foundational.
2. Concluir somente US1: cadastro, entrada, publicação e descoberta local.
3. Escrever cada teste primeiro, executar `flutter test` e observar a falha esperada antes de implementar a parte correspondente.
4. Validar a US1 pelo seu teste independente; isso já entrega o objetivo inicial de aproximar oferta e procura.

### Entregas incrementais

1. US1 como MVP.
2. US3 para candidatura, aceite, gerenciamento e contato autorizado.
3. US2 para filtro por categoria.
4. Executar os comandos de qualidade ao final e atualizar o quickstart.

## Notas

- `[P]` indica tarefas que podem ser feitas em paralelo sem editar o mesmo arquivo nem depender de tarefa incompleta.
- IDs de história correspondem a `spec.md`: US1=P1, US3=P2, US2=P3.
- Todos os comportamentos seguem TDD: teste, execução com falha esperada, implementação, execução novamente.
- Repositórios falsos são obrigatórios em `flutter test`; não conectar testes a Firebase real.
- A inclusão de pacotes e o canal de contato permanecem gates explícitos registrados neste plano.
