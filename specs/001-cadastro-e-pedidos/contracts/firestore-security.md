# Contrato de dados e acesso do Firestore

Este documento define o comportamento observável entre os repositórios do app e o Firebase. Não há API HTTP nem backend próprio. O formato detalhado das entidades está em [data-model.md](../data-model.md).

## Coleções

- `users/{uid}`: perfil básico. A pessoa autenticada pode criar/editar o próprio perfil respeitando validação e perfil permitido. Não inclui contato.
- `users/{uid}/private/contact`: e-mail da conta, legível somente pelo próprio titular.
- `categories/{categoryId}`: catálogo administrado pelo produto, somente leitura nesta funcionalidade.
- `requests/{requestId}`: pedido e estado operacional. Leituras da lista são limitadas a prestadores autenticados e pedidos abertos dentro da validade, em qualquer cidade selecionada; dados de contato não são gravados aqui.
- `requests/{requestId}/applications/{providerUid}`: candidatura única por prestador/pedido; somente o prestador dono cria a sua e o contratante do pedido revisa/aceita.
- `requests/{requestId}/applications/{providerUid}/private/contact`: e-mail do prestador, gravado por ele ao candidatar-se; legível pelo titular e, depois do aceite, pelas partes enquanto o pedido estiver em andamento.
- `requests/{requestId}/privateContacts/{contractorUid}`: cópia privada do e-mail do contratante, criada no aceite; legível pelas partes enquanto o pedido estiver em andamento.

## Regras de autorização obrigatórias

1. Rejeitar leituras/escritas sem autenticação.
2. Validar que publicação só é feita por conta de perfil `contratante`; candidatura somente por `prestador`.
3. Não confiar em restrições visuais do cliente: validar UID, perfil, campos permitidos, estado atual e datas nas regras e no domínio.
4. Antes do aceite, não devolver dado de contato em lista, perfil público ou documento do pedido.
5. Permitir que o titular leia o próprio contato. Contatos privados vinculados ao pedido só podem ser lidos quando `estado == em_andamento` e o leitor é `contratanteUid` ou `prestadorEscolhidoUid`; negar após cancelamento. A cópia do contratante é criada apenas pelo contratante autor durante o aceite e deve corresponder ao e-mail autenticado.
6. Fazer aceite como operação atômica condicionada a pedido `aberto`, candidatura `pendente` e pedido ainda dentro da validade; registrar apenas um `prestadorEscolhidoUid`.
7. Recusar candidaturas repetidas ao mesmo pedido, pedidos expirados/cancelados, e edição/cancelamento por pessoa sem autorização conforme FR-016 a FR-021.
8. Ao aceitar, persistir a candidatura escolhida como `aceita` e as demais como `recusada`, sem aceitar duas em concorrência.
9. Regras Firestore são por documento, não filtram resultados e não podem remover campos de documentos retornados. Por isso, manter contato fora de documentos consultados pela lista; incluir na consulta as mesmas restrições verificadas pelas regras.

## Consultas suportadas

- Pedidos abertos e válidos com cidade selecionada e filtro opcional por categoria.
- Pedidos do contratante autenticado para gerenciamento.
- Candidaturas do pedido para o contratante autor, e candidatura própria para o prestador.
- Nenhuma consulta ampla à coleção de contatos; e-mails privados são lidos por caminhos vinculados à conta ou ao pedido conhecido.

Consultas compostas podem exigir índices Firestore. Índices necessários serão documentados junto ao código de implementação; não são uma nova funcionalidade.

## Concorrência e expiração

O aceite é uma transação Firestore: se o pedido já tiver sido aceito, cancelado ou expirado, a operação falha e a interface mostra mensagem em português com orientação para atualizar a lista. Como não há servidor agendado, validade é calculada pelo limite do dia atual e aplicada nas consultas e mutações.

## Critérios de aceitação do contrato

- Uma conta não lê contatos antes do aceite.
- Após aceite, somente as duas contas vinculadas leem o contato daquele pedido.
- Uma tentativa concorrente de aceitar segunda candidatura falha e não altera o prestador escolhido.
- Consultas de lista incluem somente pedidos da cidade selecionada que estejam abertos e dentro da validade; não incluem pedidos cancelados ou em andamento.
- Tentativas com papel ou UID incorretos são negadas mesmo se forem feitas fora da interface.
