# Pesquisa técnica: cadastro e pedidos locais

## Decisões

### Flutter e Dart

- **Decisão**: usar Flutter stable e Dart null-safe, mantendo `sdk: ^3.13.4` definido no repositório. Resolver a versão exata de Flutter/plugins em `flutter pub get` antes da implementação.
- **Racional**: corresponde à restrição do projeto e evita reduzir a faixa atual do SDK.
- **Alternativas consideradas**: fixar imediatamente um número de release do Flutter. Não escolhido porque o ambiente local não foi validado e a compatibilidade dos plugins precisa ser resolvida em conjunto.
- **Referência**: [ciclo de releases do Flutter](https://docs.flutter.dev/release/whats-new).

### Firebase Authentication e Cloud Firestore

- **Decisão**: `firebase_core`, `firebase_auth` e `cloud_firestore`; login por e-mail/senha e armazenamento de perfil, pedidos, candidaturas e categorias no Firestore.
- **Racional**: satisfaz a opção de arquitetura indicada pelo usuário e não requer backend próprio. FlutterFire requer configuração nativa por plataforma; credenciais e dados privados não devem ser publicados em consultas abertas.
- **Alternativas consideradas**: login/SQLite local (a alternativa de protótipo indicada pelo usuário), não escolhida para este plano porque o caminho principal solicitado usa Firebase compartilhado entre contratantes e prestadores.
- **Referências oficiais**: [configuração Firebase para Flutter](https://firebase.google.com/docs/flutter/setup), [autenticação por senha](https://firebase.google.com/docs/auth/flutter/password-auth), [regras e consultas Firestore](https://firebase.google.com/docs/firestore/security/rules-query), [regras por campo](https://firebase.google.com/docs/firestore/security/rules-fields), [transações](https://firebase.google.com/docs/firestore/manage-data/transactions).

### Dados pessoais e autorização

- **Decisão**: separar dados públicos de perfil/pedido do contato; guardar o contato num documento privado por conta e permitir sua leitura somente ao autor do pedido e ao prestador escolhido, depois do aceite.
- **Racional**: regras Firestore são aplicadas no documento inteiro e não podem ocultar seletivamente um campo. Regras também não filtram resultados: a consulta deve carregar restrições compatíveis com as regras.
- **Aceite exclusivo**: atualizar o pedido e a candidatura escolhida em transação; a regra de estado permite apenas uma associação. As outras candidaturas tornam-se recusadas conforme o contrato de dados, sem depender de Cloud Functions.
- **Alternativas consideradas**: pôr e-mail/telefone dentro do perfil/pedido e ocultá-lo só na interface (inseguro); função de backend para seleção (contraria ausência de backend próprio).
- **Referências oficiais**: [regras de campos](https://firebase.google.com/docs/firestore/security/rules-fields), [regras e consultas](https://firebase.google.com/docs/firestore/security/rules-query), [transações](https://firebase.google.com/docs/firestore/manage-data/transactions), [getAfter em regras](https://firebase.google.com/docs/firestore/security/rules-conditions).

### Expiração sem servidor

- **Decisão**: calcular disponibilidade a partir da data de validade e filtrar pedidos cuja validade ainda inclui o dia atual; validar novamente ao candidatar-se/aceitar. Não usar tarefa agendada nem Cloud Functions.
- **Racional**: mantém a regra de expiração mesmo sem backend próprio. Um campo `status` pode continuar `open` no documento após a data; a disponibilidade efetiva é derivada e nenhum pedido expirado aparece ou recebe candidatura.
- **Limitação**: não haverá mutação automática do documento exatamente à meia-noite. A regra observável pela interface e pelas operações será imediata quando a data local vigente ultrapassar o fim do prazo.
- **Alternativas consideradas**: Cloud Function agendada, rejeitada por acrescentar backend e operação; atualização apenas no cliente, rejeitada porque não é autoridade para autorização.

### Provider e go_router

- **Decisão**: Provider para injeção de repositórios/estado de apresentação; go_router para rotas protegidas e redirecionamento conforme sessão/perfil.
- **Racional**: explicitamente solicitados. Provider atende ao padrão simples de consumo de estado documentado pelo Flutter; go_router é mantido pela equipe Flutter e oferece navegação declarativa.
- **Alternativas consideradas**: `ChangeNotifier`/`InheritedWidget` sem pacote para estado, e Navigator 1.0 para rotas. Essas alternativas aumentariam código manual ou não cobririam bem redirecionamentos declarativos; evitar instalar outros gerenciadores/roteadores em paralelo.
- **Referências**: [gerenciamento simples de estado no Flutter](https://docs.flutter.dev/data-and-backend/state-mgmt/simple), [go_router no pub.dev](https://pub.dev/packages/go_router), [Provider no pub.dev](https://pub.dev/packages/provider).

### Dependências e justificativa

| Pacote | Faixa pesquisada | Uso | Por que não usar somente Flutter/Dart |
|---|---:|---|---|
| `firebase_core` | `^5.0.0` | Inicializar Firebase por plataforma | SDK padrão não inicializa serviços Firebase. |
| `firebase_auth` | `^7.0.0` | Cadastro e sessão por e-mail/senha | Flutter não fornece autenticação hospedada e compartilhada. |
| `cloud_firestore` | `^7.0.0` | Persistir e consultar dados sincronizados | Armazenamento local não compartilha pedidos entre dispositivos. |
| `provider` | `^6.1.5+1` | Injeção de dependências e estado reativo simples | Foi solicitado para este plano; APIs nativas exigiriam mais boilerplate e não substituem o padrão de estado escolhido. |
| `go_router` | `^18.1.0` | Rotas declarativas e guardas de sessão/perfil | Navigator básico não oferece por si só as rotas declarativas/redirecionamentos desejados. |

As versões acima são as consultadas durante a pesquisa, não um bloqueio de versão. Antes da implementação, resolver compatibilidade com Flutter/Dart do ambiente e pedir confirmação do usuário antes de incluir os pacotes, conforme `AGENTS.md`.

## Verificação de escopo contra a spec

O plano cobre somente contas, pedidos, categorias definidas pelo produto, lista regional por cidade, filtro, candidatura, aceite, edição/cancelamento, prazo e contato protegido descritos em `spec.md`.

**Decisões técnicas que não são funcionalidades adicionais**: coleções/documentos separados para cumprir privacidade; regras Firestore; operação atômica de aceite; validade derivada sem job de servidor; estados de interface exigidos pela constituição e FR-012.

**Canal de contato definido**: FR-013 e FR-018 especificam o e-mail de acesso. Como regras Firestore não conseguem buscar autorizações em pedidos arbitrários para proteger um único caminho de contato global, o modelo mantém o contato global acessível apenas ao titular e grava cópias privadas por pedido nos caminhos documentados em `data-model.md` e `contracts/firestore-security.md`.

**Itens fora do escopo mantidos fora do plano**: chat interno, pagamentos, avaliações, conclusão do serviço, criação/edição de categorias, múltiplos perfis por conta e backend próprio.
