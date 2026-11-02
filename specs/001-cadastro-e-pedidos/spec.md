# Feature Specification: Cadastro e pedidos locais

**Feature Branch**: `001-cadastro-e-pedidos`

**Created**: 2026-10-19

**Status**: Draft

**Input**: User description: "Quero um aplicativo que substitua a busca desorganizada por trabalhadores em grupos de mensagens por uma plataforma centralizada. Existem dois perfis: contratante (quem precisa de um serviço rápido) e prestador (quem busca bicos na região). Nesta primeira funcionalidade, uma pessoa pode se cadastrar e entrar no aplicativo escolhendo seu perfil, informando nome, cidade e bairro. O contratante pode publicar um pedido de serviço com título, categoria, descrição, local, data desejada e valor combinado. O prestador pode ver a lista de pedidos abertos da sua região e filtrá-los por categoria. O objetivo é que o contratante encontre ajuda mais rápido e que o prestador encontre serviços perto de si."

## Clarifications

### Session 2026-10-19

- Q: O pedido terá prazo de validade? → A: Sim; cada pedido expira, e a duração ainda será definida.
- Q: Quem pode editar ou cancelar o pedido? → A: O contratante e o prestador.
- Q: Como um prestador deve se tornar autorizado a editar ou cancelar um pedido? → A: Após ser escolhido pelo contratante; incluir candidatura e aceite nesta entrega.
- Q: Como deve ser definido o prazo de validade de cada pedido? → A: O contratante escolhe a data de validade ao publicar, no máximo até a data desejada.
- Q: Qual contato é revelado após o aceite? → A: O e-mail de acesso, somente ao contratante autor e ao prestador escolhido enquanto o pedido estiver em andamento; após cancelamento, o contato deixa de ser exibido.
- Q: Quais dados do perfil aparecem a outros usuários? → A: Nome, e-mail e bairro do perfil permanecem privados; na lista, o prestador vê apenas os dados do serviço e a cidade necessária à busca regional.
- Q: Como tratar dados ao excluir conta e quanto tempo manter pedidos encerrados? → A: Excluir os dados pessoais do perfil e contato com a conta; remover identificadores pessoais dos pedidos encerrados e eliminá-los após 12 meses.

### Session 2026-11-02

- Q: A pessoa pode trocar de perfil depois do cadastro? → A: Não. O perfil (contratante ou prestador) é escolhido uma única vez, no cadastro, e não pode ser alterado depois. Esta decisão substitui a alternância de perfil prevista anteriormente.

## User Scenarios & Testing

### User Story 1 - Publicar e encontrar pedidos locais (Priority: P1)

Uma pessoa cria uma conta com e-mail e senha, escolhe uma única vez se será contratante ou
prestador e informa nome, cidade e bairro. O perfil escolhido no cadastro não pode ser alterado depois. O contratante publica um pedido com título, categoria, descrição, local,
data desejada e valor. O prestador consulta pedidos abertos na região do seu perfil e encontra
as informações necessárias para decidir se aquele serviço lhe interessa.

**Why this priority**: Esse fluxo entrega o valor central da plataforma: organizar a oferta de
serviços e permitir que prestadores encontrem oportunidades locais.

**Independent Test**: Cadastrar um contratante e um prestador, publicar um pedido como
contratante e confirmar que o prestador consegue encontrá-lo na lista de pedidos abertos.

**Acceptance Scenarios**:

1. **Given** que uma pessoa ainda não tem conta, **When** ela informa e-mail, senha, nome, cidade,
   bairro e escolhe um perfil válido, **Then** sua conta é criada com o perfil e os dados informados,
   e a tela de cadastro avisa, antes da confirmação, que o perfil não poderá ser alterado depois.
2. **Given** que existe uma conta ativa, **When** a pessoa informa e-mail e senha corretos,
   **Then** ela entra na conta associada ao seu perfil.
3. **Given** que uma pessoa autenticada tem o perfil escolhido no cadastro, **When** ela usa o aplicativo,
   **Then** nenhuma opção de troca de perfil é oferecida e as ações disponíveis são somente as do seu perfil.
4. **Given** que uma pessoa autenticada tenta alterar o perfil da própria conta por qualquer meio,
   **When** a alteração é enviada, **Then** ela é recusada e o perfil escolhido no cadastro permanece.
5. **Given** que um contratante está autenticado, **When** informa título, categoria, descrição,
   local, data desejada, data de validade e valor válido, **Then** o pedido é publicado como aberto
   e aparece na lista de pedidos da região correspondente.
6. **Given** que um prestador está autenticado, **When** consulta pedidos abertos da sua região,
   **Then** cada resultado mostra título, categoria, descrição, local, data desejada e valor.
7. **Given** que um pedido está aberto, **When** o prestador o consulta, **Then** os dados de
   contato pessoal das partes não são exibidos antes do aceite de uma candidatura.
8. **Given** que uma pessoa tenta publicar um pedido com campo obrigatório ausente ou valor não
   positivo, **When** envia o formulário, **Then** o pedido não é publicado e os campos inválidos
   são indicados em português com orientação para correção.
9. **Given** que a data de validade é anterior à data atual ou posterior à data desejada do serviço,
   **When** o contratante tenta publicar o pedido, **Then** a publicação é recusada e a regra de
   datas é informada em português.

---

### User Story 2 - Entrar e filtrar oportunidades (Priority: P3)

O prestador entra na conta existente e filtra os pedidos abertos disponíveis por uma categoria,
para reduzir a lista às oportunidades que correspondem ao tipo de serviço que procura.

**Why this priority**: A filtragem torna a busca mais rápida quando há pedidos de diferentes tipos,
após o fluxo essencial de publicação e descoberta estar disponível.

**Independent Test**: Com pedidos abertos de pelo menos duas categorias, entrar como prestador,
selecionar uma categoria e confirmar que só aparecem pedidos daquela categoria.

**Acceptance Scenarios**:

1. **Given** que há pedidos abertos em mais de uma categoria, **When** o prestador seleciona uma
   categoria, **Then** a lista mostra somente pedidos abertos daquela categoria na região aplicável.
2. **Given** que nenhum pedido aberto corresponde à categoria selecionada, **When** o filtro é
   aplicado, **Then** a lista vazia informa que não há pedidos para essa categoria e permite limpar
   o filtro.
3. **Given** que o prestador aplicou um filtro, **When** limpa a seleção, **Then** volta a ver
   todos os pedidos abertos da região aplicável.

---

### User Story 3 - Candidatar-se e gerenciar um pedido (Priority: P2)

Um prestador pode se candidatar a um pedido aberto. O contratante escolhe uma candidatura e,
depois do aceite, o contratante e o prestador escolhido podem editar ou cancelar aquele pedido.

**Why this priority**: O aceite associa um prestador ao pedido e permite que somente as partes
envolvidas gerenciem o serviço e vejam os dados de contato protegidos.

**Independent Test**: Criar um pedido, candidatar-se como prestador, aceitar a candidatura como
contratante e verificar que ambas as partes podem editar e cancelar o pedido, enquanto outro
prestador não pode.

**Acceptance Scenarios**:

1. **Given** que existe um pedido aberto, **When** um prestador se candidata, **Then** o
   contratante pode ver a candidatura associada ao pedido.
2. **Given** que há candidaturas a um pedido aberto, **When** o contratante aceita uma delas,
   **Then** o pedido passa a em andamento e o prestador escolhido fica associado ao pedido.
3. **Given** que a candidatura foi aceita, **When** o contratante que publicou ou o prestador
   escolhido edita ou cancela o pedido, **Then** a ação é aplicada e refletida para as partes.
4. **Given** que a candidatura de um prestador não foi aceita, **When** ele tenta editar ou cancelar
   o pedido, **Then** a ação é recusada e o pedido não é alterado.
5. **Given** que uma candidatura foi aceita, **When** qualquer uma das partes consulta os dados do
   pedido, **Then** os contatos ficam visíveis somente para o contratante e o prestador escolhido.
6. **Given** que um pedido está aberto antes do aceite, **When** o contratante que o publicou o
   edita ou cancela, **Then** a alteração é aplicada ou o pedido deixa de estar aberto.
7. **Given** que o pedido está em andamento após o aceite, **When** o contratante que o publicou ou
   o prestador escolhido o edita ou cancela, **Then** a alteração é aplicada ou o pedido é cancelado.
8. **Given** que o prazo de validade do pedido terminou, **When** um prestador consulta os pedidos
   abertos, **Then** o pedido expirado não aparece e não pode receber nova candidatura.
9. **Given** que há candidaturas de mais de um prestador, **When** o contratante aceita uma,
   **Then** somente essa candidatura é aceita e as demais são recusadas.
10. **Given** que um prestador já se candidatou a um pedido, **When** tenta se candidatar novamente,
   **Then** o sistema mantém uma única candidatura desse prestador para esse pedido.
11. **Given** que um pedido está expirado ou cancelado, **When** uma das partes tenta editá-lo,
    **Then** a alteração é recusada e o estado do pedido não muda.

### Edge Cases

- Quando o prazo de validade termina, o pedido deixa de aparecer entre os pedidos abertos.
- Uma edição inválida não altera os dados publicados; a pessoa recebe indicação dos campos que
  precisa corrigir.

- Se o e-mail informado no cadastro já estiver associado a uma conta, a conta não é duplicada e a
  pessoa recebe uma mensagem em português para entrar ou usar outro e-mail.
- Se e-mail, senha, nome, cidade ou bairro estiver ausente, o cadastro não é concluído e cada
  campo obrigatório ausente é indicado.
- Se o prestador não tiver pedidos abertos disponíveis, a lista informa que está vazia e não
  apresenta dados de pedidos encerrados.
- Se a categoria escolhida não tiver resultados, a lista informa isso e permite remover o filtro.
- Se os dados obrigatórios do pedido estiverem ausentes, ou o valor for zero ou negativo, o pedido
  não é publicado e a pessoa recebe orientação para corrigir os dados.
- Se a data de validade estiver no passado ou for posterior à data desejada do serviço, o pedido
  não é publicado e a pessoa é orientada a escolher uma data permitida.
- Se a data desejada for anterior à data atual, o pedido não é publicado e a pessoa é orientada a
  escolher uma data futura ou a data atual.
- Se ocorrer falha ao carregar pedidos, a lista informa que não foi possível carregá-los e oferece
  uma ação para tentar novamente.
- Se ocorrer falha temporária ao publicar ou alterar pedido, os dados preenchidos permanecem no
  formulário e a pessoa pode tentar novamente sem criar uma operação duplicada.
- Se uma pessoa tentar uma ação que o perfil ou vínculo com o pedido não permite, a ação é recusada,
  nenhum dado protegido é retornado e a interface informa como voltar à área segura.
- Antes de excluir a conta, a pessoa recebe aviso de que seus pedidos abertos/em andamento serão
  cancelados e suas candidaturas removidas; a exclusão só ocorre após confirmação.
- Um pedido expirado ou cancelado não pode receber candidaturas nem ser aceito.
- Um prestador cuja candidatura não foi aceita não pode editar nem cancelar o pedido.
- Um prestador não pode enviar mais de uma candidatura para o mesmo pedido.

## Requirements

### Functional Requirements

- **FR-001**: O sistema MUST permitir criar uma conta com e-mail, senha, nome, cidade, bairro e
  perfil de contratante ou prestador, escolhido uma única vez no cadastro.
- **FR-002**: O sistema MUST rejeitar cadastro com e-mail já associado a uma conta e orientar a
  pessoa a entrar ou informar outro e-mail.
- **FR-003**: O sistema MUST permitir que uma pessoa autenticada entre usando o e-mail e a senha
  associados à sua conta.
- **FR-004**: O sistema MUST exigir e-mail, senha, nome, cidade, bairro e perfil no cadastro e
  informar em português cada dado obrigatório que estiver ausente ou inválido.
- **FR-005**: O sistema MUST permitir que apenas uma pessoa com perfil de contratante publique
  pedidos de serviço.
- **FR-006**: Cada pedido MUST conter título, categoria, descrição, local, data desejada, data de
  validade e valor.
- **FR-007**: O sistema MUST exigir todos os dados do pedido e rejeitar valor igual ou inferior a
  zero e data anterior à data atual antes da publicação.
- **FR-008**: Um pedido publicado MUST permanecer aberto até uma candidatura ser aceita pelo contratante,
  cancelado ou expirado; após o aceite, MUST passar ao estado em andamento. A conclusão e a
  avaliação do pedido estão fora do escopo desta funcionalidade.
- **FR-009**: O sistema MUST permitir que apenas uma pessoa com perfil de prestador consulte pedidos abertos e selecione a cidade de busca. A busca inicial MUST usar a cidade do perfil.
- **FR-010**: Cada item da lista MUST apresentar título, categoria, descrição, local, data desejada
  e valor do pedido.
- **FR-011**: A lista MUST permitir filtrar pedidos abertos por uma categoria e remover o filtro.
- **FR-012**: A lista MUST apresentar estados distintos de carregamento, ausência de resultados e
  falha, com mensagens em português e uma ação de nova tentativa quando houver falha.
- **FR-013**: O sistema MUST ocultar os e-mails de acesso das partes antes do aceite de uma
  candidatura e MUST limitar sua exibição posterior às partes daquele pedido.
- **FR-014**: A busca inicial MUST incluir pedidos abertos da cidade do prestador, independentemente do bairro. O prestador MUST poder selecionar outra cidade para buscar pedidos abertos válidos nela.

- **FR-015**: Ao publicar um pedido, o contratante MUST escolher sua data de validade. Essa data
  MUST ser hoje ou futura e MUST ser igual ou anterior à data desejada do serviço. O pedido MUST
  permanecer disponível durante toda a data de validade e MUST expirar às 00:00 do dia seguinte,
  considerando o fuso `America/Sao_Paulo`; a partir desse instante, MUST deixar de aparecer como
  aberto.
- **FR-016**: O sistema MUST permitir que o contratante que publicou um pedido e um prestador
  cuja candidatura foi aceita o editem e cancelem. Antes do aceite, somente o contratante que
  publicou o pedido pode editá-lo ou cancelá-lo.
- **FR-017**: O sistema MUST permitir que um prestador se candidate a um pedido aberto e que o
  contratante aceite uma candidatura; cada pedido MUST ter no máximo um prestador escolhido.
- **FR-018**: Depois do aceite, o sistema MUST exibir o e-mail de acesso de cada parte somente ao
  contratante que publicou o pedido e ao prestador escolhido.
- **FR-019**: O sistema MUST impedir candidaturas e aceite em pedidos expirados ou cancelados.
- **FR-020**: O sistema MUST impedir edição e cancelamento de pedidos expirados ou já cancelados.
- **FR-021**: O sistema MUST permitir no máximo uma candidatura por prestador para cada pedido.
- **FR-022**: Quando o contratante aceita uma candidatura, o sistema MUST recusar as demais
  candidaturas daquele pedido.
- **FR-023**: O sistema MUST manter nome, e-mail e bairro do perfil invisíveis a outros usuários; a lista regional MUST exibir somente os dados definidos em FR-010 e a cidade usada para a busca.
- **FR-024**: O sistema MUST deixar de exibir contatos quando um pedido em andamento for cancelado; pedidos abertos expirados não podem revelar contato.
- **FR-025**: Pedidos encerrados MUST ter os identificadores pessoais removidos e MUST ser eliminados após 12 meses do encerramento.
- **FR-026**: O sistema MUST proteger dados pessoais durante armazenamento e transmissão por criptografia e MUST NOT incluí-los em mensagens de erro ou registros de diagnóstico. Tentativas sem autorização MUST ser recusadas sem retornar dados protegidos.
- **FR-027**: Cada campo obrigatório inválido MUST receber mensagem em português junto ao campo, descrevendo o erro e como corrigi-lo. Falhas de entrada MUST informar que as credenciais não foram aceitas e permitir nova tentativa; falhas temporárias MUST oferecer nova tentativa quando aplicável. Se uma publicação ou alteração falhar, o sistema MUST manter os dados já preenchidos e oferecer nova tentativa sem duplicar a operação.
- **FR-028**: Nas telas móveis, o conteúdo MUST caber sem rolagem horizontal a partir de 320 dp de largura; alvos de toque MUST medir pelo menos 48×48 dp; texto comum MUST ter contraste mínimo de 4,5:1 e texto grande contraste mínimo de 3:1; com ampliação de texto de 200%, os controles e conteúdos MUST continuar disponíveis sem perda de informação; elementos informativos MUST ter rótulo acessível.
- **FR-029**: O perfil da conta (contratante ou prestador) MUST ser definido no cadastro e MUST ser imutável depois. O sistema MUST NOT oferecer opção de troca de perfil e MUST recusar, também nas regras de acesso aos dados, qualquer tentativa de alterar o perfil de uma conta existente.
- **FR-030**: Ao escolher o perfil no cadastro, o sistema MUST explicar que o contratante pode publicar pedidos e o prestador pode consultar pedidos da cidade do perfil e candidatar-se, e MUST avisar que a escolha não poderá ser alterada depois. A interface MUST indicar as ações disponíveis para o perfil da conta e para cada pedido associado à pessoa.
- **FR-031**: Quando uma ação for recusada por falta de permissão, o sistema MUST informar em português que a pessoa não tem autorização e indicar uma próxima ação segura, como voltar à lista ou à tela inicial, sem revelar dados protegidos.
- **FR-032**: Antes de excluir a conta, o sistema MUST informar que pedidos abertos ou em andamento publicados pela pessoa ou associados a ela como prestador escolhido serão cancelados e que suas candidaturas serão removidas. Após confirmação, MUST cancelar esses pedidos, remover as candidaturas da pessoa e excluir os dados pessoais do perfil e do contato. Pedidos cancelados MUST ser anonimizados e eliminados 12 meses após o cancelamento.

### Key Entities

- **Conta**: pessoa cadastrada, com e-mail de acesso, nome, perfil escolhido no cadastro (imutável), cidade e bairro.
- **Pedido**: serviço publicado por um contratante, com título, categoria, descrição, local, data
  desejada, data de validade, valor e estado.
- **Candidatura**: manifestação de interesse de um prestador em realizar um pedido aberto; pode
  ser aceita ou recusada pelo contratante para associar um único prestador escolhido ao pedido.
- **Categoria**: tipo de serviço usado para classificar e filtrar pedidos.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Em uma avaliação com tarefas guiadas apenas pela interface, ao menos 9 de 10
  participantes conseguem criar uma conta válida em até 3 minutos.
- **SC-002**: Ao menos 9 de 10 participantes no papel de contratante conseguem publicar um pedido
  válido em até 3 minutos após entrar na conta.
- **SC-003**: Ao menos 9 de 10 participantes no papel de prestador conseguem localizar um pedido
  aberto da categoria escolhida em até 1 minuto, quando existe resultado disponível.
- **SC-004**: Em todos os cenários de validação, campos obrigatórios ausentes, e-mail duplicado e
  valores ou datas inválidos impedem a operação correspondente e recebem mensagem clara em
  português.
- **SC-005**: Em todos os cenários de privacidade, nenhum dado de contato pessoal aparece em
  pedido ou perfil antes do aceite de candidatura.
- **SC-006**: Em todos os cenários de edição e cancelamento, somente o contratante que publicou o
  pedido e o prestador cuja candidatura foi aceita conseguem executar essas ações.
- **SC-007**: Em todos os cenários de candidatura aceita, os contatos do pedido ficam visíveis
  somente para as duas partes escolhidas.
- **SC-008**: Em todos os cenários de validade, pedidos expirados não aparecem na lista de pedidos
  abertos e não aceitam candidaturas.
- **SC-009**: A avaliação guiada deve incluir 10 participantes sem ajuda do moderador durante as tarefas; um cronômetro começa quando cada tarefa é apresentada e para quando a ação é concluída com sucesso. Registrar conclusão e duração para cadastro, publicação e localização.
- **SC-010**: Em testes de interface a 320 dp, não há rolagem horizontal; alvos de toque têm ao menos 48×48 dp; com escala de texto de 200%, controles continuam utilizáveis e rótulos acessíveis são anunciados.
- **SC-011**: Em todos os testes de permissão, nome, e-mail e bairro de perfil não aparecem para outra conta; pedido cancelado não permite ler contato; dados pessoais não aparecem em erros ou registros de diagnóstico; tentativa sem permissão recebe orientação em português sem dados protegidos.
- **SC-012**: Em teste de exclusão com pedidos abertos e em andamento e candidaturas, a tela exibe o aviso antes da confirmação; após confirmar, os pedidos são cancelados, as candidaturas da pessoa são removidas, perfil e contato são excluídos, e os pedidos são anonimizados. Após 12 meses, os pedidos anonimizados são eliminados.
- **SC-013**: Para cada campo obrigatório inválido, a mensagem aparece junto ao campo e indica a correção; credenciais inválidas não autenticam e mostram orientação para nova tentativa. Se salvar pedido falhar, os campos permanecem preenchidos e uma nova tentativa não cria duplicata.
- **SC-014**: Em verificação de segurança, os dados pessoais persistidos estão criptografados, conexões sem criptografia são recusadas, e inspeção de mensagens de erro e registros de diagnóstico não encontra dados pessoais.
- **SC-015**: Em revisão automatizada de telas, texto comum atende contraste 4,5:1, texto grande atende 3:1, alvos de toque medem ao menos 48×48 dp e a interface funciona a 320 dp e com escala de texto de 200%.
- **SC-016**: Em teste de cada perfil, a tela de cadastro descreve as permissões de cada perfil e avisa que a escolha é definitiva; depois de entrar, a interface mostra apenas as ações do perfil da conta e não oferece troca; uma tentativa de alterar o perfil é recusada; uma ação não permitida mostra orientação para voltar à área segura.

## Assumptions

- O cadastro usa e-mail e senha, e um e-mail identifica uma única conta.
- Cada conta tem um único perfil, contratante ou prestador, escolhido no cadastro e imutável. Quem precisar atuar no outro papel deve criar outra conta com outro e-mail.
- As categorias disponíveis são definidas pelo produto e compartilhadas por contratantes e
  prestadores; criar ou editar categorias está fora do escopo.
- O valor do pedido é expresso em reais e deve ser maior que zero.
- A data desejada pode ser hoje ou uma data futura; datas são apresentadas no formato brasileiro.
- O contratante escolhe uma data de validade igual ou anterior à data desejada e igual ou posterior
  à data atual; datas de serviço representam dias civis no fuso `America/Sao_Paulo`, são salvas em
  ISO 8601 e exibidas como `dd/MM/aaaa`. O pedido fica disponível durante todo o dia de validade e
  expira às 00:00 do dia civil seguinte nesse fuso.
- Esta entrega cobre cadastro, entrada na conta, publicação, descoberta, candidatura e aceite de
  pedidos. Conclusão e avaliação pertencem a funcionalidades posteriores.
- O contato pessoal usado nesta entrega é o e-mail de acesso da conta. Ele fica protegido conforme
  a constituição; antes do aceite permanece oculto e, após o aceite, fica visível somente ao
  contratante autor e ao prestador escolhido daquele pedido.
- O sistema identifica falhas de carregamento e permite nova tentativa sem perder o filtro
  escolhido.
- Cada prestador pode manter somente uma candidatura por pedido; ao aceitar uma, o contratante
  encerra as demais candidaturas daquele pedido.
- Nome, e-mail e bairro do perfil não são públicos; a cidade só é usada para busca e os dados do pedido listados em FR-010 são exibidos ao prestador.
- O contato fica acessível somente enquanto o pedido aceito estiver em andamento; cancelamento revoga a exibição. A exclusão da conta cancela pedidos abertos ou em andamento associados à pessoa, remove suas candidaturas e apaga perfil e contato; pedidos encerrados são anonimizados e retidos por no máximo 12 meses.
