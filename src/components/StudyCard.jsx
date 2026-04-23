import { motion } from "framer-motion";

export function StudyCard({ card, isFlipped, onFlip, progress, total }) {
  if (!card) {
    return null;
  }

  return (
    <div className="card-viewport">
      <motion.button
        animate={{ opacity: 1, y: 0 }}
        className={`card-3d outline-focus relative h-[29rem] w-full rounded-[36px] border border-[var(--border-soft)] text-left ${isFlipped ? "is-flipped" : ""}`}
        initial={{ opacity: 0, y: 20 }}
        onClick={onFlip}
        style={{ background: "transparent" }}
        transition={{ duration: 0.35 }}
        type="button"
      >
        <div className="card-face absolute inset-0 soft-card rounded-[36px] p-6 sm:p-8">
          <div className="flex h-full flex-col">
            <div className="flex items-start justify-between gap-4">
              <div className="space-y-2">
                <div className="inline-flex rounded-full bg-[var(--bg-elevated)] px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.24em] text-[var(--accent)]">
                  {card.label}
                </div>
                <p className="text-sm uppercase tracking-[0.28em] text-[var(--text-muted)]">frente</p>
              </div>
              <div className="rounded-full border border-[var(--border-soft)] px-3 py-1.5 text-sm font-semibold text-[var(--text-secondary)]">
                {progress}/{total}
              </div>
            </div>

            <div className="flex flex-1 items-center justify-center">
              <h2 className="max-w-3xl text-center font-display text-5xl leading-none tracking-[-0.05em] text-[var(--text-primary)] sm:text-6xl">
                {card.front}
              </h2>
            </div>

            <div className="space-y-2 text-center">
              <p className="text-sm text-[var(--text-secondary)]">
                Clique ou pressione <span className="font-semibold">espaco</span> para revelar.
              </p>
              {card.hint ? (
                <p className="text-xs uppercase tracking-[0.24em] text-[var(--text-muted)]">
                  Dica: {card.hint}
                </p>
              ) : null}
            </div>
          </div>
        </div>

        <div className="card-face back absolute inset-0 soft-card rounded-[36px] p-6 sm:p-8">
          <div className="flex h-full flex-col">
            <div className="flex items-start justify-between gap-4">
              <div className="space-y-2">
                <div className="inline-flex rounded-full bg-[var(--bg-elevated)] px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.24em] text-[var(--accent)]">
                  {card.theme}
                </div>
                <p className="text-sm uppercase tracking-[0.28em] text-[var(--text-muted)]">verso</p>
              </div>
              <div className="rounded-full border border-[var(--border-soft)] px-3 py-1.5 text-sm font-semibold text-[var(--text-secondary)]">
                resposta
              </div>
            </div>

            <div className="mt-8 flex-1 overflow-y-auto scrollbar-soft pr-2">
              <p className="font-display text-4xl tracking-[-0.04em] text-[var(--text-primary)] sm:text-5xl">
                {card.front}
              </p>
              <p className="mt-6 text-base leading-8 text-[var(--text-secondary)] sm:text-lg">
                {card.back}
              </p>
            </div>

            <p className="mt-6 text-center text-sm text-[var(--text-secondary)]">
              Avalie o quanto esse conteudo ja esta fixo para ajustar a repeticao.
            </p>
          </div>
        </div>
      </motion.button>
    </div>
  );
}
