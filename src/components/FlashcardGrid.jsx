import { AnimatePresence, motion } from "framer-motion";
import { Edit3, Flame, PenSquare, Trash2 } from "lucide-react";

function formatNextReview(card) {
  const nextDue = card.studyMeta?.nextDueAt ?? Date.now();
  const diff = nextDue - Date.now();

  if (diff <= 0) {
    return "Revisar agora";
  }

  const hours = Math.round(diff / 3600000);
  if (hours < 24) {
    return `Em ${hours}h`;
  }

  const days = Math.round(hours / 24);
  return `Em ${days}d`;
}

export function FlashcardGrid({ cards, onEdit, onDelete }) {
  return (
    <div className="grid gap-4 lg:grid-cols-2 2xl:grid-cols-3">
      <AnimatePresence>
        {cards.map((card, index) => (
          <motion.article
            animate={{ opacity: 1, y: 0 }}
            className="soft-card rounded-[30px] p-5"
            exit={{ opacity: 0, y: 16 }}
            initial={{ opacity: 0, y: 18 }}
            key={card.id}
            transition={{ delay: index * 0.02, duration: 0.26 }}
          >
            <div className="flex items-start justify-between gap-3">
              <div className="space-y-3">
                <div className="inline-flex rounded-full bg-[var(--bg-elevated)] px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.24em] text-[var(--accent)]">
                  {card.label}
                </div>
                <div>
                  <p className="font-display text-3xl tracking-[-0.04em] text-[var(--text-primary)]">
                    {card.front}
                  </p>
                  <p className="mt-2 text-sm text-[var(--text-secondary)]">{card.theme}</p>
                </div>
              </div>

              <div className="inline-flex items-center gap-1 rounded-full bg-[var(--bg-elevated)] px-3 py-1.5 text-xs font-semibold text-[var(--text-secondary)]">
                <Flame size={14} />
                {card.studyMeta?.streak ?? 0}
              </div>
            </div>

            <p className="mt-5 max-h-[4.5rem] overflow-hidden text-sm leading-6 text-[var(--text-secondary)]">
              {card.back}
            </p>

            <div className="mt-6 flex flex-wrap items-center justify-between gap-3">
              <div className="space-y-1">
                <p className="text-xs font-semibold uppercase tracking-[0.22em] text-[var(--text-muted)]">
                  Proxima revisao
                </p>
                <p className="text-sm text-[var(--text-primary)]">{formatNextReview(card)}</p>
              </div>
              <div className="flex gap-2">
                <button
                  className="outline-focus inline-flex items-center gap-2 rounded-2xl border border-[var(--border-soft)] bg-[var(--bg-card)] px-3 py-2 text-sm font-semibold text-[var(--text-primary)] transition hover:bg-[var(--bg-elevated)]"
                  onClick={() => onEdit(card)}
                  type="button"
                >
                  <Edit3 size={15} />
                  Editar
                </button>
                <button
                  className="outline-focus inline-flex items-center gap-2 rounded-2xl border border-[var(--border-soft)] bg-transparent px-3 py-2 text-sm font-semibold text-[var(--danger)] transition hover:bg-[var(--bg-elevated)]"
                  onClick={() => onDelete(card.id)}
                  type="button"
                >
                  <Trash2 size={15} />
                  Excluir
                </button>
              </div>
            </div>
          </motion.article>
        ))}
      </AnimatePresence>
      {cards.length === 0 ? (
        <div className="soft-card col-span-full flex min-h-60 flex-col items-center justify-center rounded-[32px] p-8 text-center">
          <div className="bg-accent-soft flex h-14 w-14 items-center justify-center rounded-3xl text-[var(--accent)]">
            <PenSquare size={22} />
          </div>
          <h3 className="mt-4 font-display text-3xl tracking-[-0.04em] text-[var(--text-primary)]">
            Nenhum card encontrado
          </h3>
          <p className="mt-2 max-w-md text-sm leading-6 text-[var(--text-secondary)]">
            Ajuste os filtros ou crie um novo flashcard para alimentar sua sessao de estudo.
          </p>
        </div>
      ) : null}
    </div>
  );
}
