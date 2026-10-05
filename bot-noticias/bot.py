"""Bot que envia, todo dia, notícias sobre a eleição para o WhatsApp.

Busca as notícias nos feeds RSS das fontes escolhidas, filtra pelas
palavras-chave, monta uma mensagem e envia pela Twilio.

Variáveis de ambiente:
  TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN  credenciais da Twilio
  TWILIO_WHATSAPP_FROM                   número remetente (ex.: whatsapp:+14155238886)
  DESTINATARIOS                          números separados por vírgula (ex.: +5511999999999,+5521988888888)
  DRY_RUN=1                              só mostra a mensagem, sem enviar
"""

import os
import re
import sys
import time
import unicodedata
from datetime import datetime, timedelta, timezone
from urllib.parse import quote_plus

import feedparser

# ---------------------------------------------------------------- configuração

SITES = {
    "Carta Capital": "cartacapital.com.br",
    "Mídia Ninja": "midianinja.org",
}

# Feeds diretos dos sites (WordPress) e, como reserva, a busca do Google News
# restrita a cada site.
FEEDS = [(nome, f"https://www.{dominio}/feed/") for nome, dominio in SITES.items()] + [
    (
        nome,
        "https://news.google.com/rss/search?q="
        + quote_plus(f"(Flávio Bolsonaro OR Lula OR eleição) site:{dominio} when:2d")
        + "&hl=pt-BR&gl=BR&ceid=BR:pt-419",
    )
    for nome, dominio in SITES.items()
]

# Notícias que citam os candidatos vêm primeiro; as demais palavras ampliam a busca.
PRIORIDADE = ["flavio bolsonaro", "lula"]
PALAVRAS_CHAVE = PRIORIDADE + ["eleicao", "eleicoes", "eleitoral", "candidato", "pesquisa", "tse", "urna"]

MINIMO = 2
MAXIMO = 4
JANELA_HORAS = 36  # só notícias publicadas nesse intervalo

# ---------------------------------------------------------------- busca e filtro


def normalizar(texto):
    """Minúsculas e sem acentos, para comparar palavras-chave."""
    texto = unicodedata.normalize("NFKD", texto or "").encode("ascii", "ignore").decode()
    return re.sub(r"\s+", " ", texto.lower()).strip()


def pontuacao(texto):
    texto = normalizar(texto)
    pontos = sum(3 for p in PRIORIDADE if p in texto)
    pontos += sum(1 for p in PALAVRAS_CHAVE if p not in PRIORIDADE and re.search(rf"\b{p}\b", texto))
    return pontos


def limpar_titulo(titulo, fonte):
    # O Google News acrescenta " - Nome do site" ao final do título.
    nome = r"\s*".join(map(re.escape, fonte.split()))
    return re.sub(rf"\s+-\s+{nome}.*$", "", titulo, flags=re.I).strip()


def buscar_noticias():
    limite = datetime.now(timezone.utc) - timedelta(hours=JANELA_HORAS)
    noticias = {}

    for fonte, url in FEEDS:
        feed = feedparser.parse(url, agent="Mozilla/5.0 (bot-noticias)")
        if feed.bozo and not feed.entries:
            print(f"Aviso: não foi possível ler {url} ({feed.get('bozo_exception')})", file=sys.stderr)
            continue

        for item in feed.entries:
            data = item.get("published_parsed") or item.get("updated_parsed")
            if data and datetime.fromtimestamp(time.mktime(data), timezone.utc) < limite:
                continue

            titulo = limpar_titulo(item.get("title", ""), fonte)
            pontos = pontuacao(titulo + " " + item.get("summary", ""))
            if not pontos:
                continue

            chave = normalizar(titulo)
            if chave not in noticias or pontos > noticias[chave]["pontos"]:
                noticias[chave] = {"titulo": titulo, "link": item.get("link", ""), "fonte": fonte, "pontos": pontos}

    selecionadas = sorted(noticias.values(), key=lambda n: n["pontos"], reverse=True)
    return selecionadas[:MAXIMO]


# ---------------------------------------------------------------- mensagem e envio


def montar_mensagem(noticias):
    hoje = datetime.now(timezone(timedelta(hours=-3))).strftime("%d/%m/%Y")
    if not noticias:
        return f"🗳️ *Eleições 2026 — {hoje}*\n\nNenhuma notícia nova encontrada nas fontes hoje."

    linhas = [f"🗳️ *Eleições 2026 — notícias de {hoje}*"]
    for i, n in enumerate(noticias, 1):
        linhas.append(f"*{i}. {n['titulo']}*\n_{n['fonte']}_\n{n['link']}")
    return "\n\n".join(linhas)


def enviar(mensagem):
    from twilio.rest import Client

    client = Client(os.environ["TWILIO_ACCOUNT_SID"], os.environ["TWILIO_AUTH_TOKEN"])
    remetente = os.environ.get("TWILIO_WHATSAPP_FROM") or "whatsapp:+14155238886"
    destinatarios = [n.strip() for n in os.environ["DESTINATARIOS"].split(",") if n.strip()]

    for numero in destinatarios:
        if not numero.startswith("whatsapp:"):
            numero = f"whatsapp:{numero}"
        msg = client.messages.create(from_=remetente, to=numero, body=mensagem[:1600])
        print(f"Enviado para {numero} (id {msg.sid})")


def main():
    noticias = buscar_noticias()
    if len(noticias) < MINIMO:
        print(f"Aviso: só {len(noticias)} notícia(s) encontrada(s).", file=sys.stderr)

    mensagem = montar_mensagem(noticias)
    print(mensagem)

    if os.environ.get("DRY_RUN") == "1":
        print("\n(DRY_RUN: mensagem não enviada)")
        return
    enviar(mensagem)


if __name__ == "__main__":
    main()
