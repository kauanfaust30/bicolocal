# Contrato de segurança do Firestore — 002

Complementa `specs/001-cadastro-e-pedidos/contracts/firestore-security.md`. Onde houver conflito,
este contrato prevalece (ver "Precedência sobre a 001" no [plan.md](../plan.md)). Os trechos são
o contrato que `firestore.rules` deve cumprir; a redação final das regras sai na implementação.

## Princípios

- Nada é liberado por padrão; `match /{document=**}` continua negando tudo.
- `allow get` e `allow list` ficam separados em `requests` e nas coleções novas.
- Toda garantia da spec que envolve permissão também é imposta aqui, não só no app.

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

`perfil` nunca muda (nenhum ramo de update o inclui).

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
- `comentario is string && comentario.size() <= 300`;
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
- **Imutabilidade**: nenhum ramo existente aceita `resource.data.estado == 'concluido'` (os ramos
  de edição e cancelamento exigem `mayManage`, que só aceita `aberto` ou `em_andamento`; o aceite
  exige `aberto`).
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

Candidato recusado: `r.prestadorEscolhidoUid != providerUid`, então o contratante nunca lê a foto.

## `requests/{requestId}/fotos/{contratanteUid}` (novo)

| Operação | Regra |
|---|---|
| get | `aceito(r) && ehParte(r) && contratanteUid == r.contratanteUid` |
| list | negado |
| create | `isContractor(contratanteUid)`; chaves só `imagem`, `copiadaEm`; `imagem == get(privateFotoPath(contratanteUid)).imagem`; `copiadaEm == request.time`; `getAfter(requests/{requestId}).estado == 'em_andamento'` |
| update, delete | negado |

## Testes

`test/firestore_rules_002_test.dart` (estático, sem Firebase) confere, antes de cada mudança nas
regras: blocos novos presentes; `update, delete: if false` em avaliações e nas duas cópias de
foto; ausência de `allow list` em `profiles`; ramo "concluir" restrito a `em_andamento`; leitura da
foto do candidato condicionada a `prestadorEscolhidoUid == providerUid`. A validação real é feita
pelo [quickstart.md](../quickstart.md) após o deploy.
