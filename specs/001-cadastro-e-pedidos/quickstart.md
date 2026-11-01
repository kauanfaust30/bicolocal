# Quickstart: validar cadastro e pedidos locais

Guia para preparar o ambiente e validar os fluxos descritos em [spec.md](spec.md). Requer Flutter stable com Dart compatível com `^3.13.4`, Android Studio ou Xcode conforme a plataforma e um projeto Firebase de desenvolvimento. Nunca use credenciais de produção nos testes.

## Preparação do Firebase

1. Criar/selecionar um projeto Firebase de desenvolvimento.
2. Ativar Authentication por e-mail/senha e criar Cloud Firestore.
3. Configurar os apps Android/iOS no projeto e gerar a configuração FlutterFire para as plataformas usadas.
4. Aplicar regras de segurança conforme [contrato Firestore](contracts/firestore-security.md). Não publicar contato em documento consultado pela lista.
5. As versões resolvidas (`cloud_firestore 7.0.0`, Firebase Auth 7.0.0) requerem Android minSdk 24 e iOS 15. O projeto usa Android `flutter.minSdkVersion` (24 no Flutter 3.47.5) e iOS deployment target 15.0; revalidar se os plugins forem atualizados.
6. Criar documentos de categoria definidos pelo produto em `categories/{categoryId}`. O catálogo desta feature é somente leitura no app.
7. A validade é uma data civil em `America/Sao_Paulo`: o pedido permanece aberto até o fim da data escolhida e deixa de aparecer às 00:00 do dia seguinte. Configure um projeto Firebase de desenvolvimento; nenhum arquivo de configuração de projeto está presente no repositório neste momento.

## Preparar o projeto

```powershell
flutter --version
flutter pub get
```

Esperado: Flutter stable, Dart compatível com a restrição do projeto e dependências resolvidas sem conflito. Os pacotes Firebase, Provider e go_router estão listados no plano e já foram autorizados para inclusão.

## Validar com testes automatizados

Executar testes unitários e de widget usando exclusivamente repositórios falsos:

```powershell
flutter test
flutter analyze
```

Esperado: cobertos cadastro com dados válidos/inválidos e e-mail duplicado; publicação e validações de prazo/valor; lista por cidade e categoria; estados carregando/vazio/erro; candidatura única; aceite concorrente; edição/cancelamento por partes autorizadas; contato oculto/visível conforme vínculo. Os testes não acessam Firebase real.

## Cenários manuais ponta a ponta

Para validação manual em ambiente Firebase de desenvolvimento, cadastrar contas descartáveis e limpar os dados ao fim:

1. **Cadastro e acesso**: criar um contratante e um prestador com e-mails diferentes; sair e entrar com credenciais corretas. E-mail duplicado e campos obrigatórios vazios devem produzir mensagens em português.
2. **Publicar e encontrar**: como contratante, publicar pedido com todos os campos e validade permitida. Como prestador, conferir os pedidos da cidade do perfil e selecionar outra cidade no filtro para buscar oportunidades adicionais. Confirmar que contato não aparece.
3. **Filtro e lista**: criar pedidos em duas categorias; selecionar uma categoria e conferir apenas resultados correspondentes; limpar o filtro; verificar estados vazio e falha com nova tentativa.
4. **Candidatura e aceite**: candidatar dois prestadores; aceitar uma candidatura. O pedido deve ficar em andamento, a candidatura escolhida aceita e a outra recusada. Repetir o aceite deve falhar sem trocar a pessoa escolhida.
5. **Permissões e contato**: verificar que contratante e prestador escolhido podem ver contato e editar/cancelar conforme estado; outro prestador não pode. Antes do aceite nenhum contato aparece.
6. **Validade**: publicar pedido com validade de hoje e um pedido de teste expirado (por fixture/dado controlado); confirmar que o segundo não aparece nem aceita candidatura.

## Executar no dispositivo/emulador

```powershell
flutter run
```

Esperado: app abre no dispositivo Android/iOS conectado, apresenta fluxo em português e mantém conteúdo adaptado a tela de celular.

## Limites desta validação

`flutter test` comprova regras de apresentação/domínio com fakes; não valida regras implantadas no Firestore. Revisão de regras em emulador Firebase pode ser acrescentada quando as regras forem implementadas, sem substituir os testes com fakes. Sem backend agendado, a expiração é derivada das datas em consultas e operações; o documento não muda de estado sozinho à meia-noite.
