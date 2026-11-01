# Usabilidade e segurança dos dados pessoais: Checklist de cadastro e pedidos locais

**Purpose**: Revisar se os requisitos de usabilidade móvel e proteção de dados pessoais estão completos, claros, consistentes e mensuráveis.
**Created**: 2026-10-19
**Feature**: [spec.md](../spec.md)

**Note**: Esta checklist personalizada foi gerada pelo comando `$speckit-checklist` com base no contexto e nos requisitos da feature.
**Review Ownership**: Artefato de revisão da qualidade dos requisitos, sob responsabilidade do revisor. Marque `[x]` somente quando o critério de qualidade do requisito tiver sido revisado e considerado satisfeito.
**Marker Semantics**: `[x]` significa que o requisito foi revisado e satisfaz o critério de qualidade; não significa que a implementação foi concluída.

## Completude dos requisitos de usabilidade

- [x] CHK001 Os requisitos definem como a pessoa escolhe entre contratante e prestador e como entende as permissões do perfil escolhido? [Completude, Spec §FR-001, §FR-005, §FR-009]
- [x] CHK002 Os requisitos de cadastro e publicação especificam como cada campo ausente ou inválido é associado a uma orientação acionável em português? [Completude, Spec §FR-004, §FR-007, §SC-004]
- [x] CHK003 Os requisitos de lista definem conteúdo e comportamento de carregamento, lista vazia, filtro sem resultados, erro e nova tentativa? [Completude, Spec §FR-010–FR-012]
- [x] CHK004 Os requisitos de usabilidade móvel especificam critérios verificáveis para legibilidade, acessibilidade e uso em telas pequenas? [Gap, Constituição §Restrições do projeto]
- [x] CHK005 Os critérios de sucesso definem como a avaliação guiada será conduzida e como os tempos de cadastro, publicação e busca serão medidos? [Clareza, Spec §SC-001–SC-003]

## Clareza e cobertura de privacidade

- [x] CHK006 A spec define qual dado ou canal de contato será revelado após o aceite, considerando que o plano assume e-mail provisoriamente? [Ambiguidade, Spec §FR-013, §FR-018; Plano §Summary]
- [x] CHK007 Os requisitos identificam precisamente quais duas contas podem acessar o contato e como esse acesso se comporta após cancelamento ou expiração do pedido? [Clareza, Cobertura, Spec §FR-013, §FR-018–FR-020]
- [x] CHK008 Os requisitos distinguem os dados do perfil visíveis a outros usuários dos dados privados, incluindo e-mail e demais identificadores pessoais? [Gap, Constituição §V]
- [x] CHK009 Os requisitos especificam limites para coleta, retenção e remoção de dados pessoais quando uma conta ou pedido deixa de ser usado? [Gap, Constituição §V]
- [x] CHK010 Os requisitos de segurança cobrem confidencialidade de dados pessoais em armazenamento, transporte, mensagens de erro e registros de diagnóstico? [Gap, Constituição §V]
- [x] CHK011 Os requisitos deixam claro se as permissões de leitura e alteração se aplicam também fora da interface e como tentativas não autorizadas são comunicadas às pessoas? [Cobertura, Spec §FR-013, §FR-016–FR-022]

## Consistência e critérios de aceitação

- [x] CHK012 As regras de privacidade são consistentes entre perfil, lista de pedidos, candidaturas, contato após aceite e critérios de sucesso? [Consistência, Spec §FR-009–FR-018, §SC-005, §SC-007]
- [x] CHK013 Os critérios de sucesso permitem determinar objetivamente se nenhum contato foi exposto antes do aceite e se somente as partes autorizadas tiveram acesso depois dele? [Mensurabilidade, Spec §SC-005–SC-007]
- [x] CHK014 Os requisitos de mensagens e recuperação cobrem falhas de autenticação, carregamento e operações sem divulgar dados pessoais nem deixar a pessoa sem próximo passo? [Cobertura, Exceção, Spec §FR-002–FR-004, §FR-012]

## Notes

- Marque itens `[x]` somente após revisão confirmar que o critério de qualidade do requisito foi satisfeito.
- Deixe itens sem marcação se ainda exigirem esclarecimento, correção ou avaliação do revisor.
- `$speckit-implement` lê o estado das checklists como referência e não deve alterar seus marcadores.
- `checklists/requirements.md` tem ciclo de manutenção próprio por `$speckit-specify` e `$speckit-clarify`.
- Esta checklist avalia a redação e cobertura dos requisitos; não verifica o comportamento do código.
