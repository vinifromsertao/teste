import { motion } from "framer-motion";
import { getThemeLabel } from "../utils/defaultDeck";

export function StudyCard({ card, isFlipped, onFlip, progress, total }) {
  if (!card) {
    return null;
  }

  const handleKeyDown = (event) => {
    const isSpace = event.key === " " || event.key === "Spacebar" || event.code === "Space";
    const isEnter = event.key === "Enter";

    if (!isSpace && !isEnter) {
      return;
    }

    event.preventDefault();
    event.stopPropagation();
    onFlip();
  };

  const handleClick = (event) => {
    if (event.detail === 0) {
      return;
    }

    onFlip();
  };

  return (
    <div className="card-viewport">
      <motion.div
        animate={{ opacity: 1, y: 0 }}
        initial={{ opacity: 0, y: 20 }}
        transition={{ duration: 0.35 }}
      >
        <button
          aria-label={`Flashcard ${card.front}`}
          aria-pressed={isFlipped}
          className={`card-3d outline-focus relative h-[29rem] w-full rounded-[36px] border border-[var(--border-soft)] text-left ${isFlipped ? "is-flipped" : ""}`}
          onClick={handleClick}
          onKeyDown={handleKeyDown}
          style={{ background: "transparent" }}
          type="button"
        >
          <div className="card-face front absolute inset-0 soft-card rounded-[36px] p-6 sm:p-8">
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
                  Clique ou pressione <span className="font-semibold">espaço</span> para revelar.
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
                    {getThemeLabel(card.theme)}
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
                Avalie o quanto esse conteúdo já está fixo para ajustar a repetição.
              </p>
            </div>
          </div>
        </button>
      </motion.div>
    </div>
  );
}
