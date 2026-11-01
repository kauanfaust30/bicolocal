# BicoLocal: projeto pronto para VS Code + Codex

Pasta preparada para construir o BicoLocal (Flutter) com Spec-Driven Development usando o **Codex** como agente. No Codex, os comandos do Spec Kit começam com **`$`** (ex.: `$speckit-specify`), e não com `/`.

Regra de ouro da aula: **a spec diz o quê; o plano diz o como.** Nada de Flutter ou Firebase nas specs. Você revisa cada etapa antes de seguir.

## 1. Pré-requisitos (instale uma vez)

- [Git](https://git-scm.com), [Flutter SDK](https://docs.flutter.dev/get-started/install) (`flutter doctor` sem erros), Python 3.11+
- Codex: extensão **Codex** no VS Code ou CLI (`npm i -g @openai/codex`), com login feito
- Extensões do VS Code: Flutter e Dart

## 2. Preparar o projeto (um clique)

1. No VS Code: **File > Open Folder** e abra esta pasta `bicolocal`.
2. Pressione `Ctrl+Shift+P` > **Tasks: Run Task** > escolha **1. Preparar projeto** (Windows ou macOS/Linux).
   - Ou rode no terminal: `powershell -ExecutionPolicy Bypass -File setup.ps1` (Windows) / `bash setup.sh` (macOS/Linux).
3. O script instala o Specify CLI, cria o projeto Flutter, roda `specify init --here --integration codex` e faz o primeiro commit. O seu `AGENTS.md` é preservado.
4. Confirme que existe a pasta `.agents/skills/` com as skills `speckit-*`.

## 3. Abrir o Codex e conferir

Abra o Codex **nesta pasta**, em sessão nova (ele lê o `AGENTS.md` ao iniciar), e digite `$speckit-`. As skills devem aparecer. Se não aparecerem: rode `specify integration status`, reinicie o Codex e confira `.agents/skills/`.

Permissões sugeridas no Codex: permitir `flutter test`, `flutter analyze`, `flutter pub get` e edição em `lib/` e `test/`; pedir aval para `git push` e `flutter pub add`; negar ler `.env` ou chaves.

---

## 4. Feature 1 (Entrega 1, 03/11): cadastro, login e pedidos

Cole **um comando por vez** no chat do Codex e revise o resultado antes do próximo.

### 4.1 Constituição

```
$speckit-constitution Crie princípios para o projeto BicoLocal, um aplicativo móvel que conecta quem precisa de serviços rápidos com pessoas que buscam bicos na região: código Dart simples e legível, com widgets e funções pequenos; teste primeiro com flutter test (inegociável); poucas dependências, cada uma justificada no plano; mensagens ao usuário em português, claras e acionáveis; dados pessoais protegidos, com contato visível apenas após o aceite do prestador; interface simples, pensada para celular.
```

Revise: algum princípio está vago demais para ser verificado? Edite à mão.

### 4.2 Especificação (só o quê e o porquê)

```
$speckit-specify Quero um aplicativo que substitua a busca desorganizada por trabalhadores em grupos de mensagens por uma plataforma centralizada. Existem dois perfis: contratante (quem precisa de um serviço rápido) e prestador (quem busca bicos na região). Nesta primeira funcionalidade, uma pessoa pode se cadastrar e entrar no aplicativo escolhendo seu perfil, informando nome, cidade e bairro. O contratante pode publicar um pedido de serviço com título, categoria, descrição, local, data desejada e valor combinado. O prestador pode ver a lista de pedidos abertos da sua região e filtrá-los por categoria. O objetivo é que o contratante encontre ajuda mais rápido e que o prestador encontre serviços perto de si.
```

Checklist de revisão da spec:

- [ ] Nenhuma tecnologia (Flutter, Firebase, SQLite) aparece na spec
- [ ] Cada requisito dá para testar (passa ou falha)
- [ ] A história P1 entrega valor sozinha
- [ ] Casos de borda listados (e-mail já cadastrado, lista vazia, campos obrigatórios em branco)
- [ ] Dúvidas aparecem como `[NEEDS CLARIFICATION]`

### 4.3 Esclarecimentos

```
$speckit-clarify
```

Responda com decisão **sua**, não só "aceitar a sugestão". Pontos prováveis: o pedido tem prazo de validade? Quem edita ou cancela um pedido? "Região" é cidade ou bairro?

### 4.4 Plano (aqui entra a tecnologia)

```
$speckit-plan Flutter estável com Dart. Autenticação por e-mail e senha com Firebase Authentication. Persistência em Cloud Firestore (coleções de usuários, pedidos e categorias). Gerenciamento de estado com Provider. Navegação com go_router. Testes de unidade e de widget com flutter test, usando repositórios falsos (sem acessar o Firebase real nos testes). Sem backend próprio.
```

Alternativa sem conta Firebase (só protótipo): troque a persistência por SQLite com o pacote `sqflite` e login local.

Revise: o plano respeita **cada** princípio da constituição? Há algo que não está na spec? Abra o `quickstart.md`.

### 4.5 Checklist, tarefas e análise

```
$speckit-checklist Usabilidade e segurança dos dados pessoais
```

```
$speckit-tasks Os testes vêm antes da implementação de cada tarefa. Organize por história de usuário.
```

```
$speckit-analyze
```

Corrija os achados **altos** na spec, no plano ou nas tarefas (não no código) e rode `analyze` de novo.

### 4.6 Implementação

```
$speckit-implement Execute somente as tarefas da História 1 (MVP).
```

Durante a execução: os testes aparecem vermelhos antes de ficarem verdes? Leia cada comando antes de aprovar. Depois, se quiser, rode `$speckit-converge`.

### 4.7 Revisão do que a IA entregou

- [ opcao A] Rodei `flutter test` e `flutter analyze` eu mesmo (Tasks: Run Task no VS Code)
- [ ] Cada cenário da spec tem um teste
- [ ] Li o diff por tarefa; não há arquivos fora do plano
- [ ] Não há código que ninguém pediu
- [ ] Rodei o app (`flutter run`) e segui o `quickstart.md`
- [ ] Tirei os **prints das telas** para a entrega
- [ ] Fiz commit citando a história

---

## 5. Feature 2 (Etapa 2): candidatura e aceite

```
$speckit-specify O prestador pode se candidatar a um pedido aberto, com uma mensagem curta. O contratante vê as candidaturas recebidas em seus pedidos e pode aceitar uma delas. Ao aceitar, o pedido passa a "em andamento", as demais candidaturas são recusadas e o contato do prestador escolhido fica visível ao contratante (e o do contratante ao prestador). O contratante pode marcar o pedido como concluído. Um prestador não pode se candidatar duas vezes ao mesmo pedido.
```

Depois siga: `$speckit-clarify` → `$speckit-plan` → `$speckit-tasks` → `$speckit-analyze` → `$speckit-implement`.

## 6. Feature 3 (Etapa 2): avaliação

```
$speckit-specify Ao concluir um pedido, contratante e prestador podem avaliar um ao outro com nota de 1 a 5 e um comentário opcional, uma única vez por pedido. A nota média e as últimas avaliações aparecem no perfil de cada pessoa, para ajudar na escolha de com quem trabalhar.
```

## 7. Mudou um requisito?

Comece pela spec, não pelo código: `$speckit-specify` (nova história) → clarify → plan → tasks → analyze → implement.

## 8. Quando algo dá errado

| Sintoma | O que fazer |
| --- | --- |
| Skills `$speckit-*` não aparecem | Confira `.agents/skills/`, rode o `init` de novo na raiz e reinicie o Codex |
| A spec veio cheia de tecnologia | Mova para o plano e refaça o `specify` |
| `implement` mexe fora do escopo | Restrinja o escopo, declare o que está fora e refaça plano e tarefas |
| O plano ignora a constituição | Encurte a constituição, torne os princípios verificáveis e rode `analyze` |
| O agente repete o mesmo erro | Escreva a regra no `AGENTS.md` ou crie um teste que falhe |

## 9. Diário do harness (para o relatório)

| # | Falha do agente | O que mudei (guia, sensor ou permissão) |
| --- | --- | --- |
| 1 | | |
| 2 | | |
| 3 | | |

## 10. Mapa para as entregas

| Entrega | O que usar daqui |
| --- | --- |
| 03/11: documentação e planejamento | `spec.md`, `plan.md`, `tasks.md` da Feature 1 + documento da Entrega 1 |
| 03/11: prints das telas | Passo 4.7 |
| 03/11: relatório de 1 página | Diário do harness + estado das tarefas |
| 03/11: link do GitHub | Repositório com histórico: spec, plano, tarefas, código |
| 01/12: entrega final | Features 2 e 3, apresentação e vídeo de até 3 minutos |
