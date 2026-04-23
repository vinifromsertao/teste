import { useEffect, useMemo, useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { PencilLine, Plus, X } from "lucide-react";
import { RichTextEditor } from "./RichTextEditor";
import { colorOptions, getColorOption, getStripedCardBackground, getThemeColorId } from "../utils/colorThemes";
import { getThemeLabel } from "../utils/defaultDeck";
import { isRichTextEmpty } from "../utils/richText";

const emptyForm = {
  theme: "Figuras de linguagem",
  colorId: "amber",
  label: "",
  front: "",
  back: "",
  hint: "",
};

export function FlashcardComposer({ card, open, onClose, onSave, themeOptions }) {
  const [form, setForm] = useState(emptyForm);

  const title = useMemo(() => (card ? "Editar card" : "Novo card"), [card]);

  useEffect(() => {
    if (card) {
      setForm({
        theme: card.theme,
        colorId: card.colorId ?? getThemeColorId(card.theme),
        label: card.label,
        front: card.front,
        back: card.back,
        hint: card.hint,
      });
      return;
    }

    setForm({
      ...emptyForm,
      colorId: getThemeColorId(emptyForm.theme),
    });
  }, [card, open]);

  const handleSubmit = (event) => {
    event.preventDefault();

    if (isRichTextEmpty(form.back)) {
      return;
    }

    onSave(form);
    onClose();
  };

  return (
    <AnimatePresence>
      {open ? (
        <motion.div
          animate={{ opacity: 1 }}
          className="fixed inset-0 z-50 flex items-end justify-center bg-black/30 p-4 backdrop-blur-md sm:items-center"
          exit={{ opacity: 0 }}
          initial={{ opacity: 0 }}
          onClick={onClose}
        >
          <motion.div
            animate={{ y: 0, opacity: 1 }}
            className="glass-panel w-full max-w-3xl rounded-[34px] p-5 sm:p-7"
            exit={{ y: 16, opacity: 0 }}
            initial={{ y: 24, opacity: 0 }}
            onClick={(event) => event.stopPropagation()}
            transition={{ duration: 0.28 }}
          >
            <div className="flex items-start justify-between gap-4">
              <div>
                <div className="inline-flex rounded-full bg-[var(--bg-elevated)] px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.24em] text-[var(--accent)]">
                  {card ? "Atualização" : "Criação"}
                </div>
                <h3 className="mt-3 font-display text-4xl tracking-[-0.04em] text-[var(--text-primary)]">
                  {title}
                </h3>
                <p className="mt-2 text-sm text-[var(--text-secondary)]">
                  Escreva um enunciado claro, uma resposta memorável e um contexto curto.
                </p>
              </div>

              <button
                className="outline-focus inline-flex h-11 w-11 items-center justify-center rounded-2xl border border-[var(--border-soft)] bg-[var(--bg-card)] text-[var(--text-primary)]"
                onClick={onClose}
                type="button"
              >
                <X size={18} />
              </button>
            </div>

            <form
              className="mt-6 grid gap-4"
              onSubmit={handleSubmit}
            >
              <div className="grid gap-4 md:grid-cols-2">
                <label className="grid gap-2">
                  <span className="text-xs font-semibold uppercase tracking-[0.2em] text-[var(--text-muted)]">
                    Tema
                  </span>
                  <select
                    className="outline-focus rounded-2xl border border-[var(--border-soft)] bg-[var(--bg-card)] px-4 py-3 text-sm text-[var(--text-primary)]"
                    onChange={(event) =>
                      setForm((state) => ({
                        ...state,
                        theme: event.target.value,
                        colorId:
                          state.colorId === getThemeColorId(state.theme)
                            ? getThemeColorId(event.target.value)
                            : state.colorId,
                      }))
                    }
                    value={form.theme}
                  >
                    {themeOptions.map((option) => (
                      <option
                        key={option}
                        value={option}
                      >
                        {getThemeLabel(option)}
                      </option>
                    ))}
                  </select>
                </label>

                <label className="grid gap-2">
                  <span className="text-xs font-semibold uppercase tracking-[0.2em] text-[var(--text-muted)]">
                    Categoria curta
                  </span>
                  <input
                    className="outline-focus rounded-2xl border border-[var(--border-soft)] bg-[var(--bg-card)] px-4 py-3 text-sm text-[var(--text-primary)]"
                    onChange={(event) => setForm((state) => ({ ...state, label: event.target.value }))}
                    placeholder="Ex.: Figuras de som"
                    required
                    value={form.label}
                  />
                </label>
              </div>

              <div className="grid gap-3">
                <div>
                  <span className="text-xs font-semibold uppercase tracking-[0.2em] text-[var(--text-muted)]">
                    Cor do assunto
                  </span>
                  <p className="mt-1 text-sm text-[var(--text-secondary)]">
                    Essa cor aparece na barra lateral e passa a identidade visual do assunto.
                  </p>
                </div>

                <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                  {colorOptions.map((option) => {
                    const active = form.colorId === option.id;

                    return (
                      <button
                        className={`outline-focus rounded-[22px] border p-3 text-left transition ${
                          active ? "scale-[1.01] shadow-[0_10px_30px_rgba(0,0,0,0.12)]" : "hover:translate-y-[-1px]"
                        }`}
                        key={option.id}
                        onClick={() => setForm((state) => ({ ...state, colorId: option.id }))}
                        style={{
                          background: getStripedCardBackground(option.id),
                          borderColor: active ? "rgba(255,255,255,0.45)" : option.border,
                          color: option.text,
                        }}
                        type="button"
                      >
                        <div className="flex items-center justify-between gap-3">
                          <div>
                            <p className="text-[11px] font-semibold uppercase tracking-[0.24em] text-white/78">
                              Paleta
                            </p>
                            <p className="mt-1 text-base font-semibold">{option.name}</p>
                          </div>
                          <div
                            className="h-10 w-10 rounded-2xl border border-white/30"
                            style={{ backgroundColor: getColorOption(option.id).solid }}
                          />
                        </div>
                      </button>
                    );
                  })}
                </div>
              </div>

                            <label className="grid gap-2">
                <span className="text-xs font-semibold uppercase tracking-[0.2em] text-[var(--text-muted)]">
                  Frente
                </span>
                <input
                  className="outline-focus rounded-2xl border border-[var(--border-soft)] bg-[var(--bg-card)] px-4 py-3 text-sm text-[var(--text-primary)]"
                  onChange={(event) => setForm((state) => ({ ...state, front: event.target.value }))}
                  placeholder="Ex.: Metáfora"
                  required
                  value={form.front}
                />
              </label>

              <div className="grid gap-2">
                <div className="flex items-center justify-between gap-3">
                  <span className="text-xs font-semibold uppercase tracking-[0.2em] text-[var(--text-muted)]">
                    Verso
                  </span>
                  <span className="text-[11px] font-semibold uppercase tracking-[0.2em] text-[var(--text-muted)]">
                    Editor rico
                  </span>
                </div>

                <RichTextEditor
                  onChange={(nextBack) => setForm((state) => ({ ...state, back: nextBack }))}
                  value={form.back}
                />
              </div>

              <label className="grid gap-2">
                <span className="text-xs font-semibold uppercase tracking-[0.2em] text-[var(--text-muted)]">
                  Dica sutil
                </span>
                <input
                  className="outline-focus rounded-2xl border border-[var(--border-soft)] bg-[var(--bg-card)] px-4 py-3 text-sm text-[var(--text-primary)]"
                  onChange={(event) => setForm((state) => ({ ...state, hint: event.target.value }))}
                  placeholder="Ex.: Pense no efeito sonoro."
                  value={form.hint}
                />
              </label>


              <div className="flex flex-col gap-3 pt-2 sm:flex-row sm:justify-end">
                <button
                  className="outline-focus rounded-2xl border border-[var(--border-soft)] px-4 py-3 text-sm font-semibold text-[var(--text-secondary)] transition hover:bg-[var(--bg-elevated)]"
                  onClick={onClose}
                  type="button"
                >
                  Cancelar
                </button>
                <button
                  className="outline-focus inline-flex items-center justify-center gap-2 rounded-2xl bg-[var(--accent)] px-5 py-3 text-sm font-semibold text-white transition hover:brightness-105"
                  type="submit"
                >
                  {card ? <PencilLine size={16} /> : <Plus size={16} />}
                  {card ? "Salvar alterações" : "Criar flashcard"}
                </button>
              </div>
            </form>
          </motion.div>
        </motion.div>
      ) : null}
    </AnimatePresence>
  );
}
