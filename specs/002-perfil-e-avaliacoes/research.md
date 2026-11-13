# Research: Perfil com foto e avaliações

Decisões técnicas da 002. Não restam itens NEEDS CLARIFICATION.

## D1. Perfil público separado de `users/{uid}`

- **Decision**: Criar `profiles/{uid}` com `nome`, `cidade`, `perfil`, `notaMedia`,
  `totalAvaliacoes`, `somaNotas` e `ultimaAvaliacaoId`, legível por qualquer pessoa autenticada.
  `users/{uid}` continua privado (com bairro) e não muda de regra de leitura.
- **Rationale**: Regras do Firestore liberam documentos inteiros, não campos. Separar é a única
  forma de expor nome e reputação sem expor bairro (FR-010, FR-015).
- **Alternatives considered**: Abrir `users/{uid}` para leitura — exporia bairro. Duplicar o nome
  em cada pedido — não atende ao perfil com reputação.
- **Nota**: `ultimaAvaliacaoId` não estava na lista de campos pedida. É necessário para que a
  regra de `update` do perfil saiba qual avaliação está sendo criada na mesma operação e confira
  a nota dela (D6). Não é exibido.

## D2. Foto privada em `users/{uid}/private/foto`, sem Storage

- **Decision**: Guardar a foto como `Bytes` (JPEG) no campo `imagem`, com `atualizadaEm`, legível
  e gravável só pelo dono. Limite de 200 KB nas regras.
- **Rationale**: Atende "sem Storage" e cabe com folga no limite de 1 MiB por documento. Segue o
  padrão de `private/contact`.
- **Alternatives considered**: Firebase Storage — descartado pelo usuário e exigiria outra
  dependência e outras regras. Base64 em string — 33% maior, sem vantagem.

## D3. Redução da imagem com o próprio `image_picker`

- **Decision**: `pickImage(source, maxWidth: 300, maxHeight: 300, imageQuality: 70)`; prévia com
  `Image.memory`. Se o resultado passar de 200 KB (raro), tentar de novo com `imageQuality: 50`; se
  ainda passar, recusar com mensagem (FR-021).
- **Rationale**: O `image_picker` já redimensiona e comprime no aparelho (Android, iOS e web), então
  não há motivo para um segundo pacote. A 300 px e qualidade 70, uma foto de rosto fica em 20–60 KB.
- **Alternatives considered**: `flutter_image_compress` ou `image` — dependência extra
  desnecessária; o pacote `image` também seria lento em Dart puro.
- **Permissões**: Android não precisa declarar permissão para galeria nem câmera via intent. iOS
  exige as duas chaves de `Info.plist`. Acesso negado chega como `PlatformException`
  (`camera_access_denied`, `photo_access_denied`) e vira `FotoErro.semPermissao` (FR-022).

## D4. Cópia da foto para as partes do pedido

- **Problema da versão anterior**: o pedido era copiar "a foto das duas partes" no aceite. Sem
  Cloud Functions, quem escreve no aceite é o contratante, e a foto do prestador está em
  `users/{prestador}/private/foto`, que só o prestador pode ler. Então o contratante não tem como
  copiá-la. A primeira saída (o prestador copiar a própria foto ao abrir o pedido depois do aceite)
  deixava o contratante vendo só a inicial até o prestador abrir o app.
- **Decision** (adotada em 2026-11-12, mesmo padrão do `private/contact` da 001):
  - **Prestador**: ao se candidatar, grava a cópia da própria foto em
    `requests/{id}/applications/{providerUid}/private/foto`, na mesma transação da candidatura e do
    contato. Leitura: o próprio prestador sempre; o contratante só quando o pedido está em
    andamento ou concluído **e** `prestadorEscolhidoUid == providerUid`.
  - **Contratante**: no aceite, grava a cópia da própria foto em
    `requests/{id}/fotos/{contratanteUid}`, na transação que já existe em `aceitar`. Leitura: o
    contratante e o prestador escolhido, com o pedido em andamento ou concluído.
  - As duas cópias são só `create`, gravadas pelo próprio dono e com `imagem` idêntica a
    `users/{uid}/private/foto` (conferido pela regra).
- **Rationale**: Funciona só com regras. As duas fotos ficam disponíveis no momento do aceite, sem
  depender de o prestador abrir o app. A cópia do candidato fica guardada no pedido, mas a regra de
  leitura nunca a libera ao contratante se ele não for o escolhido: **candidatos não escolhidos
  nunca têm a foto lida**.
- **Consequências**:
  - A foto do prestador num pedido é a que ele tinha **ao se candidatar**. Se trocar a foto entre a
    candidatura e o aceite, o pedido aceito mostra a anterior, como determinam o cenário 5 da
    História 1 e o FR-019.
  - A foto do contratante num pedido é a que ele tinha **no aceite**. Se trocar a foto depois, a
    nova vale só para os pedidos aceitos depois da troca (cenário 5 da História 1 e FR-019).
  - Candidaturas feitas antes da 002 não têm cópia; se forem aceitas, o contratante vê a inicial
    (FR-020: "enquanto a foto não tiver sido enviada").
  - A cópia ocupa até 200 KB por candidatura no Firestore.
- **Pendência (resolvida em 2026-11-12)**: a spec foi ajustada (cenário 5 da História 1 e FR-019):
  a nova foto vale para as candidaturas enviadas depois da troca, e as já enviadas mantêm a foto
  do momento da candidatura. As candidaturas anteriores à 002 entraram em Edge Cases. A
  alternativa de atualizar as cópias de candidaturas pendentes ao trocar a foto (consulta de grupo
  de coleções sobre `applications`, com regra e índice novos) não é necessária.
- **Alternatives considered**: Prestador copia ao abrir o pedido aceito (versão anterior) —
  substituída: atraso na foto. Contratante lê a foto privada do prestador após o aceite — a foto
  deixaria de ser privada do dono e a troca valeria para pedidos já aceitos. Cloud Functions —
  excluídas pelo usuário.

## D5. Estado `concluido`

- **Decision**: Novo valor `concluido` em `requests.estado`. Transição só de `em_andamento`, só
  pelo contratante, alterando apenas `estado` e `atualizadoEm`. As regras de edição e cancelamento
  da 001 já exigem `aberto` ou `em_andamento` (`mayManage`), então um pedido concluído fica imutável
  sem regra extra. As regras de leitura passam a aceitar `concluido` para o prestador escolhido,
  mantendo `allow get` e `allow list` separados.
- **Rationale**: Menor mudança possível no modelo de estados da 001.
- **Alternatives considered**: Campo booleano `concluido` — duplicaria o estado e abriria
  combinações inválidas.

## D6. Avaliação e reputação na mesma escrita atômica

- **Decision**: Transação do cliente que lê `profiles/{avaliado}` e grava:
  1. `profiles/{avaliado}/avaliacoes/{requestId}` (create);
  2. `profiles/{avaliado}` com `totalAvaliacoes + 1`, `somaNotas + nota`,
     `notaMedia = somaNotas / totalAvaliacoes` e `ultimaAvaliacaoId = requestId`.
  As regras cruzam os dois lados com `get`/`getAfter`/`existsAfter`: a avaliação só é criada se o
  perfil mudar exatamente assim, e o perfil só muda se a avaliação nova existir depois e não
  existir antes. `notaMedia` é conferida com tolerância de 0,001 (`math.abs`).
- **Rationale**: O id do documento ser o `requestId` impõe uma avaliação por parte por pedido
  (create em documento existente é update, que é negado). A transação é necessária, e não um
  batch simples, porque o cliente precisa ler a soma e o total atuais para calcular a média.
  Ela é tão atômica quanto um batch.
- **Alternatives considered**: `FieldValue.increment` em batch — não permite gravar a média
  coerente. Calcular a média só na leitura — o usuário pediu `notaMedia` guardada.
- **Concorrência**: Duas avaliações simultâneas ao mesmo avaliado (de pedidos diferentes)
  conflitam na transação, que é reexecutada pelo SDK com os valores novos.

## D7. Conta antiga sem foto ou sem perfil público

- **Decision**: Ao carregar a sessão, o repositório verifica se existem `users/{uid}/private/foto`
  e `profiles/{uid}`. `Conta.temFoto` fica falso se faltar a foto ou o perfil público. O redirect do
  `go_router` leva a `/foto` qualquer rota autenticada enquanto `temFoto` for falso. Adicionar foto
  grava a foto e, se faltar, cria `profiles/{uid}` a partir de `users/{uid}`, numa só escrita.
- **Rationale**: Atende FR-018 e migra contas da 001 sem script administrativo.

## D8. Cadastro atômico com foto

- **Decision**: Depois de criar o usuário no Auth, gravar num único batch `users/{uid}`,
  `users/{uid}/private/contact`, `users/{uid}/private/foto` e `profiles/{uid}`. Se o batch falhar,
  apagar o usuário do Auth (comportamento atual) e mostrar "Não foi possível enviar sua foto. Seus
  dados continuam preenchidos. Verifique a conexão e toque em Criar conta de novo."
- **Rationale**: Hoje o cadastro faz duas gravações em sequência; com o batch, ou tudo é criado ou
  nada é (FR-017).

## D9. Testes

- **Decision**: Testes de domínio e de widget com fakes (`FakePerfilRepository`,
  `FakeAvaliacaoRepository`, `FakeSeletorFoto`, `FakePedidoRepository` com `concluir`), sem
  Firebase. As regras ganham testes estáticos de texto (padrão de
  `test/firestore_rules_perfil_test.dart`) para cada garantia crítica, e são validadas de verdade
  pelo [quickstart.md](quickstart.md) após o deploy.
- **Alternatives considered**: Emulador do Firestore com `@firebase/rules-unit-testing` — seria
  o ideal para regras, mas exige Node e Java no ambiente e uma suíte fora do `flutter test`. Fica
  como melhoria futura.
