# Contrato de telas e rotas — 002

Textos em português; datas dd/MM/aaaa; alvos de toque ≥ 48 dp; foto com rótulo acessível
"Foto de {nome}" (ou "Inicial de {nome}" quando oculta).

## Rotas novas

| Rota | Tela | Quem acessa | Redirect |
|---|---|---|---|
| `/foto` | Adicionar foto | autenticado com `temFoto == false` | qualquer rota autenticada → `/foto` enquanto `temFoto` for falso; `/foto` → `/inicio` quando verdadeiro |
| `/perfil` | Meu perfil | autenticado | — |
| `/perfis/:uid?pedido=:pedidoId` | Perfil de outra pessoa | autenticado | sem `pedido` → `/inicio` (o app só oferece o acesso a partir de um pedido) |
| `/pedidos/:pedidoId/concluir` | Concluir pedido | contratante | outro perfil → `/inicio` |
| `/pedidos/:pedidoId/avaliar` | Avaliar | contratante ou prestador | quem não é parte → `/inicio` |

## Pontos de entrada

- **Início**: cartão "Meu perfil" para os dois perfis.
- **Candidaturas** (contratante): cada candidato com avatar (inicial; foto só no aceito), nome e
  nota média; toque abre `/perfis/{prestador}?pedido={id}`.
- **Pedidos da cidade** (prestador): ação "Ver contratante" no cartão abre
  `/perfis/{contratante}?pedido={id}`.
- **Meus pedidos / Gerenciar pedido**: avatar da outra parte (foto após o aceite); em andamento,
  o contratante vê "Concluir pedido"; concluído, cada parte vê "Avaliar" ou "Você já avaliou".

## Telas

### Adicionar foto (`/foto`) e escolha de foto no cadastro

- Botões "Tirar foto" e "Escolher da galeria".
- Prévia circular com "Usar esta foto" e "Escolher outra".
- Mensagens:
  - permissão negada: "Não conseguimos acessar a câmera. Permita o acesso nas configurações do
    celular ou escolha uma foto da galeria." (e o inverso para a galeria);
  - não é imagem: "Esse arquivo não é uma foto. Escolha uma imagem.";
  - grande demais: "Essa foto ficou grande demais. Escolha outra.";
  - envio falhou (cadastro): "Não foi possível enviar sua foto. Seus dados continuam preenchidos.
    Verifique a conexão e toque em Criar conta de novo.";
  - envio falhou (adicionar/trocar): "Não foi possível enviar sua foto. Verifique a conexão e tente
    de novo." (a foto anterior continua valendo).
- Cadastro sem foto: "Adicione uma foto para concluir o cadastro." junto à seção de foto.

### Meu perfil (`/perfil`)

Foto própria, nome, cidade, selo do tipo, nota média ("4,7 ★") e total ("12 avaliações"), botão
"Trocar foto" e as 5 avaliações recentes. Sem avaliações: "Ainda sem avaliações". Estados de
carregando, vazio e erro ("Não foi possível carregar as avaliações. Tentar novamente").

### Perfil de outra pessoa (`/perfis/:uid`)

Igual a Meu perfil, sem "Trocar foto", e com a foto só quando a regra de foto permitir (senão a
inicial). Nunca mostra bairro, e-mail ou telefone.

### Concluir pedido (`/pedidos/:pedidoId/concluir`)

Resumo do pedido e aviso: "Depois de concluído, o pedido não pode mais ser editado nem cancelado.
Você e o prestador poderão se avaliar." Botões "Concluir pedido" e "Voltar". Sucesso volta ao
pedido com "Pedido concluído.". Recusa: "Este pedido não pode ser concluído agora." com "Voltar ao
início".

### Avaliar (`/pedidos/:pedidoId/avaliar`)

Avatar e nome da outra parte, 5 estrelas (alvos de 48 dp, rótulos "1 estrela"…"5 estrelas"),
comentário opcional com contador "0/300", aviso "A avaliação não pode ser editada depois.", botão
"Enviar avaliação". Erros: "Escolha uma nota de 1 a 5."; "O comentário pode ter até 300
caracteres."; falha: "Não foi possível enviar a avaliação. Sua nota e seu comentário continuam
aqui. Tente de novo.". Depois de enviar: volta ao pedido, que mostra "Você já avaliou".
