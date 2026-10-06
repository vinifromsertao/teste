"""Busca, todo dia, notícias sobre a eleição para enviar no WhatsApp.

Lê os feeds RSS das fontes escolhidas, filtra pelas palavras-chave, descobre a
foto de cada manchete e grava a lista em NOTICIAS_ARQUIVO (padrão:
noticias.json). O envio é feito pelo whatsapp.js: uma mensagem por notícia,
com a foto, o título e o link.
"""

import html
import html.entities
import json
import os
import re
import sys
import time
import unicodedata
from datetime import datetime, timedelta, timezone
from urllib.parse import quote_plus, urlparse
from urllib.request import Request, urlopen

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
MAXIMO = 2
JANELA_HORAS = 36  # só notícias publicadas nesse intervalo

NAVEGADOR = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36"

# ---------------------------------------------------------------- busca e filtro


def baixar(url):
    with urlopen(Request(url, headers={"User-Agent": NAVEGADOR}), timeout=20) as resposta:
        return resposta.read().decode("utf-8", "replace")


def corrigir_entidades(xml):
    """Troca entidades de HTML (ex.: &nbsp;) que quebram a leitura do RSS."""
    def trocar(m):
        nome = m.group(1)
        if nome in ("amp", "lt", "gt", "quot", "apos"):
            return m.group(0)
        codigo = html.entities.name2codepoint.get(nome)
        return f"&#{codigo};" if codigo else ""

    return re.sub(r"&([A-Za-z][A-Za-z0-9]*);", trocar, xml)


def ler_feed(url):
    try:
        return feedparser.parse(corrigir_entidades(baixar(url)))
    except Exception as erro:  # noqa: BLE001 - qualquer falha só pula o feed
        print(f"Aviso: não foi possível ler {url} ({erro})", file=sys.stderr)
        return None


def do_google(link):
    return urlparse(link).netloc.endswith("news.google.com")


def imagem_do_item(item):
    """Foto que o próprio RSS informa (media:content, thumbnail ou anexo)."""
    for campo in ("media_content", "media_thumbnail"):
        for midia in item.get(campo) or []:
            if midia.get("url"):
                return midia["url"]
    for anexo in item.get("enclosures") or []:
        if anexo.get("type", "").startswith("image") and anexo.get("href"):
            return anexo["href"]
    return None


def imagem_da_pagina(link):
    """Foto de destaque da notícia (og:image), a mesma que aparece ao compartilhar."""
    try:
        pagina = baixar(link)
    except Exception:  # noqa: BLE001
        return None
    for padrao in (
        r'<meta[^>]+property=["\']og:image["\'][^>]+content=["\']([^"\']+)',
        r'<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']og:image["\']',
    ):
        achado = re.search(padrao, pagina, re.I)
        if achado:
            return html.unescape(achado.group(1))
    return None


def resolver_pelo_site(titulo, fonte):
    """Acha o link direto e a foto de uma notícia do Google News pela busca do site (WordPress)."""
    dominio = SITES[fonte]
    url = (
        f"https://www.{dominio}/wp-json/wp/v2/posts?per_page=5&_fields=link,title,jetpack_featured_media_url"
        f"&search={quote_plus(titulo)}"
    )
    try:
        posts = json.loads(baixar(url))
    except Exception:  # noqa: BLE001
        return None, None
    alvo = normalizar(titulo)
    for post in posts:
        if normalizar(html.unescape(post.get("title", {}).get("rendered", ""))) == alvo:
            return post.get("link"), post.get("jetpack_featured_media_url") or None
    return None, None


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
        feed = ler_feed(url)
        if not feed or (feed.bozo and not feed.entries):
            if feed is not None:
                print(f"Aviso: não foi possível ler {url} ({feed.get('bozo_exception')})", file=sys.stderr)
            continue

        for item in feed.entries:
            data = item.get("published_parsed") or item.get("updated_parsed")
            if data and datetime.fromtimestamp(time.mktime(data), timezone.utc) < limite:
                continue

            titulo = html.unescape(limpar_titulo(item.get("title", ""), fonte))
            pontos = pontuacao(titulo + " " + item.get("summary", ""))
            if not pontos:
                continue

            link = item.get("link", "")
            # Entre notícias iguais, prefere a do feed do próprio site (link direto).
            pontos += 0 if do_google(link) else 0.5
            chave = normalizar(titulo)
            if chave not in noticias or pontos > noticias[chave]["pontos"]:
                noticias[chave] = {
                    "titulo": titulo,
                    "link": link,
                    "fonte": fonte,
                    "imagem": imagem_do_item(item),
                    "pontos": pontos,
                }

    selecionadas = sorted(noticias.values(), key=lambda n: n["pontos"], reverse=True)[:MAXIMO]

    for n in selecionadas:
        if do_google(n["link"]):
            link, imagem = resolver_pelo_site(n["titulo"], n["fonte"])
            if link:
                n["link"], n["imagem"] = link, imagem or n["imagem"]
        if not n["imagem"] and not do_google(n["link"]):
            n["imagem"] = imagem_da_pagina(n["link"])
        del n["pontos"]
    return selecionadas


# ---------------------------------------------------------------- saída


def main():
    noticias = buscar_noticias()
    if len(noticias) < MINIMO:
        print(f"Aviso: só {len(noticias)} notícia(s) encontrada(s).", file=sys.stderr)

    for n in noticias:
        print(f"- {n['titulo']}\n  {n['link']}\n  foto: {n['imagem'] or '(sem foto)'}")

    arquivo = os.environ.get("NOTICIAS_ARQUIVO", "noticias.json")
    with open(arquivo, "w", encoding="utf-8") as f:
        json.dump(noticias, f, ensure_ascii=False, indent=2)

if __name__ == "__main__":
    main()
