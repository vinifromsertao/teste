# Bot de notícias para o WhatsApp

Todo dia, por volta das 7h (horário de Brasília), o bot busca notícias sobre a
eleição na **Carta Capital** e na **Mídia Ninja**. Ele dá prioridade às que
citam Flávio Bolsonaro e Lula e envia de 2 a 4 delas pelo WhatsApp, usando a
Twilio.

## Passo a passo

1. **Crie uma conta na Twilio** em <https://www.twilio.com/try-twilio>.
2. No painel, abra *Messaging → Try it out → Send a WhatsApp message*. Do seu
   celular, mande para o número indicado a mensagem `join <código>` que aparece
   na tela. **Cada pessoa que for receber precisa fazer isso** enquanto você
   usa o modo de teste (sandbox).
3. No GitHub, abra o repositório e vá em **Settings → Secrets and variables →
   Actions → New repository secret**. Crie estes quatro segredos:

   | Nome | Valor |
   |---|---|
   | `TWILIO_ACCOUNT_SID` | o "Account SID" do painel da Twilio |
   | `TWILIO_AUTH_TOKEN` | o "Auth Token" do painel da Twilio |
   | `TWILIO_WHATSAPP_FROM` | `whatsapp:+14155238886` (número do sandbox) |
   | `DESTINATARIOS` | números com DDI e DDD, separados por vírgula: `+5511999999999,+5521988888888` |

4. Junte (merge) este código na branch `main`. O GitHub só executa os
   agendamentos que estão na branch principal.
5. Para testar na hora, vá em **Actions → Bot de notícias (WhatsApp) → Run
   workflow**.

## Como personalizar (arquivo `bot.py`)

- **Fontes:** acrescente sites no dicionário `SITES`.
- **Assuntos:** edite `PRIORIDADE` e `PALAVRAS_CHAVE`. Escreva as palavras sem
  acento e em minúsculas.
- **Quantidade:** altere `MINIMO` e `MAXIMO`.
- **Horário:** mude a linha `cron` em `.github/workflows/bot-noticias.yml`. O
  horário é em UTC, ou seja, Brasília + 3 horas.

Para ver a mensagem no seu computador sem enviar nada:

```bash
pip install -r requirements.txt
DRY_RUN=1 python bot.py
```

## Cuidados

- Envie só para quem **pediu para receber**. Durante o período eleitoral, a
  legislação (Resolução TSE nº 23.610/2019) proíbe o disparo em massa de
  mensagens sem consentimento, e o WhatsApp também pode bloquear o número.
- O sandbox da Twilio serve para testes. Para usar de forma definitiva, é
  preciso registrar um número próprio na Twilio, e o envio passa a ser pago.
