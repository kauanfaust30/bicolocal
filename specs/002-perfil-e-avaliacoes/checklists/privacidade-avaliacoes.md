# Privacidade da foto e integridade das avaliações: Checklist de perfil com foto e avaliações

**Purpose**: Revisar se os requisitos de privacidade da foto de perfil e de integridade das avaliações e da reputação estão completos, claros, consistentes e mensuráveis.
**Created**: 2026-11-12
**Feature**: [spec.md](../spec.md)

**Note**: Esta checklist personalizada foi gerada pelo comando `$speckit-checklist` com base no contexto e nos requisitos da feature.
**Review Ownership**: Artefato de revisão da qualidade dos requisitos, sob responsabilidade do revisor. Marque `[x]` somente quando o critério de qualidade do requisito tiver sido revisado e considerado satisfeito.
**Marker Semantics**: `[x]` significa que o requisito foi revisado e satisfaz o critério de qualidade; não significa que a implementação foi concluída.

## Privacidade da foto — completude

- [x] CHK001 Os requisitos definem, para cada lugar onde a foto pode aparecer (perfil próprio, perfil de outra pessoa, lista de candidaturas, candidatura aceita, pedido), quem pode vê-la e em qual estado do pedido? [Completude, Spec §FR-013, §FR-014, §FR-020]
- [x] CHK002 A spec define se a foto continua visível entre as partes quando um pedido em andamento é cancelado? [Gap, Spec §FR-020; 001 §FR-024]
- [x] CHK003 Os requisitos estabelecem por quanto tempo as cópias da foto guardadas no pedido são mantidas, inclusive as de candidatos recusados, e se seguem a retenção de 12 meses de pedidos encerrados da 001? [Gap, Constituição §V; 001 §FR-025]
- [x] CHK004 A spec define o que a foto deve representar (por exemplo, o rosto da pessoa), já que o objetivo declarado é "saber quem é a outra pessoa"? [Gap, Spec §Input, §FR-016]
- [x] CHK005 O tamanho máximo e os formatos de imagem aceitos estão quantificados nos requisitos, ou a delegação ao plano está registrada como suposição aceita? [Clareza, Spec §FR-021, §Assumptions]
- [x] CHK006 Os requisitos definem o que acontece com a foto e suas cópias quando a conta é excluída, ou a exclusão fora do escopo está explicitamente ligada à foto? [Suposição, Spec §Assumptions]

## Privacidade da foto — clareza e consistência

- [x] CHK007 O FR-009 ("perfil que mostra foto") está consistente com FR-013, FR-014 e FR-020, que ocultam a foto da outra pessoa antes do aceite? [Conflito, Spec §FR-009, §FR-020]
- [x] CHK008 A regra 9 da descrição original (foto "na lista de candidaturas") está registrada como substituída pelos esclarecimentos de 2026-11-12, para não gerar leitura conflitante? [Consistência, Spec §Input, §Clarifications]
- [x] CHK009 A expressão "incluindo a própria pessoa na visão pública" no FR-010 está definida de forma inequívoca? [Ambiguidade, Spec §FR-010]
- [x] CHK010 "Pedidos aceitos a partir delas" e "momento da candidatura" / "momento do aceite" no FR-019 estão definidos de forma que se possa determinar qual versão da foto cada pedido mostra? [Clareza, Spec §FR-019, Cenário H1-5]
- [x] CHK011 A inicial do nome usada no lugar da foto oculta está definida da mesma forma que a inicial usada enquanto a foto não foi enviada, inclusive no rótulo acessível? [Consistência, Spec §FR-020, §FR-024]
- [x] CHK012 Os requisitos de foto estão impostos também nas regras de acesso aos dados, e não só na interface, como a spec faz para avaliações em FR-005? [Gap, Spec §FR-020; Constituição §V]

## Privacidade da foto — critérios de aceitação e cenários

- [x] CHK013 O SC-008 permite verificar objetivamente que candidatos recusados nunca tiveram a foto exibida ao contratante? [Mensurabilidade, Spec §SC-008, Cenário H3-9]
- [x] CHK014 Os cenários cobrem a visão de um terceiro (outro prestador ou outro contratante) sobre a foto das duas partes depois do aceite? [Cobertura, Spec Cenário H3-8]
- [x] CHK015 Os cenários de falha cobrem permissão negada, cancelamento da escolha, arquivo inválido e falha de envio tanto no cadastro quanto em Adicionar foto e na troca de foto? [Cobertura, Exceção, Spec §FR-017, §FR-019, §FR-021, §FR-022, §Edge Cases]

## Integridade das avaliações — completude

- [x] CHK016 A spec exige que nota média, total e soma só possam mudar como consequência de uma avaliação válida, e nunca por alteração direta? [Gap, Spec §FR-005, §SC-007]
- [x] CHK017 Os requisitos definem se "nome de quem avaliou" é o nome no momento da avaliação ou o nome atual da pessoa? [Ambiguidade, Spec §FR-009]
- [x] CHK018 O número de "avaliações mais recentes" exibidas está quantificado em requisito, e não só em suposição? [Clareza, Spec §FR-009, §Assumptions]
- [x] CHK019 A spec define se é possível ver todas as avaliações de uma pessoa ou apenas as mais recentes? [Gap, Spec §FR-009, §FR-015]
- [x] CHK020 A ausência de recurso quando o contratante nunca conclui o pedido (o prestador fica sem poder avaliar) está registrada como decisão intencional? [Gap, Spec §Edge Cases, §FR-001]

## Integridade das avaliações — clareza

- [x] CHK021 A regra de arredondamento da nota média com uma casa decimal está definida (por exemplo, 4,65 → 4,7)? [Clareza, Spec §SC-007, §Assumptions]
- [x] CHK022 O limite de 300 caracteres define como contar caracteres (acentos, emojis) e se comentário só com espaços conta como vazio? [Clareza, Spec §FR-004]
- [x] CHK023 A data da avaliação define o fuso usado para o dia exibido, coerente com `America/Sao_Paulo` da 001? [Clareza, Spec §FR-008; 001 §FR-015]

## Integridade das avaliações — consistência e cenários

- [x] CHK024 As garantias de "uma por parte por pedido", "só após concluído", "só entre as partes" e "imutável" estão todas impostas também nas regras de acesso aos dados? [Consistência, Spec §FR-003, §FR-005, §FR-006]
- [x] CHK025 A imutabilidade do pedido concluído (FR-002) está consistente com a 001, que permitia edição e cancelamento a pessoas autorizadas? [Consistência, Spec §FR-002; Plano §Precedência sobre a 001]
- [x] CHK026 A suposição de que cada avaliação fica visível assim que registrada (sem esperar a da outra parte) considera o risco de retaliação e está aceita explicitamente? [Suposição, Spec §Assumptions]
- [x] CHK027 Os cenários cobrem envio repetido, envio simultâneo das duas partes e falha de envio com preservação da nota e do comentário? [Cobertura, Recuperação, Spec §Edge Cases]
- [x] CHK028 O SC-004 e o SC-007 permitem verificar objetivamente a integridade da reputação após várias avaliações de pedidos diferentes? [Mensurabilidade, Spec §SC-004, §SC-007]

## Notes

- Marque itens `[x]` somente após revisão confirmar que o critério de qualidade do requisito foi satisfeito.
- Deixe itens sem marcação se ainda exigirem esclarecimento, correção ou avaliação do revisor.
- `$speckit-implement` lê o estado das checklists como referência e não deve alterar seus marcadores.
- `checklists/requirements.md` tem ciclo de manutenção próprio por `$speckit-specify` e `$speckit-clarify`.
- Esta checklist avalia a redação e cobertura dos requisitos; não verifica o comportamento do código.
- Avaliação de 2026-11-12, a pedido do revisor, contra a spec com FR-009, FR-020 e FR-026 a FR-028
  atualizados: 16 itens resolvidos e 12 em aberto (CHK004, CHK006, CHK008, CHK009, CHK011, CHK014,
  CHK015, CHK018, CHK019, CHK022, CHK023, CHK026). Nenhum item duplicado: CHK009 trata da redação
  do FR-010 e CHK012 da imposição da foto nas regras; CHK001/CHK014 e CHK018/CHK019 são próximos,
  mas avaliam aspectos diferentes (completude x cenário; quantidade x alcance).
- Reavaliação de 2026-11-12 (após C1, C2, A1, U1, I2, I3 e F1): CHK018, CHK019, CHK022 e CHK023
  resolvidos pelos novos textos de FR-004, FR-008 e FR-009. Seguem em aberto 8 itens: CHK004,
  CHK006, CHK008, CHK009, CHK011, CHK014, CHK015 e CHK026.
- Reavaliação final de 2026-11-12: CHK004 e CHK006 (Assumptions), CHK008 (Clarifications: regra 9
  substituída pelo FR-020), CHK009 (FR-010), CHK011 (FR-024), CHK014 (cenário 10 da História 3),
  CHK015 (FR-018) e CHK026 (Assumptions) resolvidos. Todos os 28 itens estão resolvidos.
