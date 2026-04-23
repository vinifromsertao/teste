import { useEffect, useRef, useState } from "react";
import {
  AlignCenter,
  AlignLeft,
  AlignRight,
  Highlighter,
  PaintBucket,
  Type,
} from "lucide-react";
import {
  clampFontSize,
  createRichTextDocument,
  DEFAULT_FONT_SIZE,
  DEFAULT_TEXT_ALIGN,
  parseRichTextDocument,
} from "../utils/richText";

const textColors = [
  { label: "Marrom", value: "#2f221b" },
  { label: "Vinho", value: "#7b3148" },
  { label: "Petróleo", value: "#24556a" },
  { label: "Oliva", value: "#556645" },
];

const highlightColors = [
  { label: "Âmbar", value: "#ffe08a" },
  { label: "Pêssego", value: "#ffd0a8" },
  { label: "Menta", value: "#cdeec9" },
  { label: "Azul", value: "#cfe5ff" },
];

function ToolbarButton({ active = false, children, onClick, title }) {
  return (
    <button
      className={`outline-focus inline-flex h-11 items-center justify-center gap-2 rounded-2xl border px-3 text-sm font-semibold transition ${
        active
          ? "border-[var(--accent)] bg-[var(--accent-soft)] text-[var(--accent)]"
          : "border-[var(--border-soft)] bg-[var(--bg-card)] text-[var(--text-secondary)] hover:bg-[var(--bg-elevated)]"
      }`}
      onMouseDown={(event) => event.preventDefault()}
      onClick={onClick}
      title={title}
      type="button"
    >
      {children}
    </button>
  );
}

export function RichTextEditor({ value, onChange }) {
  const editorRef = useRef(null);
  const [fontSize, setFontSize] = useState(DEFAULT_FONT_SIZE);
  const [textAlign, setTextAlign] = useState(DEFAULT_TEXT_ALIGN);
  const [isFocused, setIsFocused] = useState(false);

  useEffect(() => {
    const { contentHtml, fontSize: nextFontSize, textAlign: nextTextAlign } = parseRichTextDocument(value);
    setFontSize(nextFontSize);
    setTextAlign(nextTextAlign);

    if (editorRef.current && editorRef.current.innerHTML !== contentHtml) {
      editorRef.current.innerHTML = contentHtml || "<p></p>";
    }
  }, [value]);

  const emitChange = (nextContent, nextFontSize = fontSize, nextTextAlign = textAlign) => {
    onChange(
      createRichTextDocument({
        contentHtml: nextContent,
        fontSize: nextFontSize,
        textAlign: nextTextAlign,
      }),
    );
  };

  const syncFromEditor = () => {
    emitChange(editorRef.current?.innerHTML ?? "");
  };

  const applyCommand = (command, commandValue = undefined) => {
    editorRef.current?.focus();
    document.execCommand(command, false, commandValue);
    syncFromEditor();
  };

  const updateFontSize = (direction) => {
    const nextFontSize = clampFontSize(fontSize + direction * 2);
    setFontSize(nextFontSize);
    emitChange(editorRef.current?.innerHTML ?? "", nextFontSize, textAlign);
  };

  const updateAlignment = (nextTextAlign) => {
    setTextAlign(nextTextAlign);
    emitChange(editorRef.current?.innerHTML ?? "", fontSize, nextTextAlign);
  };

  return (
    <div className="grid gap-3">
      <div className="flex flex-wrap gap-2">
        <ToolbarButton
          onClick={() => updateFontSize(-1)}
          title="Diminuir tamanho"
        >
          <Type size={16} />
          A-
        </ToolbarButton>
        <ToolbarButton
          onClick={() => updateFontSize(1)}
          title="Aumentar tamanho"
        >
          <Type size={16} />
          A+
        </ToolbarButton>

        <ToolbarButton
          active={textAlign === "left"}
          onClick={() => updateAlignment("left")}
          title="Alinhar à esquerda"
        >
          <AlignLeft size={16} />
        </ToolbarButton>
        <ToolbarButton
          active={textAlign === "center"}
          onClick={() => updateAlignment("center")}
          title="Centralizar"
        >
          <AlignCenter size={16} />
        </ToolbarButton>
        <ToolbarButton
          active={textAlign === "right"}
          onClick={() => updateAlignment("right")}
          title="Alinhar à direita"
        >
          <AlignRight size={16} />
        </ToolbarButton>
      </div>

      <div className="flex flex-wrap gap-2">
        <div className="flex items-center gap-2 rounded-2xl border border-[var(--border-soft)] bg-[var(--bg-card)] px-3 py-2">
          <PaintBucket size={16} className="text-[var(--text-secondary)]" />
          <div className="flex gap-2">
            {textColors.map((color) => (
              <button
                className="outline-focus h-7 w-7 rounded-full border border-white/40"
                key={color.value}
                onMouseDown={(event) => event.preventDefault()}
                onClick={() => applyCommand("foreColor", color.value)}
                style={{ backgroundColor: color.value }}
                title={`Cor do texto: ${color.label}`}
                type="button"
              />
            ))}
          </div>
        </div>

        <div className="flex items-center gap-2 rounded-2xl border border-[var(--border-soft)] bg-[var(--bg-card)] px-3 py-2">
          <Highlighter size={16} className="text-[var(--text-secondary)]" />
          <div className="flex gap-2">
            {highlightColors.map((color) => (
              <button
                className="outline-focus h-7 w-7 rounded-full border border-white/40"
                key={color.value}
                onMouseDown={(event) => event.preventDefault()}
                onClick={() => applyCommand("hiliteColor", color.value)}
                style={{ backgroundColor: color.value }}
                title={`Marca-texto: ${color.label}`}
                type="button"
              />
            ))}
          </div>
        </div>
      </div>

      <div
        className={`rounded-[28px] border bg-[var(--bg-card)] px-4 py-4 shadow-[var(--shadow-card)] transition ${
          isFocused ? "border-[var(--accent)]" : "border-[var(--border-soft)]"
        }`}
      >
        <div
          ref={editorRef}
          className="rich-text-editor min-h-40 text-[var(--text-primary)] focus:outline-none"
          contentEditable
          onBlur={() => {
            setIsFocused(false);
            syncFromEditor();
          }}
          onFocus={() => setIsFocused(true)}
          onInput={syncFromEditor}
          style={{
            fontSize: `${fontSize}px`,
            textAlign,
          }}
          suppressContentEditableWarning
        />
      </div>

      <div className="flex flex-wrap items-center justify-between gap-3 text-xs font-semibold uppercase tracking-[0.2em] text-[var(--text-muted)]">
        <span>Tamanho atual: {fontSize}px</span>
        <span>Selecione um trecho para aplicar cor ou marca-texto</span>
      </div>
    </div>
  );
}
