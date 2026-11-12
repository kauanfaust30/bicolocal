# Data Model: Perfil com foto e avaliações

Datas salvas como `Timestamp` do servidor (ISO 8601 ao serializar); exibidas em dd/MM/aaaa.

## PerfilPublico — `profiles/{uid}`

Legível por qualquer pessoa autenticada. Nunca contém foto, bairro nem e-mail.

| Campo | Tipo | Regras |
|---|---|---|
| `nome` | string | igual a `users/{uid}.nome` |
| `cidade` | string | igual a `users/{uid}.cidade` |
| `perfil` | string | `contratante` ou `prestador`, igual a `users/{uid}.perfil`, imutável |
| `totalAvaliacoes` | int | ≥ 0; começa em 0; +1 por avaliação recebida |
| `somaNotas` | int | ≥ 0; começa em 0; + nota por avaliação recebida |
| `notaMedia` | number | 0 sem avaliações; senão `somaNotas / totalAvaliacoes` (tolerância 0,001) |
| `ultimaAvaliacaoId` | string ou null | null na criação; `requestId` da última avaliação recebida |

- **Criação**: no cadastro (batch com `users`) ou em Adicionar foto, para contas da 001.
- **Atualização**: só pela transação de avaliação (D6). `nome`/`cidade` acompanham `users/{uid}`
  se a 001 vier a permitir editá-los (não há tela para isso hoje).
- **Integridade (FR-027)**: `notaMedia`, `somaNotas` e `totalAvaliacoes` só mudam no ramo de
  avaliação das regras; nenhum outro ramo de `update` os inclui.
- **Exibição (FR-009)**: calculada de `somaNotas` e `totalAvaliacoes` com aritmética inteira,
  arredondada para uma casa decimal meio para cima (`(somaNotas * 20 + totalAvaliacoes) ~/
  (totalAvaliacoes * 2)` décimos; ex.: 93/20 = 4,65 → 4,7), exibida com vírgula. O campo
  `notaMedia` guardado não é usado para exibir, evitando erro de ponto flutuante;
  `totalAvaliacoes == 0` → "Ainda sem
  avaliações".

## Avaliacao — `profiles/{avaliadoUid}/avaliacoes/{requestId}`

O id é o `requestId`: no máximo uma avaliação por parte por pedido. Só `create`.

| Campo | Tipo | Regras |
|---|---|---|
| `avaliadorUid` | string | = `request.auth.uid`; contratante ou prestador escolhido do pedido |
| `avaliadorNome` | string | = `profiles/{avaliadorUid}.nome` no momento da avaliação; não é atualizado depois (FR-009) |
| `nota` | int | 1 a 5 |
| `comentario` | string | 0 a 300 caracteres; vazio quando não informado |
| `criadaEm` | timestamp | = `request.time` |

- **Pré-condições**: `requests/{requestId}.estado == 'concluido'`; avaliado é a outra parte.
- **Listagem**: 5 mais recentes, `orderBy('criadaEm', descending)`, `limit(5)` (índice de campo
  único, automático).

## FotoPrivada — `users/{uid}/private/foto`

| Campo | Tipo | Regras |
|---|---|---|
| `imagem` | bytes | JPEG ~300 px; 1 a 204 800 bytes |
| `atualizadaEm` | timestamp | = `request.time` |

Leitura e escrita só pelo dono. `update` permitido (trocar foto); sem `delete`.

## Cópias da foto no pedido (research D4)

Cada parte copia a própria foto; a regra confere que `imagem` é idêntica a
`users/{uid}/private/foto.imagem`. Só `create`, sem `update` nem `delete`. Por isso, trocar a foto
privada não altera cópias já feitas: para o prestador, a nova foto vale para candidaturas enviadas
depois; para o contratante, para pedidos aceitos depois (FR-019).
Candidaturas anteriores à 002 não têm cópia; aceitas, mostram a inicial do nome.

- **Cancelamento (FR-020)**: as duas cópias só são legíveis com o pedido em andamento ou concluído;
  se o pedido em andamento for cancelado, a leitura passa a ser recusada e o app volta a mostrar a
  inicial.
- **Retenção (FR-028)**: as cópias ficam enquanto o pedido existir e são removidas com ele, pelo
  mesmo processo de retenção de pedidos encerrados da 001 (12 meses). Como o Firestore não apaga
  subcoleções junto com o documento, esse processo precisa apagar também `fotos/*` e
  `applications/*/private/foto`. Clientes nunca apagam cópias.
- **Recusados (FR-028)**: a cópia de um candidato não escolhido só é legível pelo próprio dono.

Campos das duas cópias:

| Campo | Tipo | Regras |
|---|---|---|
| `imagem` | bytes | idêntica à foto privada do dono no momento da cópia |
| `copiadaEm` | timestamp | = `request.time` |

### FotoDoCandidato — `requests/{requestId}/applications/{providerUid}/private/foto`

- **Quando**: gravada pelo prestador ao se candidatar, na transação da candidatura (com a
  candidatura ainda `pendente`).
- **Leitura**: o próprio prestador; o contratante do pedido só com o pedido em andamento ou
  concluído e `prestadorEscolhidoUid == providerUid`. Candidatos recusados nunca têm a foto lida.

### FotoDoContratante — `requests/{requestId}/fotos/{contratanteUid}`

- **Quando**: gravada pelo contratante na transação do aceite (pedido passa a em andamento).
- **Leitura**: o contratante e o prestador escolhido, com o pedido em andamento ou concluído.

### Qual foto aparece

| Quem vê | Onde | Fonte |
|---|---|---|
| A própria pessoa | Meu perfil | `users/{uid}/private/foto` |
| Contratante | Candidatura aceita, pedido e perfil do prestador escolhido (a partir do pedido) | `applications/{prestador}/private/foto` |
| Prestador escolhido | Pedido e perfil do contratante (a partir do pedido) | `fotos/{contratante}` |
| Qualquer outro caso | — | inicial do nome |

## Pedido — `requests/{requestId}` (da 001)

Novo valor de `estado`: `concluido`.

```text
aberto ──aceite──▶ em_andamento ──concluir (contratante)──▶ concluido (imutável)
  │                    │
  └─cancelar/expirar   └─cancelar
```

- Concluir altera apenas `estado` e `atualizadoEm`.
- Concluído: sem edição, cancelamento, reabertura nem candidaturas (já garantido pelas regras da
  001, que exigem `aberto` ou `em_andamento`).

## Conta (domínio, da 001)

Ganha `temFoto` (bool, derivado): verdadeiro quando existem `users/{uid}/private/foto` e
`profiles/{uid}`. Falso leva o redirect para `/foto`.

## Entidades de domínio (Dart)

- `PerfilPublico(uid, nome, cidade, perfil, notaMedia, totalAvaliacoes)` — `semAvaliacoes` quando
  total é 0.
- `Avaliacao(pedidoId, avaliadorUid, avaliadorNome, avaliadoUid, nota, comentario, criadaEm)`.
- `AvaliacaoValidator.validar(nota, comentario)` → erros por campo (nota ausente ou fora de 1–5;
  comentário > 300).
- `FotoPerfil(bytes)` e `FotoErro` (`semPermissao(origem)`, `naoImagem`, `grandeDemais`,
  `envioFalhou`, `cancelada`).
- `EstadoPedido.concluido` e `PedidoPermissions.podeConcluir`, `podeAvaliar`, `podeVerFoto`.
