import { useEffect, useMemo, useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { PencilLine, Plus, X } from "lucide-react";

const emptyForm = {
  theme: "Figuras de linguagem",
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
        label: card.label,
        front: card.front,
        back: card.back,
        hint: card.hint,
      });
      return;
    }

    setForm(emptyForm);
  }, [card, open]);

  const handleSubmit = (event) => {
    event.preventDefault();
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
            className="glass-panel w-full max-w-2xl rounded-[34px] p-5 sm:p-7"
            exit={{ y: 16, opacity: 0 }}
            initial={{ y: 24, opacity: 0 }}
            onClick={(event) => event.stopPropagation()}
            transition={{ duration: 0.28 }}
          >
            <div className="flex items-start justify-between gap-4">
              <div>
                <div className="inline-flex rounded-full bg-[var(--bg-elevated)] px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.24em] text-[var(--accent)]">
                  {card ? "Atualizacao" : "Criacao"}
                </div>
                <h3 className="mt-3 font-display text-4xl tracking-[-0.04em] text-[var(--text-primary)]">
                  {title}
                </h3>
                <p className="mt-2 text-sm text-[var(--text-secondary)]">
                  Escreva um enunciado claro, uma resposta memoravel e um contexto curto.
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
                    onChange={(event) => setForm((state) => ({ ...state, theme: event.target.value }))}
                    value={form.theme}
                  >
                    {themeOptions.map((option) => (
                      <option
                        key={option}
                        value={option}
                      >
                        {option}
                      </option>
                    ))}
                  </select>
                </label>

                <label className="grid gap-2">
                  <span className="text-xs font-semibold uppercase tracking-[0.2em] text-[var(--text-muted)]">
                    Label superior
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

              <label className="grid gap-2">
                <span className="text-xs font-semibold uppercase tracking-[0.2em] text-[var(--text-muted)]">
                  Frente
                </span>
                <input
                  className="outline-focus rounded-2xl border border-[var(--border-soft)] bg-[var(--bg-card)] px-4 py-3 text-sm text-[var(--text-primary)]"
                  onChange={(event) => setForm((state) => ({ ...state, front: event.target.value }))}
                  placeholder="Ex.: Metafora"
                  required
                  value={form.front}
                />
              </label>

              <label className="grid gap-2">
                <span className="text-xs font-semibold uppercase tracking-[0.2em] text-[var(--text-muted)]">
                  Verso
                </span>
                <textarea
                  className="outline-focus min-h-32 rounded-3xl border border-[var(--border-soft)] bg-[var(--bg-card)] px-4 py-3 text-sm leading-7 text-[var(--text-primary)]"
                  onChange={(event) => setForm((state) => ({ ...state, back: event.target.value }))}
                  placeholder="Definicao, exemplo e contexto."
                  required
                  value={form.back}
                />
              </label>

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
                  {card ? "Salvar alteracoes" : "Criar flashcard"}
                </button>
              </div>
            </form>
          </motion.div>
        </motion.div>
      ) : null}
    </AnimatePresence>
  );
}
