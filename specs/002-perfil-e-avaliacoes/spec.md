# Feature Specification: Perfil com foto e avaliações

**Feature Branch**: `002-perfil-e-avaliacoes`

**Created**: 2026-11-12

**Status**: Draft

**Input**: User description: "Quero que cada pessoa tenha um perfil com foto e avaliações, e que contratante e prestador possam se avaliar depois do serviço. Regras de negócio: (1) O contratante pode marcar um pedido \"em andamento\" como \"concluído\". (2) Só depois de concluído, o contratante e o prestador escolhido podem avaliar um ao outro, uma única vez por pedido cada um, com nota de 1 a 5 e comentário opcional de até 300 caracteres. A avaliação não pode ser editada nem apagada. (3) Quem não participou do pedido não pode avaliar. (4) Cada pessoa tem um perfil que mostra foto, nome, cidade, o tipo (contratante ou prestador), a nota média, o total de avaliações recebidas e as avaliações mais recentes com nota, comentário, nome de quem avaliou e data. Bairro, e-mail e telefone nunca aparecem no perfil. (5) O perfil próprio é acessível pelo início do app. O perfil da outra pessoa é acessível a partir de um pedido: o contratante abre o perfil do prestador nas candidaturas, e o prestador abre o perfil do contratante no pedido. (6) Perfil sem avaliações mostra \"Ainda sem avaliações\". (7) Depois de avaliar, o pedido mostra \"Você já avaliou\" e o botão some. (8) A foto de perfil é obrigatória no cadastro: a pessoa pode tirar uma foto na hora ou escolher uma da galeria, vê uma prévia antes de confirmar e pode trocar a foto depois no próprio perfil. (9) A foto aparece no perfil, na lista de candidaturas e no pedido, para as duas partes saberem com quem estão tratando. Sem foto, o app mostra a inicial do nome apenas enquanto a foto não é enviada. (10) Quem já tem conta e não tem foto é levado a adicionar uma na próxima vez que entrar. (11) Se o envio da foto falhar, o cadastro não é concluído e a mensagem explica o que fazer. O objetivo é ajudar quem escolhe com quem trabalhar a decidir com mais confiança e dar segurança de saber quem é a outra pessoa."

## Clarifications

### Session 2026-11-12

- Q: Em quais pedidos o prestador pode ver o perfil e a foto do contratante? → A: O perfil do
  contratante (nome, cidade, tipo, nota média, total e avaliações recentes) pode ser visto por
  qualquer prestador a partir de qualquer pedido que ele consiga ver, inclusive na lista da cidade.
  Somente a foto do contratante fica oculta aos prestadores até que um deles seja escolhido; a
  partir daí, só o prestador escolhido daquele pedido vê a foto. Esta resposta substitui a anterior
  da mesma sessão, que ocultava todo o perfil até a escolha.
- Q: A mesma regra vale para o contratante ao ver os prestadores? → A: Sim. O contratante vê nome,
  cidade, tipo, nota média, total e avaliações recentes de cada prestador candidato, mas a foto do
  prestador fica oculta até o contratante aceitar a candidatura; a partir daí, só o contratante
  daquele pedido vê a foto do prestador escolhido. A foto das duas partes só é revelada entre elas,
  depois do aceite.

## Relação com a funcionalidade 001

Esta funcionalidade depende de `specs/001-cadastro-e-pedidos` (contas, perfil imutável, pedidos,
candidaturas e aceite) e altera três pontos dela:

- **Estado concluído**: a 001 deixa conclusão e avaliação fora do escopo (FR-008). Aqui o pedido
  ganha o estado concluído, que só pode ser alcançado a partir de em andamento.
- **Dados visíveis a outras pessoas**: a 001 mantém o nome invisível a outros usuários (FR-023).
  Aqui foto, nome, cidade, tipo de perfil e avaliações passam a ser visíveis a outras pessoas nos
  pontos definidos em FR-012 a FR-014. Bairro e e-mail continuam privados, como na 001.
- **Cadastro**: a 001 exige e-mail, senha, nome, cidade, bairro e perfil (FR-001 e FR-004). Aqui a
  foto passa a ser também obrigatória.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Foto de perfil obrigatória (Priority: P1)

No cadastro, a pessoa tira uma foto na hora ou escolhe uma da galeria, vê uma prévia e confirma.
O cadastro só termina quando a foto é enviada. Quem já tinha conta sem foto é levado a adicionar uma
ao entrar. Depois, a pessoa pode trocar a foto no próprio perfil. A foto só aparece para a outra
parte depois do aceite da candidatura; antes disso, aparece a inicial do nome.

**Why this priority**: Saber quem é a outra pessoa é a base da confiança que a funcionalidade
busca. As avaliações e o perfil dependem de cada pessoa ter uma identidade visual.

**Independent Test**: Cadastrar uma conta com foto, confirmar que a foto aparece no perfil próprio
e no pedido em andamento visto pela outra parte, e que não aparece antes do aceite; simular falha
no envio e confirmar que o cadastro não termina.

**Acceptance Scenarios**:

1. **Given** que uma pessoa preenche o cadastro, **When** ela não escolheu uma foto, **Then** o
   cadastro não é concluído e ela é orientada a tirar ou escolher uma foto.
2. **Given** que a pessoa está escolhendo a foto, **When** ela tira uma foto ou escolhe uma da
   galeria, **Then** vê uma prévia e pode confirmar ou escolher outra antes de continuar.
3. **Given** que a pessoa confirmou a foto e os demais dados, **When** o envio da foto falha,
   **Then** o cadastro não é concluído, os dados preenchidos são mantidos e a mensagem explica que a
   foto não foi enviada e que ela pode tentar novamente.
4. **Given** uma conta existente sem foto, **When** a pessoa entra no aplicativo, **Then** ela é
   levada a adicionar uma foto antes de usar as demais telas.
5. **Given** uma pessoa com foto, **When** ela troca a foto no próprio perfil e confirma a prévia,
   **Then** a nova foto passa a aparecer no próprio perfil e nas candidaturas enviadas depois da
   troca; as candidaturas já enviadas, e os pedidos aceitos a partir delas, continuam mostrando a
   foto do momento da candidatura; para o contratante, a nova foto vale para os pedidos aceitos
   depois da troca, e os pedidos já aceitos continuam mostrando a foto do momento do aceite.
6. **Given** que um prestador se candidatou, **When** o contratante abre as candidaturas do pedido,
   **Then** vê o nome de cada prestador candidato com a inicial do nome no lugar da foto; depois de
   aceitar uma candidatura, passa a ver a foto do prestador escolhido.
7. **Given** que a foto de uma pessoa ainda não foi enviada, **When** outra tela precisaria
   mostrá-la, **Then** aparece a inicial do nome no lugar da foto.

---

### User Story 2 - Concluir o pedido e avaliar a outra parte (Priority: P2)

O contratante marca como concluído um pedido em andamento. A partir daí, o contratante e o
prestador escolhido podem avaliar um ao outro uma única vez, com nota de 1 a 5 e comentário
opcional. A avaliação é definitiva.

**Why this priority**: As avaliações formam a reputação que ajuda nas próximas escolhas, mas
dependem de pedidos concluídos com partes identificadas.

**Independent Test**: Com um pedido em andamento, marcar como concluído como contratante, avaliar
o prestador e, como prestador, avaliar o contratante; confirmar que nenhum dos dois consegue
avaliar de novo e que uma terceira pessoa não consegue avaliar.

**Acceptance Scenarios**:

1. **Given** um pedido em andamento, **When** o contratante que o publicou o marca como concluído,
   **Then** o pedido passa a concluído para as duas partes.
2. **Given** um pedido em andamento, **When** o prestador escolhido ou qualquer outra pessoa tenta
   marcá-lo como concluído, **Then** a ação é recusada e o estado não muda.
3. **Given** um pedido aberto, cancelado ou expirado, **When** alguém tenta marcá-lo como
   concluído, **Then** a ação é recusada.
4. **Given** um pedido concluído, **When** o contratante ou o prestador escolhido envia nota de 1 a
   5 e comentário opcional de até 300 caracteres, **Then** a avaliação é registrada para a outra
   parte, o botão de avaliar some e o pedido mostra "Você já avaliou".
5. **Given** que uma parte já avaliou o pedido, **When** ela tenta avaliar de novo, editar ou apagar
   a avaliação, **Then** a ação é recusada e a avaliação original permanece.
6. **Given** um pedido que ainda não foi concluído, **When** uma das partes tenta avaliar, **Then**
   a avaliação é recusada.
7. **Given** um pedido concluído, **When** uma pessoa que não é o contratante nem o prestador
   escolhido tenta avaliar, **Then** a avaliação é recusada.
8. **Given** o formulário de avaliação, **When** a pessoa envia sem nota, com nota fora de 1 a 5 ou
   com comentário acima de 300 caracteres, **Then** a avaliação não é registrada e o campo inválido
   é indicado com orientação para corrigir.
9. **Given** que uma parte avaliou e a outra ainda não, **When** a outra parte abre o pedido,
   **Then** ainda vê o botão de avaliar.

---

### User Story 3 - Consultar perfil e reputação (Priority: P3)

Cada pessoa tem um perfil com foto, nome, cidade, tipo de perfil, nota média, total de avaliações
recebidas e as avaliações mais recentes. A pessoa abre o próprio perfil pelo início do app. O
contratante abre o perfil de um prestador a partir das candidaturas, e o prestador abre o perfil do
contratante a partir do pedido.

**Why this priority**: Torna a reputação útil na hora de escolher, mas só tem conteúdo depois que
fotos e avaliações existem.

**Independent Test**: Com avaliações registradas, abrir o próprio perfil pelo início, abrir o
perfil de um prestador pelas candidaturas e confirmar média, total, avaliações recentes e a
ausência de bairro e e-mail.

**Acceptance Scenarios**:

1. **Given** uma pessoa autenticada, **When** ela abre o próprio perfil pelo início, **Then** vê
   foto, nome, cidade, tipo de perfil, nota média, total de avaliações recebidas e as avaliações
   mais recentes.
2. **Given** que há candidaturas a um pedido, **When** o contratante abre o perfil de um prestador
   candidato, **Then** vê nome, cidade, tipo de perfil, nota média, total e avaliações recentes,
   com a inicial do nome no lugar da foto.
3. **Given** que um prestador vê um pedido, inclusive na lista da cidade, **When** ele abre o perfil
   do contratante a partir do pedido, **Then** vê nome, cidade, tipo de perfil, nota média, total e
   avaliações recentes, com a inicial do nome no lugar da foto.
4. **Given** um perfil com avaliações, **When** ele é exibido, **Then** cada avaliação recente
   mostra nota, comentário (quando houver), nome de quem avaliou e data no formato dd/MM/aaaa.
5. **Given** um perfil sem avaliações recebidas, **When** ele é exibido, **Then** mostra "Ainda sem
   avaliações" no lugar da média e da lista.
6. **Given** qualquer perfil, **When** ele é exibido para qualquer pessoa, **Then** bairro, e-mail
   e telefone não aparecem.
7. **Given** uma pessoa autenticada sem vínculo com um pedido da outra, **When** os dados do perfil
   dela são lidos, **Then** só são obtidos nome, cidade, tipo de perfil, nota média, total e
   avaliações recentes; bairro, e-mail e telefone nunca são obtidos, a foto segue o FR-020 e o
   aplicativo não oferece esse acesso fora das candidaturas e do pedido.
8. **Given** que um prestador foi escolhido em um pedido, **When** ele abre o pedido ou o perfil do
   contratante a partir dele, **Then** vê também a foto do contratante; os demais prestadores
   continuam sem vê-la.
9. **Given** que o contratante aceitou a candidatura de um prestador, **When** abre o pedido ou o
   perfil do prestador escolhido, **Then** vê também a foto dele; a foto dos candidatos recusados
   continua oculta.

---

### Edge Cases

- Se a pessoa nega acesso à câmera ou à galeria, o aplicativo explica que a foto é necessária e
  como permitir o acesso, e oferece a outra origem (câmera ou galeria).
- Se a pessoa cancela a escolha da foto, volta ao cadastro com os dados preenchidos e sem foto.
- Se o arquivo escolhido não for uma imagem ou for grande demais, a foto é recusada e a pessoa é
  orientada a escolher outra.
- Se a troca de foto no perfil falhar, a foto anterior continua valendo e a pessoa pode tentar de
  novo.
- Se a conta sem foto entrar e a pessoa sair do aplicativo sem adicionar a foto, ela é levada de novo
  à tela de foto na próxima entrada.
- Se as duas partes avaliarem ao mesmo tempo, as duas avaliações são registradas, uma para cada.
- Se a mesma parte enviar a avaliação duas vezes seguidas (toque duplo, reenvio após falha), só
  uma avaliação é registrada.
- Se o envio da avaliação falhar, a nota e o comentário preenchidos permanecem e a pessoa pode
  tentar de novo.
- Se o contratante nunca marcar o pedido como concluído, nenhuma das partes pode avaliar.
- Um pedido concluído não pode ser editado, cancelado, reaberto nem receber candidaturas.
- A nota média não é exibida enquanto não houver avaliações; com avaliações, é exibida com uma casa
  decimal.
- Candidaturas feitas antes desta funcionalidade não têm foto; se forem aceitas, a outra parte vê a
  inicial do nome no lugar da foto.

## Requirements *(mandatory)*

### Functional Requirements

**Conclusão do pedido**

- **FR-001**: O sistema MUST permitir que somente o contratante que publicou um pedido em andamento
  o marque como concluído, e MUST recusar essa ação para outras pessoas e para pedidos em qualquer
  outro estado.
- **FR-002**: Um pedido concluído MUST NOT ser editado, cancelado, reaberto nem receber
  candidaturas.

**Avaliações**

- **FR-003**: O sistema MUST permitir que, em um pedido concluído, o contratante avalie o prestador
  escolhido e o prestador escolhido avalie o contratante, uma única vez por pedido cada um.
- **FR-004**: Cada avaliação MUST ter nota inteira de 1 a 5 e MAY ter comentário de até 300
  caracteres. O sistema MUST rejeitar nota ausente ou fora do intervalo e comentário acima do
  limite, indicando o campo e como corrigir.
- **FR-005**: O sistema MUST recusar avaliações de quem não é parte do pedido, avaliações de pedidos
  não concluídos e uma segunda avaliação da mesma parte no mesmo pedido, também nas regras de
  acesso aos dados.
- **FR-006**: Uma avaliação registrada MUST NOT ser editada nem apagada por ninguém.
- **FR-007**: Depois que uma parte avalia, o pedido MUST mostrar a ela "Você já avaliou" e MUST
  deixar de oferecer o botão de avaliar; a outra parte continua com o botão enquanto não avaliar.
- **FR-008**: O sistema MUST registrar a data da avaliação e MUST exibi-la no formato dd/MM/aaaa.

**Perfil**

- **FR-009**: Cada pessoa MUST ter um perfil que mostra foto, conforme o FR-020, nome, cidade, tipo
  de perfil (contratante ou prestador), nota média e total de avaliações recebidas, e as avaliações
  mais recentes com nota, comentário (quando houver), nome de quem avaliou e data. O nome exibido em
  cada avaliação MUST ser o de quem avaliou no momento em que a avaliação foi feita. A nota média
  MUST ser calculada como soma das notas ÷ total de avaliações, arredondada para uma casa decimal
  (meio para cima, ex.: 4,65 → 4,7) e exibida com vírgula.
- **FR-010**: O perfil MUST NOT mostrar bairro, e-mail ou telefone, para ninguém, incluindo a
  própria pessoa na visão pública.
- **FR-011**: Um perfil sem avaliações recebidas MUST mostrar "Ainda sem avaliações".
- **FR-012**: A pessoa MUST poder abrir o próprio perfil pelo início do aplicativo.
- **FR-013**: O contratante MUST poder abrir o perfil de cada prestador candidato a partir das
  candidaturas do seu pedido e ver nome, cidade, tipo de perfil, nota média, total e avaliações
  recentes. A foto do prestador MUST ficar oculta ao contratante, com a inicial do nome no lugar,
  e MUST ser exibida somente ao contratante que aceitou a candidatura dele (pedido em andamento ou
  concluído).
- **FR-014**: O prestador MUST poder abrir o perfil do contratante a partir de qualquer pedido que
  consiga ver, inclusive na lista de pedidos da cidade, e ver nome, cidade, tipo de perfil, nota
  média, total e avaliações recentes. A foto do contratante MUST ficar oculta aos prestadores, com a
  inicial do nome no lugar, e MUST ser exibida somente ao prestador escolhido daquele pedido (pedido
  em andamento ou concluído).
- **FR-015**: Qualquer pessoa autenticada MUST poder ler nome, cidade, tipo de perfil, nota média,
  total e avaliações recentes de outra pessoa. O aplicativo MUST oferecer esse acesso somente a
  partir das candidaturas e do pedido (FR-013 e FR-014). Bairro, e-mail e telefone MUST NOT ser
  acessíveis a outras pessoas em nenhum caso. A foto segue exclusivamente o FR-020.

**Foto de perfil**

- **FR-016**: O cadastro MUST exigir uma foto de perfil. A pessoa MUST poder tirar uma foto na hora
  ou escolher uma da galeria, e MUST ver uma prévia antes de confirmar.
- **FR-017**: Se o envio da foto falhar, o cadastro MUST NOT ser concluído, os dados preenchidos
  MUST ser mantidos e a mensagem MUST explicar que a foto não foi enviada e como tentar de novo.
- **FR-018**: Uma pessoa com conta existente e sem foto MUST ser levada a adicionar uma foto ao
  entrar, antes de acessar as demais telas.
- **FR-019**: A pessoa MUST poder trocar a própria foto no perfil, com prévia antes de confirmar;
  se a troca falhar, a foto anterior MUST continuar valendo. A nova foto MUST aparecer no próprio
  perfil e nas candidaturas enviadas depois da troca; as candidaturas já enviadas, e os pedidos
  aceitos a partir delas, MUST continuar mostrando a foto do momento da candidatura. Para o
  contratante, a nova foto vale para os pedidos aceitos depois da troca; pedidos já aceitos
  continuam mostrando a foto do momento do aceite.
- **FR-020**: A foto de uma pessoa MUST aparecer para ela mesma no próprio perfil. Para outra
  pessoa, a foto MUST aparecer somente quando as duas são o contratante e o prestador escolhido de um
  mesmo pedido em andamento ou concluído, no perfil, na candidatura aceita e no pedido (FR-013 e
  FR-014). Em todos os outros casos, e enquanto a foto não tiver sido enviada, o sistema MUST
  mostrar a inicial do nome no lugar dela. Se um pedido em andamento for cancelado, a foto da outra
  parte MUST deixar de ser visível naquele pedido e a inicial do nome MUST voltar a ser exibida.
- **FR-021**: O sistema MUST aceitar somente arquivos de imagem e MUST recusar arquivos acima de um
  tamanho máximo, orientando a pessoa a escolher outra foto.
- **FR-022**: Se o acesso à câmera ou à galeria for negado, o sistema MUST explicar como permitir o
  acesso e MUST oferecer a outra origem.

**Privacidade, mensagens e acessibilidade**

- **FR-024**: Todas as mensagens desta funcionalidade MUST estar em português, explicar o problema
  e indicar como continuar. As telas MUST seguir os requisitos de acessibilidade da 001 (FR-028),
  e a foto MUST ter rótulo acessível com o nome da pessoa.
- **FR-025**: As listas desta funcionalidade (avaliações recentes, candidaturas) MUST
  apresentar estados distintos de carregamento, vazio e falha, com nova tentativa na falha.

**Garantias nas regras de acesso aos dados e retenção**

- **FR-026**: As restrições de visibilidade da foto (FR-020) MUST ser impostas também nas regras de
  acesso aos dados, e não só na interface: uma leitura da foto fora dos casos do FR-020 MUST ser
  recusada.
- **FR-027**: A nota média, a soma das notas e o total de avaliações de uma pessoa MUST mudar somente
  junto com a criação de uma avaliação válida (FR-003 a FR-005), na mesma operação; qualquer outra
  alteração desses valores MUST ser recusada pelas regras de acesso aos dados.
- **FR-028**: As cópias da foto guardadas em um pedido MUST permanecer enquanto o pedido existir e
  MUST ser removidas junto com ele, conforme a retenção de pedidos encerrados da 001 (FR-025). As
  cópias de candidatos não escolhidos MUST NOT ser lidas por ninguém além do próprio dono.

### Key Entities

- **Conta** (da 001): ganha a foto de perfil. Os dados visíveis a outras pessoas são nome, cidade e
  tipo de perfil; a foto só é visível à outra parte depois do aceite; bairro e e-mail continuam
  privados.
- **Pedido** (da 001): ganha o estado concluído, alcançável somente a partir de em andamento.
- **Avaliação**: nota de 1 a 5 e comentário opcional que uma parte de um pedido concluído dá à
  outra. Guarda o pedido, quem avaliou, quem foi avaliado e a data. Uma por parte por pedido;
  imutável.
- **Resumo de reputação**: nota média e total de avaliações recebidas por uma pessoa, derivados das
  avaliações.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Ao menos 9 de 10 participantes conseguem concluir o cadastro com foto em até 4
  minutos, usando câmera ou galeria.
- **SC-002**: Ao menos 9 de 10 participantes conseguem avaliar a outra parte em até 1 minuto depois
  que o pedido é concluído.
- **SC-003**: Ao menos 9 de 10 contratantes conseguem abrir o perfil de um prestador candidato e
  dizer a nota média e o total de avaliações dele em até 30 segundos.
- **SC-004**: Em todos os cenários de validação, nenhuma pessoa consegue avaliar sem ser parte de
  um pedido concluído, avaliar duas vezes o mesmo pedido, nem editar ou apagar uma avaliação.
- **SC-005**: Em todos os cenários de validação, nenhum perfil exibe bairro, e-mail ou telefone.
- **SC-006**: Em todos os cenários de validação, nenhuma conta nova termina o cadastro sem foto, e
  toda conta antiga sem foto é levada a adicionar uma na primeira entrada.
- **SC-007**: A nota média exibida corresponde sempre à média das notas recebidas, com uma casa
  decimal, e o total corresponde à quantidade de avaliações recebidas.
- **SC-008**: Em todos os cenários de validação, a foto de uma pessoa só é exibida a outra quando
  as duas são contratante e prestador escolhido do mesmo pedido em andamento ou concluído.

## Assumptions

- O perfil mostra as 5 avaliações recebidas mais recentes, da mais nova para a mais antiga.
- A nota média é exibida com uma casa decimal (ex.: 4,7) e considera todas as avaliações recebidas.
- Não há prazo para avaliar depois da conclusão; a avaliação fica disponível enquanto o pedido
  existir.
- Cada avaliação fica visível no perfil de quem a recebeu assim que é registrada, sem esperar a
  avaliação da outra parte.
- O aplicativo não coleta telefone; a regra de não exibi-lo vale caso esse dado venha a existir.
- Não há moderação de fotos ou comentários nesta funcionalidade.
- O tamanho máximo da foto e os formatos aceitos serão definidos no plano, seguindo o padrão de
  aplicativos móveis.
- Pedidos concluídos seguem a regra de retenção de pedidos encerrados da 001 (FR-025); as
  avaliações são mantidas no perfil de quem as recebeu mesmo após o pedido ser eliminado.
- Contratar outro pedido com a mesma pessoa gera uma nova avaliação independente.
- A exclusão de conta está fora do escopo desta funcionalidade.
