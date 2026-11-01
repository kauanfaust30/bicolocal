# Modelo de dados: cadastro e pedidos locais

O esquema separa documentos de leitura pública dos dados pessoais. Todas as datas persistidas usam timestamp ISO 8601/UTC; a interface apresenta `dd/MM/aaaa`. A implementação deve validar entradas no domínio e repetir as restrições relevantes nas regras do Firestore.

## Conta

Representa uma identidade autenticada e seu perfil de uso.

| Campo | Tipo | Regra |
|---|---|---|
| `uid` | string | Mesmo identificador da conta autenticada; único. |
| `nome` | string | Obrigatório, não vazio após trim. |
| `perfil` | enum string | `contratante` ou `prestador`; um perfil ativo por vez, alterável pela própria pessoa autenticada. |
| `cidade` | string | Obrigatória; normalizada para comparação regional. |
| `bairro` | string | Obrigatório. |
| `criadoEm` | timestamp | Definido na criação. |

**Persistência**: `users/{uid}` contém apenas os campos necessários ao perfil. `users/{uid}/private/contact` contém o e-mail e só pode ser lido pelo titular. Como regras Firestore não podem consultar pedidos arbitrários para autorizar esse caminho, o aceite também cria uma cópia privada do e-mail do contratante em `requests/{requestId}/privateContacts/{contratanteUid}`. O e-mail do prestador fica em `requests/{requestId}/applications/{prestadorUid}/private/contact`, escrito pelo próprio prestador ao candidatar-se. Essas cópias só podem ser lidas pelo titular correspondente e pelas duas partes enquanto o pedido está em andamento; após cancelamento, as regras negam acesso.

Ao excluir a conta, cancelar pedidos abertos/em andamento relacionados ao usuário, remover suas candidaturas, apagar perfil/contato e anonimizar pedidos encerrados; remover pedidos anonimizados após 12 meses.

## Pedido

| Campo | Tipo | Regra |
|---|---|---|
| `id` | string | ID do documento. |
| `contratanteUid` | string | Conta de perfil contratante que publicou; imutável. |
| `titulo` | string | Obrigatório e não vazio. |
| `categoriaId` | string | Categoria definida pelo produto. |
| `descricao` | string | Obrigatória e não vazia. |
| `cidade` | string | Local do serviço; usada para filtrar pela cidade selecionada. |
| `bairro` / `local` | string | Local informado para o pedido; obrigatório. |
| `dataDesejada` / `dataDesejadaDia` | string `aaaa-MM-dd` / timestamp UTC à meia-noite | Hoje ou data futura; o campo timestamp permite validar o dia civil nas regras. |
| `validadeAte` / `validadeAteDia` | string `aaaa-MM-dd` / timestamp UTC à meia-noite | Data escolhida pelo contratante, hoje ou futura, igual ou anterior a `dataDesejada`; disponível até o fim desse dia civil em São Paulo. |
| `valorCentavos` | integer | Maior que zero, em reais sem erro de ponto flutuante. |
| `estado` | enum string | `aberto`, `em_andamento` ou `cancelado`; expiração é derivada da data de validade. |
| `prestadorEscolhidoUid` | string/null | Nulo antes do aceite; único prestador aceito após. |
| `criadoEm`, `atualizadoEm` | timestamp | ISO 8601/UTC. |

Contato pessoal não pertence ao documento do pedido. Pedidos abertos acessíveis a prestadores não retornam subdocumentos privados. Categorias ficam em `categories/{categoryId}`, legíveis pelo app e sem fluxo de edição nesta funcionalidade.

## Candidatura

Persistida em `requests/{requestId}/applications/{providerUid}` para impedir mais de uma candidatura do mesmo prestador ao pedido.

| Campo | Tipo | Regra |
|---|---|---|
| `prestadorUid` | string | Mesmo UID do documento e de perfil prestador. |
| `estado` | enum string | `pendente`, `aceita` ou `recusada`. |
| `criadaEm`, `atualizadaEm` | timestamp | ISO 8601/UTC. |

Não há mensagem de candidatura ou outros campos não previstos na spec.

O documento privado `requests/{requestId}/applications/{prestadorUid}/private/contact` contém somente o e-mail autenticado do prestador e não é legível pelo contratante antes do aceite.

## Estados e transições

```text
Pedido: aberto -> em_andamento (aceite único)
Pedido: aberto -> cancelado (contratante)
Pedido: em_andamento -> cancelado (contratante ou prestador escolhido)
Pedido: aberto + validade vencida -> expirado (estado efetivo calculado, sem job)

Candidatura: pendente -> aceita (contratante, junto com pedido aberto -> em_andamento)
Candidatura: pendente -> recusada (contratante recusa ou outra candidatura é aceita)
```

Depois de expirar ou cancelar, impedir candidatura, aceite, edição e novo cancelamento. Aceite deve ser transacional para que duas candidaturas concorrentes não associem dois prestadores. Ao aceitar, recusar as outras candidaturas pendentes do pedido; o pedido continua sendo a autoridade de exclusividade.

## Consultas essenciais

- Prestador: `estado == aberto`, `cidade == cidade selecionada`, `validadeAte >= limite do dia corrente`; a cidade inicial vem do perfil e `categoriaId` é opcional. Ordenação estável por data desejada/criação.
- Contratante: pedidos onde `contratanteUid == uid`, incluindo seus estados para gerenciamento.
- Candidaturas: subcoleção do pedido, consultável pelo contratante autor; o prestador acessa sua própria candidatura.
- Contato do contratante: leitura da cópia privada vinculada ao pedido somente durante o andamento e pelas duas partes; a cópia global continua legível apenas pelo titular.
- Contato do prestador: leitura do documento privado da candidatura somente pelo titular e, após o aceite, pelas partes enquanto o pedido estiver em andamento.

As consultas precisam incluir restrições compatíveis com as regras Firestore; regras não atuam como filtros de resultados.
