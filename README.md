# Atlas de Revisao

Aplicacao web de flashcards para alunos do 9o ano em Lingua Portuguesa, com visual premium, tema claro/escuro, sessao de estudo interativa e repeticao basica.

## Stack

- React + Vite
- Tailwind CSS
- Framer Motion
- Zustand

## Como rodar

1. Instale as dependencias:

```bash
npm install
```

2. Inicie o ambiente de desenvolvimento:

```bash
npm run dev
```

3. Gere o build de producao:

```bash
npm run build
```

## Deploy no GitHub Pages

O projeto ja esta preparado para publicar no GitHub Pages com GitHub Actions.

1. Envie o codigo para um repositorio no GitHub.
2. Garanta que a branch principal se chama `main`.
3. No repositorio, abra `Settings > Pages`.
4. Em `Build and deployment`, escolha `Source: GitHub Actions`.
5. Faça um push na `main`.

O workflow em [`.github/workflows/deploy.yml`](C:\Users\Vini\Documents\Codex\2026-04-22-segue-um-prompt-de-alto-n\.github\workflows\deploy.yml) vai instalar dependencias, gerar o `dist` e publicar automaticamente.

Observacao: o `base` do Vite foi configurado como relativo em [vite.config.js](C:\Users\Vini\Documents\Codex\2026-04-22-segue-um-prompt-de-alto-n\vite.config.js), entao o app funciona corretamente mesmo publicado em subpastas do GitHub Pages.

## Push rapido

Quando o repositorio ja existir no GitHub, o fluxo minimo fica assim:

```bash
git init
git add .
git commit -m "feat: initial flashcards app"
git branch -M main
git remote add origin <URL_DO_REPOSITORIO>
git push -u origin main
```

Depois disso, o workflow publica sozinho no GitHub Pages.

## Estrutura

```text
src/
  components/
  hooks/
  pages/
  store/
  utils/
  styles/
```

## Recursos principais

- Biblioteca com criacao, edicao, exclusao e filtro de cards
- Temas prontos para figuras de linguagem, gramatica, interpretacao e ortografia
- Sessao com flip 3D, clique, barra de progresso e atalhos de teclado
- Repeticao basica com maior recorrencia para cards marcados como dificeis
- Modo claro/escuro com suporte a `prefers-color-scheme`
- Persistencia em `localStorage`
