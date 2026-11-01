# Implementation Plan: Cadastro e pedidos locais

**Branch**: `001-cadastro-e-pedidos` | **Date**: 2026-10-19 | **Spec**: [spec.md](spec.md)

## Summary

Implementar cadastro e entrada com e-mail e senha, alternância de perfil, publicação, busca por cidade, filtro por categoria, candidatura e aceite, além de edição/cancelamento e proteção de contato. O aplicativo usará Firebase Authentication e Cloud Firestore, com acesso aos dados encapsulado por repositórios. Provider gerenciará estado e `go_router` a navegação. Testes de comportamento começarão por `flutter test` e usarão repositórios falsos, sem Firebase real.

**Decisão de escopo**: conforme FR-013/FR-018, o contato desta entrega é o e-mail usado no acesso à conta. Ele será armazenado separadamente dos dados públicos do perfil e pedido.

## Technical Context

**Language/Version**: Dart null-safe `^3.13.4`, conforme `pubspec.yaml`; Flutter stable compatível com essa restrição e com os plugins escolhidos.
**Primary Dependencies**: `firebase_core ^5.0.0` (inicialização Firebase); `firebase_auth ^7.0.0` (cadastro e autenticação e-mail/senha); `cloud_firestore ^7.0.0` (persistência e consultas); `provider ^6.1.5+1` (estado/injeção de dependências); `go_router ^18.1.0` (rotas e redirecionamento por sessão). `flutter_test` já é dependência de desenvolvimento. Justificativas e alternativas estão em [research.md](research.md). Validar compatibilidade com Flutter instalado antes de incluir pacotes.
**Storage**: Cloud Firestore; Firebase Authentication para credenciais. Sem backend próprio, Cloud Functions ou SQLite.
**Testing**: `flutter test`, testes unitários e de widget com repositórios falsos. `flutter analyze` antes de concluir a implementação. Não acessar Firebase real nesses testes.
**Target Platform**: Aplicativo móvel Android e iOS; confirmar requisitos mínimos nativos na resolução de pacotes. O Gradle atual herda `flutter.minSdkVersion`; verificar compatibilidade do Cloud Firestore selecionado.
**Project Type**: mobile-app
**Performance Goals**: Atender aos critérios SC-001 a SC-016 da spec; especialmente publicação em até 3 minutos e localização em até 1 minuto nas tarefas guiadas.
**Constraints**: Interface celular-first; textos em português; datas persistidas em ISO 8601 e exibidas em `dd/MM/aaaa`; datas de serviço interpretadas no fuso `America/Sao_Paulo`, com validade até o fim do dia civil; repositórios como única fronteira de banco; e-mail de acesso restrito após aceite; sem segredos no Git; testes escritos e executados antes da implementação de cada comportamento; nenhuma dependência nova além das listadas sem justificativa e confirmação.
**Scale/Scope**: MVP desta spec: contas com perfil único, pedidos locais por cidade, categorias definidas pelo produto, candidaturas, aceite único, edição/cancelamento e validade. Conclusão e avaliação não incluídas. A spec não define metas de volume; dimensionamento fica para revisão posterior.

## Constitution Check

| Princípio / regra | Verificação do plano |
|---|---|
| I. Simplicidade e legibilidade | Organização por funcionalidade em `lib/features/<nome>/{data,domain,presentation}`; widgets e funções pequenos; domínio em português e identificadores técnicos Flutter em inglês. |
| II. Teste primeiro (inegociável) | Cada comportamento terá teste primeiro; executar `flutter test` para observar falha e depois novamente para verificar; fakes substituem Firebase. Testes de integração com serviço real não fazem parte do fluxo. |
| III. Dependências justificadas | Cada pacote planejado está listado com finalidade e alternativa rejeitada em `research.md`; não incluir outro sem justificativa e confirmação. |
| IV. Comunicação em português e datas | Mensagens claras e acionáveis em português; armazenamento ISO 8601 e apresentação `dd/MM/aaaa`; estados de carregamento, vazio e erro previstos. |
| V. Privacidade | Contatos em documento privado separado, sem exposição em consultas de lista; acesso concedido apenas ao contratante e prestador aceito, validado também por regras do Firestore. |
| Restrições do projeto | Flutter mobile, Dart null safety; acesso ao Firestore só por repositórios; configuração sem segredos versionados; interface prioriza celular. |
| Fluxo e qualidade | Implementação deve seguir spec e tarefas com testes primeiro; rodar `flutter test` e `flutter analyze` antes da conclusão. |

**Gate antes da implementação**: conforme; canal de contato e limite temporal de validade estão definidos na spec. A seleção/inclusão dos pacotes ainda exige confirmação do usuário conforme `AGENTS.md`.

**Re-check após design**: aprovado, sem decisão funcional de contato ou prazo pendente. A autorização para incluir pacotes permanece necessária conforme `AGENTS.md`; não é uma ambiguidade de requisito.

## Project Structure

### Documentation (this feature)

```text
specs/001-cadastro-e-pedidos/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── firestore-security.md
└── tasks.md                 # próxima etapa: speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── main.dart
├── core/
│   ├── app.dart
│   ├── router.dart
│   └── firebase/
│       └── firebase_initializer.dart
└── features/
    ├── conta/
    │   ├── data/       # implementação dos repositórios de autenticação/perfil
    │   ├── domain/     # conta, perfil, contratos e casos de uso
    │   └── presentation/ # cadastro, entrada e estado
    ├── pedidos/
    │   ├── data/       # repositório Firestore de pedidos/categorias
    │   ├── domain/     # pedido, categoria, validade e contratos
    │   └── presentation/ # publicar, listar, filtrar, editar e cancelar
    └── candidaturas/
        ├── data/       # repositório Firestore e aceite atômico
        ├── domain/     # candidatura e regras de aceite
        └── presentation/ # candidatar, revisar e aceitar

test/
├── features/
│   ├── conta/
│   ├── pedidos/
│   └── candidaturas/
└── support/            # repositórios falsos e builders de teste
```

**Structure Decision**: aplicativo Flutter único, separado por funcionalidades. Widgets consomem estado/casos de uso e nunca chamam Firestore diretamente. As pastas de teste acompanham cada funcionalidade; `support` fornece fakes reutilizados.

## Complexity Tracking

Sem violações da constituição. Provider, go_router e os plugins Firebase foram escolhidos para atender aos requisitos explícitos de tecnologia e integração apresentados para este plano; suas alternativas são documentadas em `research.md`.
