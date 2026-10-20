# BicoLocal: instruções para agentes

Aplicativo móvel em Flutter que conecta contratantes de serviços rápidos a prestadores que buscam bicos na região (Pilar II – Desenvolvimento Regional).

## Comandos
- Instalar dependências: `flutter pub get`
- Testes: `flutter test`
- Análise estática: `flutter analyze`
- Executar: `flutter run`

## Convenções
- Flutter estável e Dart com null safety
- Organização por funcionalidade: `lib/features/<nome>/` com `data`, `domain` e `presentation`
- Nomes do domínio em português (pedido, candidatura, avaliacao); identificadores técnicos do Flutter em inglês
- Todo texto mostrado ao usuário em português, claro e acionável
- Datas em ISO 8601 ao salvar; formato brasileiro (dd/MM/aaaa) ao exibir

## Regras
- Siga `specs/<feature>/spec.md`; não implemente o que não está nela
- Escreva o teste antes do código; rode `flutter test` e `flutter analyze` antes de dizer que terminou
- Não adicione dependência no `pubspec.yaml` sem justificar no plano
- Não edite `.specify/memory/constitution.md` sem pedir
- Nunca coloque chaves, senhas ou arquivos de configuração secretos no Git
- Peça confirmação antes de `git push` e de instalar pacotes novos

## Armadilhas
- Não faça chamadas ao banco dentro de widgets; use repositórios
- Sempre trate os estados de carregando, vazio e erro nas listas
- Nos testes, use repositórios falsos; não acesse o Firebase real
