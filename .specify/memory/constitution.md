<!--
Sync Impact Report
Version change: unratified scaffold -> 1.0.0
Modified principles: none (initial ratification)
Added sections: BicoLocal core principles, project constraints, development workflow
Removed sections: none
Follow-up TODOs: confirm the original ratification date.
-->

# BicoLocal Constitution

## Core Principles

### I. Simplicidade e legibilidade
O código Dart MUST ser simples e legível. Widgets e funções MUST ter escopo pequeno e uma
responsabilidade clara. A organização por funcionalidade MUST seguir `lib/features/<nome>/`, com
`data`, `domain` e `presentation` quando essas camadas forem necessárias. Nomes do domínio MUST
estar em português; identificadores técnicos exigidos pelo Flutter MUST estar em inglês. Isso
reduz complexidade e mantém as regras do produto fáceis de localizar.

### II. Teste primeiro (INEGOCIÁVEL)
Para cada mudança de comportamento, o teste correspondente MUST ser escrito primeiro. A
implementação MUST começar somente depois de executar `flutter test` e observar a falha esperada;
depois da implementação, `flutter test` MUST passar. Testes MUST usar repositórios falsos e MUST
NOT acessar o Firebase real. Nenhuma entrega de código está concluída sem executar `flutter test`.

### III. Dependências justificadas
O projeto MUST preferir recursos já disponíveis no Flutter e Dart. Cada dependência nova MUST ser
justificada no plano com sua finalidade e motivo para não usar uma alternativa já disponível. O
plano MUST identificar as dependências antes de sua inclusão no `pubspec.yaml`.

### IV. Comunicação clara em português
Todo texto apresentado ao usuário MUST estar em português, com linguagem clara e uma ação ou
resultado compreensível. Mensagens de erro MUST explicar o problema e indicar como continuar,
quando houver uma ação possível. Datas MUST ser salvas em ISO 8601 e exibidas no formato
brasileiro `dd/MM/aaaa`.

### V. Privacidade e contato protegido
Dados pessoais MUST ser acessíveis somente para as finalidades necessárias ao serviço. O contato
de contratante e prestador MUST permanecer oculto entre as partes até o aceite de uma candidatura
pelo contratante; após o aceite, o contato MUST ficar visível apenas às partes daquele pedido.
Listas, telas e respostas de dados MUST respeitar essa regra de acesso.

## Restrições do projeto

O BicoLocal MUST ser desenvolvido como aplicativo móvel em Flutter estável com Dart e null
safety. A interface MUST priorizar uso em celular e apresentar estados de carregamento, vazio e
erro nas listas. Chamadas ao banco MUST passar por repositórios e MUST NOT ser feitas dentro de
widgets. Segredos, chaves e arquivos de configuração secretos MUST NOT ser adicionados ao Git.

## Fluxo de desenvolvimento e qualidade

As funcionalidades MUST seguir `specs/<feature>/spec.md`; trabalho fora da especificação MUST
ser excluído. As tarefas MUST ordenar os testes antes da implementação. Antes de declarar uma
entrega concluída, o agente MUST executar `flutter test` e `flutter analyze` e informar os
resultados. A inclusão de pacotes novos exige confirmação do usuário. `git push` exige confirmação
do usuário.

## Governance

Esta constituição rege decisões de produto e desenvolvimento do BicoLocal. Em caso de conflito,
seus princípios e a especificação da funcionalidade prevalecem sobre convenções locais menos
específicas. Alterações nesta constituição MUST atualizar sua versão, a data de alteração e o
relatório de impacto; alterações que removam ou redefinam princípios exigem versão MAJOR, novos
princípios ou expansão material exigem MINOR, e correções de redação ou esclarecimentos exigem
PATCH. Revisões de especificações, planos, tarefas e código MUST verificar conformidade com estes
princípios; divergências MUST ser corrigidas ou registradas como bloqueio antes da conclusão.

**Version**: 1.0.0 | **Ratified**: TODO(RATIFICATION_DATE): confirmar data original de adoção | **Last Amended**: 2026-10-19
