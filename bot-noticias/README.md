# Bot de notícias para o WhatsApp

Todo dia, por volta das 7h (horário de Brasília), o bot busca notícias sobre a
eleição na **Carta Capital** e na **Mídia Ninja**. Ele dá prioridade às que
citam Flávio Bolsonaro e Lula e envia 2 delas **do seu próprio WhatsApp**,
uma mensagem por notícia (foto da manchete, título e link), conectado como "aparelho vinculado" (igual ao WhatsApp Web).

> ⚠️ Esse tipo de conexão não é oficial e viola os termos de uso do WhatsApp.
> O número pode ser bloqueado, principalmente se enviar para muitas pessoas.
> Envie só para quem pediu para receber: durante o período eleitoral, a
> Resolução TSE nº 23.610/2019 proíbe o disparo em massa sem consentimento.

## Configuração (uma vez só)

1. **Segredos do repositório** (*Settings → Secrets and variables → Actions*):

   | Nome | Valor |
   |---|---|
   | `SESSAO_SENHA` | uma senha longa qualquer, inventada por você (protege a conexão do WhatsApp) |
   | `DESTINATARIOS` | números que recebem, com DDI e DDD, separados por vírgula: `+5516999999999` |

2. **Conectar o WhatsApp:** vá em *Actions → Bot de notícias (WhatsApp) →
   Run workflow*, marque **parear**, preencha **numero** com o seu número
   (ex.: `5516999999999`) e clique em **Run workflow**.
3. Abra a execução que começou e clique em **enviar → Conectar ao WhatsApp /
   enviar**. Aparece um **código de 8 letras**.
4. No celular: *WhatsApp → Aparelhos conectados → Conectar aparelho →
   Conectar com número de telefone* e digite o código. Cada código vale
   cerca de 2 minutos; se expirar, o bot mostra um novo logo abaixo (por
   até 12 minutos).
5. Quando aparecer "WhatsApp conectado com sucesso!", está pronto. Rode o
   workflow de novo, **sem** marcar parear, para testar o envio.

Se um dia o WhatsApp desconectar (por exemplo, se você remover o aparelho no
celular), basta repetir os passos 2 a 4.

## Como personalizar (arquivo `bot.py`)

- **Fontes:** acrescente sites no dicionário `SITES`.
- **Assuntos:** edite `PRIORIDADE` e `PALAVRAS_CHAVE`. Escreva as palavras sem
  acento e em minúsculas.
- **Quantidade:** altere `MINIMO` e `MAXIMO`.
- **Horário:** mude a linha `cron` em `.github/workflows/bot-noticias.yml`. O
  horário é em UTC, ou seja, Brasília + 3 horas.

Para ver as notícias escolhidas sem enviar nada, rode o workflow marcando
**so_buscar**, ou no seu computador:

```bash
pip install -r requirements.txt
python bot.py
```

## Como funciona

- `bot.py` busca as notícias, descobre a foto de cada uma e grava a lista em
  `noticias.json`.
- `whatsapp.js` conecta ao seu WhatsApp (biblioteca Baileys) e envia cada
  notícia como uma foto com legenda.
- A sessão do WhatsApp fica guardada no cache do GitHub Actions,
  criptografada com `SESSAO_SENHA`. O cache expira se o bot ficar mais de 7
  dias sem rodar; nesse caso, pareie de novo.
