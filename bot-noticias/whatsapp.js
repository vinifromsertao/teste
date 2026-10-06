// Envia as notícias pelo seu próprio WhatsApp, conectado como
// "aparelho vinculado" (igual ao WhatsApp Web).
//
// Modos:
//   PAREAR=1 WHATSAPP_NUMERO=5516...   conecta o WhatsApp pela primeira vez
//   (padrão)                           envia as notícias de NOTICIAS_ARQUIVO para DESTINATARIOS,
//                                      uma mensagem por notícia (foto + título + link)
//
// A sessão fica na pasta SESSAO_DIR (padrão: sessao/).

import fs from "node:fs";
import makeWASocket, {
  Browsers,
  DisconnectReason,
  delay,
  fetchLatestBaileysVersion,
  useMultiFileAuthState,
} from "baileys";
import pino from "pino";
import qrcode from "qrcode-terminal";

const SESSAO_DIR = process.env.SESSAO_DIR || "sessao";
const PAREAR = process.env.PAREAR === "1";
const LIMITE_MS = (PAREAR ? 12 : 2) * 60 * 1000;

const soDigitos = (n) => (n || "").replace(/\D/g, "");

function sair(codigo, texto) {
  if (texto) (codigo ? console.error : console.log)(texto);
  // Dá tempo para a sessão ser gravada no disco antes de encerrar.
  setTimeout(() => process.exit(codigo), 3000);
}

setTimeout(() => sair(1, "Erro: tempo esgotado sem conseguir concluir."), LIMITE_MS);

async function enviarNoticia(sock, jid, noticia) {
  const legenda = `*${noticia.titulo}*\n\n${noticia.link}`;
  if (noticia.imagem) {
    try {
      await sock.sendMessage(jid, { image: { url: noticia.imagem }, caption: legenda });
      return;
    } catch (e) {
      console.error(`Não foi possível enviar a foto (${e.message}); enviando só o texto.`);
    }
  }
  await sock.sendMessage(jid, { text: legenda });
}

async function enviarNoticias(sock) {
  const arquivo = process.env.NOTICIAS_ARQUIVO || "noticias.json";
  const noticias = JSON.parse(fs.readFileSync(arquivo, "utf8"));
  if (!noticias.length) return sair(0, "Nenhuma notícia nova hoje; nada foi enviado.");

  const destinatarios = (process.env.DESTINATARIOS || "").split(",").map(soDigitos).filter(Boolean);
  if (!destinatarios.length) return sair(1, "Erro: DESTINATARIOS está vazio.");

  let falhas = 0;
  for (const [i, numero] of destinatarios.entries()) {
    // Confere o número no WhatsApp (resolve, por exemplo, o nono dígito).
    const [contato] = await sock.onWhatsApp(numero);
    if (!contato?.exists) {
      console.error(`Destinatário ${i + 1}: número não encontrado no WhatsApp.`);
      falhas++;
      continue;
    }
    for (const noticia of noticias) {
      await enviarNoticia(sock, contato.jid, noticia);
      await delay(3000);
    }
    console.log(`Destinatário ${i + 1}: ${noticias.length} notícia(s) enviada(s).`);
  }
  sair(falhas ? 1 : 0);
}

// "account" só é gravado quando o celular confirma o pareamento
// ("me" já aparece assim que o código é pedido).
const pareado = (creds) => Boolean(creds.account);

// Apaga uma sessão de pareamento que não chegou a ser concluída.
function limparSessaoIncompleta() {
  const arquivo = `${SESSAO_DIR}/creds.json`;
  if (!fs.existsSync(arquivo)) return;
  const creds = JSON.parse(fs.readFileSync(arquivo, "utf8"));
  if (!pareado(creds)) fs.rmSync(SESSAO_DIR, { recursive: true, force: true });
}

async function conectar() {
  if (PAREAR) limparSessaoIncompleta();
  const { state, saveCreds } = await useMultiFileAuthState(SESSAO_DIR);
  if (!PAREAR && !pareado(state.creds)) {
    return sair(1, "Erro: o WhatsApp ainda não foi conectado. Rode o workflow com a opção 'parear'.");
  }

  const { version } = await fetchLatestBaileysVersion();
  const sock = makeWASocket({
    version,
    auth: state,
    browser: Browsers.macOS("Chrome"),
    logger: pino({ level: "silent" }),
    markOnlineOnConnect: false,
    syncFullHistory: false,
  });
  sock.ev.on("creds.update", saveCreds);

  let pedidoFeito = false;
  sock.ev.on("connection.update", async ({ connection, lastDisconnect, qr }) => {
    if (qr && PAREAR && !pedidoFeito) {
      pedidoFeito = true;
      const numero = soDigitos(process.env.WHATSAPP_NUMERO);
      if (numero) {
        const codigo = await sock.requestPairingCode(numero);
        const hora = new Date().toLocaleTimeString("pt-BR", { timeZone: "America/Sao_Paulo" });
        console.log("\n==============================================");
        console.log(`   CÓDIGO PARA CONECTAR:  ${codigo.slice(0, 4)}-${codigo.slice(4)}`);
        console.log(`   (gerado às ${hora}; vale cerca de 2 minutos)`);
        console.log("==============================================");
        console.log("No celular: WhatsApp > Aparelhos conectados > Conectar aparelho >");
        console.log("'Conectar com número de telefone' e digite o código acima.\n");
      }
    }
    if (qr && PAREAR && !process.env.WHATSAPP_NUMERO) {
      console.log("Escaneie este QR code com o WhatsApp (Aparelhos conectados):");
      qrcode.generate(qr, { small: true });
    }

    if (connection === "open") {
      if (PAREAR) return sair(0, "WhatsApp conectado com sucesso! A sessão foi salva.");
      return enviarNoticias(sock).catch((e) => sair(1, `Erro ao enviar: ${e.message}`));
    }

    if (connection === "close") {
      const status = lastDisconnect?.error?.output?.statusCode;
      if (PAREAR && !pareado(state.creds)) {
        // O código expirou sem ser usado: gera um novo.
        console.log("O código expirou. Gerando um código novo...");
        await delay(1000);
        return conectar();
      }
      if (status === DisconnectReason.loggedOut) {
        return sair(1, "Erro: o WhatsApp desconectou este aparelho. Rode o workflow com a opção 'parear' de novo.");
      }
      // Logo após o pareamento o WhatsApp pede para reconectar (código 515).
      console.log(`Conexão fechada (código ${status ?? "?"}); reconectando...`);
      await delay(2000);
      conectar();
    }
  });
}

conectar().catch((e) => sair(1, `Erro: ${e.message}`));
