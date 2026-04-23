const DEFAULT_FONT_SIZE = 18;
const DEFAULT_TEXT_ALIGN = "left";

function sanitizeHtml(value = "") {
  return String(value)
    .replace(/<script[\s\S]*?>[\s\S]*?<\/script>/gi, "")
    .replace(/<style[\s\S]*?>[\s\S]*?<\/style>/gi, "")
    .replace(/\son\w+="[^"]*"/gi, "")
    .replace(/\son\w+='[^']*'/gi, "")
    .replace(/javascript:/gi, "");
}

function extractWithRegex(value, pattern, fallback) {
  const match = String(value).match(pattern);
  return match?.[1] ?? fallback;
}

export function createRichTextDocument({
  contentHtml = "",
  fontSize = DEFAULT_FONT_SIZE,
  textAlign = DEFAULT_TEXT_ALIGN,
} = {}) {
  const safeContent = sanitizeHtml(contentHtml).trim() || "<p></p>";
  const safeFontSize = Number.isFinite(fontSize) ? fontSize : DEFAULT_FONT_SIZE;
  const safeTextAlign = textAlign || DEFAULT_TEXT_ALIGN;

  return `<div data-rich-text-root="true" style="font-size:${safeFontSize}px;text-align:${safeTextAlign};">${safeContent}</div>`;
}

export function parseRichTextDocument(value = "") {
  const source = String(value || "");

  if (!source.includes('data-rich-text-root="true"')) {
    return {
      contentHtml: sanitizeHtml(source),
      fontSize: DEFAULT_FONT_SIZE,
      textAlign: DEFAULT_TEXT_ALIGN,
    };
  }

  if (typeof window !== "undefined" && typeof window.DOMParser !== "undefined") {
    const parser = new window.DOMParser();
    const doc = parser.parseFromString(source, "text/html");
    const root = doc.querySelector('[data-rich-text-root="true"]');

    if (root) {
      return {
        contentHtml: sanitizeHtml(root.innerHTML),
        fontSize: Number.parseInt(root.style.fontSize, 10) || DEFAULT_FONT_SIZE,
        textAlign: root.style.textAlign || DEFAULT_TEXT_ALIGN,
      };
    }
  }

  return {
    contentHtml: sanitizeHtml(
      extractWithRegex(
        source,
        /<div[^>]*data-rich-text-root="true"[^>]*>([\s\S]*)<\/div>/i,
        source,
      ),
    ),
    fontSize: Number.parseInt(
      extractWithRegex(source, /font-size:\s*(\d+)px/i, String(DEFAULT_FONT_SIZE)),
      10,
    ),
    textAlign: extractWithRegex(source, /text-align:\s*([^;"]+)/i, DEFAULT_TEXT_ALIGN),
  };
}

export function stripHtml(value = "") {
  const source = parseRichTextDocument(value).contentHtml;

  if (typeof window !== "undefined" && typeof window.DOMParser !== "undefined") {
    const parser = new window.DOMParser();
    const doc = parser.parseFromString(source, "text/html");
    return (doc.body.textContent || "").replace(/\s+/g, " ").trim();
  }

  return source
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&lt;/gi, "<")
    .replace(/&gt;/gi, ">")
    .replace(/\s+/g, " ")
    .trim();
}

export function isRichTextEmpty(value = "") {
  return stripHtml(value).length === 0;
}

export function clampFontSize(value) {
  return Math.min(32, Math.max(14, value));
}

export { DEFAULT_FONT_SIZE, DEFAULT_TEXT_ALIGN };
