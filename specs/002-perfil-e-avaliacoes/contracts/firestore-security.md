# Contrato de segurança do Firestore — 002

Complementa `specs/001-cadastro-e-pedidos/contracts/firestore-security.md`. Onde houver conflito,
este contrato prevalece (ver "Precedência sobre a 001" no [plan.md](../plan.md)). Os trechos são
o contrato que `firestore.rules` deve cumprir; a redação final das regras sai na implementação.

## Princípios

- Nada é liberado por padrão; `match /{document=**}` continua negando tudo.
- `allow get` e `allow list` ficam separados em `requests` e nas coleções novas.
- Toda garantia da spec que envolve permissão também é imposta aqui, não só no app. Em especial:
  visibilidade da foto (FR-020, FR-026) e reputação só alterável junto com uma avaliação válida
  (FR-027).

## Funções auxiliares novas

```text
function profilePath(uid)    = /databases/$(database)/documents/profiles/$(uid)
function privateFotoPath(uid) = /databases/$(database)/documents/users/$(uid)/private/foto
function fotoValida(data)    = data.imagem is bytes && data.imagem.size() > 0
                               && data.imagem.size() <= 204800
function ehParte(r)          = request.auth.uid == r.contratanteUid
                               || request.auth.uid == r.prestadorEscolhidoUid
function aceito(r)           = r.estado in ['em_andamento', 'concluido']
```

## `users/{uid}/private/foto`

| Operação | Regra |
|---|---|
| get | dono |
| list | negado |
| create, update | dono; chaves só `imagem`, `atualizadaEm`; `fotoValida`; `atualizadaEm == request.time` |
| delete | negado |

## `profiles/{uid}`

| Operação | Regra |
|---|---|
| get | qualquer pessoa autenticada |
| list | negado (o app só abre perfis por uid) |
| create | dono; chaves exatamente `nome`, `cidade`, `perfil`, `notaMedia`, `totalAvaliacoes`, `somaNotas`, `ultimaAvaliacaoId`; `nome`, `cidade`, `perfil` iguais a `getAfter(users/{uid})`; `totalAvaliacoes == 0`, `somaNotas == 0`, `notaMedia == 0`, `ultimaAvaliacaoId == null` |
| update (avaliação) | qualquer autenticado, alterando só `totalAvaliacoes`, `somaNotas`, `notaMedia`, `ultimaAvaliacaoId`, com `id = request.resource.data.ultimaAvaliacaoId`: `!exists(avaliacoes/{id})` e `existsAfter(avaliacoes/{id})`; `getAfter(avaliacoes/{id}).avaliadorUid == request.auth.uid`; `total == anterior + 1`; `soma == anterior + getAfter(avaliacoes/{id}).nota`; `math.abs(notaMedia - soma / total) < 0.001` |
| update (dados) | dono, alterando só `nome`, `cidade`, iguais a `getAfter(users/{uid})` |
| delete | negado |

`perfil` nunca muda (nenhum ramo de update o inclui). `totalAvaliacoes`, `somaNotas` e
`notaMedia` só aparecem no ramo "avaliação", que exige a criação de uma avaliação válida na mesma
operação (FR-027).

## `profiles/{avaliadoUid}/avaliacoes/{requestId}`

| Operação | Regra |
|---|---|
| get, list | qualquer pessoa autenticada |
| create | ver abaixo |
| update, delete | negado (avaliação imutável, FR-006) |

`create`, com `r = get(requests/{requestId}).data`:

- `r.estado == 'concluido'`;
- `(request.auth.uid == r.contratanteUid && avaliadoUid == r.prestadorEscolhidoUid)` ou
  `(request.auth.uid == r.prestadorEscolhidoUid && avaliadoUid == r.contratanteUid)`;
- chaves exatamente `avaliadorUid`, `avaliadorNome`, `nota`, `comentario`, `criadaEm`;
- `avaliadorUid == request.auth.uid`;
- `avaliadorNome == get(profiles/{request.auth.uid}).nome`;
- `nota is int && nota >= 1 && nota <= 5`;
- `comentario is string && comentario.size() <= 1200` — teto de segurança; o limite de 300
  caracteres visíveis (FR-004) é aplicado pelo app, que conta com o pacote `characters` do Flutter.
  A regra não conta caracteres visíveis, e um emoji composto vale vários em `size()`;
- `criadaEm == request.time`;
- `getAfter(profiles/{avaliadoUid}).ultimaAvaliacaoId == requestId` e
  `getAfter(profiles/{avaliadoUid}).totalAvaliacoes == get(profiles/{avaliadoUid}).totalAvaliacoes + 1`
  (a reputação muda na mesma operação atômica).

Uma avaliação por parte por pedido: o id é o `requestId`, e criar sobre documento existente é
`update`, que é negado.

## `requests/{requestId}` (alterações)

- **get**: o ramo do prestador escolhido passa de `estado == 'em_andamento'` para `aceito(r)`.
- **list**: idem, mantido como regra separada de `get`.
- **update — novo ramo "concluir"**: `isContractor(resource.data.contratanteUid)`;
  `resource.data.estado == 'em_andamento'`; `request.resource.data.estado == 'concluido'`;
  `affectedKeys().hasOnly(['estado', 'atualizadoEm'])`; `atualizadoEm == request.time`.
- **update — ramo de edição de campos (FR-029, prevalece sobre a 001)**: passa a exigir a nova
  função `mayEdit(resource.data)`, e não mais `mayManage`:

  ```text
  function mayEdit(data) = signedIn()
                           && data.contratanteUid == request.auth.uid
                           && ((data.estado == 'aberto' && validForToday(data))
                               || data.estado == 'em_andamento')
  ```

  Só o contratante dono edita, com o pedido aberto e válido ou em andamento. O prestador escolhido
  não edita campos em nenhum estado.
- **update — ramo de cancelamento**: continua com `mayManage(resource.data)`, que aceita o
  contratante (aberto válido ou em andamento) e o prestador escolhido (em andamento). O prestador
  escolhido continua podendo cancelar.
- **Imutabilidade**: nenhum ramo existente aceita `resource.data.estado == 'concluido'` (o ramo
  de edição exige `mayEdit` e o de cancelamento `mayManage`, que só aceitam `aberto` ou
  `em_andamento`; o aceite exige `aberto`).
- **Candidaturas**: `applications` create já exige `isOpenAndValid`, então pedidos concluídos não
  recebem candidaturas.

## `requests/{requestId}/applications/{providerUid}/private/foto` (novo)

Mesmo padrão de `applications/{providerUid}/private/contact`.

| Operação | Regra |
|---|---|
| get | `request.auth.uid == providerUid`, ou `aceito(r) && r.prestadorEscolhidoUid == providerUid && r.contratanteUid == request.auth.uid` |
| list | negado |
| create | `request.auth.uid == providerUid`; chaves só `imagem`, `copiadaEm`; `imagem == get(privateFotoPath(providerUid)).imagem`; `copiadaEm == request.time`; `getAfter(applications/{providerUid}).estado == 'pendente'` |
| update, delete | negado |

Candidato não escolhido: `r.prestadorEscolhidoUid != providerUid`, então o contratante nunca lê a foto
(FR-028). Pedido cancelado: `aceito(r)` é falso, então a leitura é recusada (FR-020).

## `requests/{requestId}/fotos/{contratanteUid}` (novo)

| Operação | Regra |
|---|---|
| get | `aceito(r) && ehParte(r) && contratanteUid == r.contratanteUid` |
| list | negado |
| create | `isContractor(contratanteUid)`; chaves só `imagem`, `copiadaEm`; `imagem == get(privateFotoPath(contratanteUid)).imagem`; `copiadaEm == request.time`; `getAfter(requests/{requestId}).estado == 'em_andamento'` |
| update, delete | negado |

Pedido cancelado: `aceito(r)` é falso, então a leitura é recusada (FR-020). Remoção das duas cópias
só pelo processo de retenção da 001, nunca por clientes (FR-028).

## Testes

`test/firestore_rules_002_test.dart` (estático, sem Firebase) confere, antes de cada mudança nas
regras: blocos novos presentes; `update, delete: if false` em avaliações e nas duas cópias de
foto; ausência de `allow list` em `profiles`; ramo "concluir" restrito a `em_andamento`; ramo de
edição com `mayEdit` (só o contratante) e de cancelamento com `mayManage`; leitura da
foto do candidato condicionada a `prestadorEscolhidoUid == providerUid`. A validação real é feita
pelo [quickstart.md](../quickstart.md) após o deploy.
