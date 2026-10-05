"""Busca, todo dia, notícias sobre a eleição e monta a mensagem do WhatsApp.

Lê os feeds RSS das fontes escolhidas, filtra pelas palavras-chave e grava a
mensagem em MENSAGEM_ARQUIVO (padrão: mensagem.txt). O envio é feito pelo
whatsapp.js, a partir do seu próprio número.
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


def main():
    noticias = buscar_noticias()
    if len(noticias) < MINIMO:
        print(f"Aviso: só {len(noticias)} notícia(s) encontrada(s).", file=sys.stderr)

    mensagem = montar_mensagem(noticias)
    print(mensagem)

    arquivo = os.environ.get("MENSAGEM_ARQUIVO", "mensagem.txt")
    with open(arquivo, "w", encoding="utf-8") as f:
        f.write(mensagem)


if __name__ == "__main__":
    main()
