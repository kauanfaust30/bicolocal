# Quickstart — validação da 002

Guia para provar a funcionalidade de ponta a ponta. Modelo de dados em
[data-model.md](data-model.md); regras em [contracts/firestore-security.md](contracts/firestore-security.md);
telas em [contracts/telas-e-rotas.md](contracts/telas-e-rotas.md).

## Pré-requisitos

- Dependências instaladas, incluindo `image_picker` e declarar `characters` (instalação exige
  confirmação):
  `flutter pub get`.
- Regras e índices publicados (exige confirmação):
  `firebase deploy --only firestore:rules,firestore:indexes --project bicolocal-35534`.
- Três contas de teste: contratante C, prestadores P1 e P2. Uma conta antiga da 001 sem foto (A).

## Testes automatizados

```text
flutter analyze   → No issues found!
flutter test      → All tests passed!
```

## Roteiro manual (`flutter run` em celular ou `-d chrome`)

1. **Cadastro com foto**
   - Tentar criar conta sem foto → "Adicione uma foto para concluir o cadastro."
   - Escolher foto da galeria → prévia → "Usar esta foto" → conta criada.
   - Com a rede desligada no envio → cadastro não termina, dados continuam preenchidos.
2. **Conta antiga**: entrar com A → vai direto para Adicionar foto; depois de enviar, vai ao
   início. No Console, `profiles/{A}` foi criado sem bairro nem e-mail.
3. **Foto só depois do aceite**
   - C publica pedido; P1 e P2 se candidatam.
   - C abre candidaturas → vê nome e nota de P1 e P2, com a inicial no lugar da foto.
   - P1, na lista da cidade, abre "Ver contratante" → nome e nota de C, com a inicial.
   - C aceita P1 → C vê a foto de P1; P1 vê a foto de C; P2 continua sem ver a foto de C e C nunca
     vê a de P2.
4. **Concluir e avaliar**
   - P1 não tem "Concluir pedido"; C conclui → pedido "Concluído", sem editar nem cancelar.
   - C avalia P1 com 5 e comentário → "Você já avaliou"; P1 ainda vê "Avaliar".
   - P1 avalia C com 4 sem comentário.
   - Perfil de P1: "5,0", "1 avaliação", avaliação com nome de C e data dd/MM/aaaa.
   - P2 tenta abrir `/pedidos/{id}/avaliar` → volta ao início.
5. **Perfil**: Meu perfil de P2 mostra "Ainda sem avaliações"; nenhum perfil mostra bairro,
   e-mail ou telefone.

## Verificação das regras no Console (Rules Playground)

| Simulação | Esperado |
|---|---|
| P2 `get` em `requests/{id}/applications/{P2}/private/foto` como C | negado |
| C `get` em `requests/{id}/applications/{P1}/private/foto` após o aceite | permitido |
| P2 `get` em `requests/{id}/fotos/{C}` | negado |
| `update` em `profiles/{P1}/avaliacoes/{id}` | negado |
| segunda `create` de C em `profiles/{P1}/avaliacoes/{id}` | negado |
| `create` de avaliação com pedido em andamento | negado |
| `update` de `requests/{id}` concluído para `cancelado` | negado |
| `get` em `profiles/{qualquer}` autenticado | permitido |
| `get` em `users/{outro}` | negado |
