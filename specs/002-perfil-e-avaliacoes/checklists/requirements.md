# Specification Quality Checklist: Perfil com foto e avaliações

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-11-12
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

## Requirement Completeness

- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Success criteria are technology-agnostic (no implementation details)
- [x] All acceptance scenarios are defined
- [x] Edge cases are identified
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

## Feature Readiness

- [x] All functional requirements have clear acceptance criteria
- [x] User scenarios cover primary flows
- [x] Feature meets measurable outcomes defined in Success Criteria
- [x] No implementation details leak into specification

## Notes

- FR-014 resolvido em 2026-11-12: qualquer prestador vê nome e avaliações do contratante a partir
  de um pedido; só a foto fica oculta até ele ser o prestador escolhido. A mesma regra vale para o
  contratante: vê nome e avaliações dos candidatos, mas a foto só depois de aceitar a candidatura.
- A spec altera três pontos da 001 (estado concluído, FR-008; nome visível a outros, FR-023; foto no
  cadastro, FR-001/FR-004). Ao planejar, atualizar a 001 ou registrar a precedência da 002.
- Tamanho máximo e formatos de foto ficaram para o plano (ver Assumptions).
- Revisão de 2026-11-12: FR-023 e o caso de borda "Conta excluída" removidos; exclusão de conta
  registrada como fora do escopo em Assumptions. A numeração dos FR foi mantida, sem renumerar
  FR-024 e FR-025.
- FR-015 reescrito: nome, cidade, tipo, nota média, total e avaliações recentes são legíveis por
  qualquer pessoa autenticada; o app só oferece o acesso pelas candidaturas e pelo pedido; bairro,
  e-mail e telefone nunca são acessíveis; a foto segue só o FR-020. Cenário 7 da História 3 ajustado.
- Cenário 5 da História 1: a nova foto vale para o perfil e para pedidos aceitos depois da troca;
  pedidos já aceitos mantêm a foto anterior. (substituída pela revisão de foto de 2026-11-12)
- SC-008 movido para depois de SC-007.
- Revisão de foto (2026-11-12): cenário 5 da História 1 e FR-019 reescritos — a nova foto vale
  para o próprio perfil e para candidaturas enviadas depois da troca; candidaturas já enviadas e os
  pedidos aceitos a partir delas mantêm a foto do momento da candidatura. Novo caso de borda:
  candidaturas anteriores à funcionalidade não têm foto e, aceitas, mostram a inicial. Coerente
  com research.md D4 (pendência resolvida). FR-019 e cenário 5 também cobrem o contratante: a nova
  foto vale para pedidos aceitos depois da troca; os já aceitos mantêm a foto do momento do aceite.
