import { useEffect, useMemo, useState } from "react";
import { ArrowLeft, Clock3, Layers3, Sparkles } from "lucide-react";
import { StudyCard } from "../components/StudyCard";
import { StudyControls } from "../components/StudyControls";
import { useKeyboardShortcuts } from "../hooks/useKeyboardShortcuts";
import { useFlashcardsStore } from "../store/useFlashcardsStore";
import { buildStudyQueue } from "../utils/spacedRepetition";

export function StudyPage({ onBackToLibrary }) {
  const cards = useFlashcardsStore((state) => state.cards);
  const session = useFlashcardsStore((state) => state.session);
  const startSession = useFlashcardsStore((state) => state.startSession);
  const reshuffleSession = useFlashcardsStore((state) => state.reshuffleSession);
  const goToNextCard = useFlashcardsStore((state) => state.goToNextCard);
  const goToPreviousCard = useFlashcardsStore((state) => state.goToPreviousCard);
  const rateCurrentCard = useFlashcardsStore((state) => state.rateCurrentCard);

  const [isFlipped, setIsFlipped] = useState(false);

  useEffect(() => {
    if (session.queue.length === 0) {
      startSession({ selectedTheme: "Todos", shuffle: false });
    }
  }, [session.queue.length, startSession]);

  useEffect(() => {
    setIsFlipped(false);
  }, [session.currentIndex]);

  const activeCard = useMemo(() => {
    const activeId = session.queue[session.currentIndex];
    return cards.find((card) => card.id === activeId) ?? null;
  }, [cards, session.currentIndex, session.queue]);

  const dueCount = useMemo(
    () => buildStudyQueue(cards, { selectedTheme: session.selectedTheme }).length,
    [cards, session.selectedTheme],
  );

  useKeyboardShortcuts({
    " ": () => setIsFlipped((state) => !state),
    ArrowRight: () => goToNextCard(),
    ArrowLeft: () => goToPreviousCard(),
  });

  const handleRate = (rating) => {
    rateCurrentCard(rating);
    setIsFlipped(false);
  };

  if (!activeCard) {
    return (
      <section className="soft-card flex min-h-[26rem] flex-col items-center justify-center rounded-[36px] p-8 text-center">
        <p className="text-xs font-semibold uppercase tracking-[0.24em] text-[var(--text-muted)]">
          Sessão vazia
        </p>
        <h2 className="mt-3 font-display text-4xl tracking-[-0.04em] text-[var(--text-primary)]">
          Não há cards suficientes para revisar.
        </h2>
        <p className="mt-3 max-w-xl text-sm leading-7 text-[var(--text-secondary)]">
          Volte para a biblioteca, crie novos cards ou redefina seus filtros de estudo.
        </p>
        <button
          className="outline-focus mt-6 inline-flex items-center gap-2 rounded-2xl bg-[var(--accent)] px-5 py-3 text-sm font-semibold text-white"
          onClick={onBackToLibrary}
          type="button"
        >
          <ArrowLeft size={16} />
          Ir para biblioteca
        </button>
      </section>
    );
  }

  return (
    <div className="mx-auto flex max-w-5xl flex-col gap-5 py-2">
      <section className="glass-panel rounded-[34px] p-4 sm:p-5">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div className="flex flex-wrap items-center gap-3">
            <button
              className="outline-focus inline-flex items-center gap-2 rounded-2xl border border-[var(--border-soft)] bg-[var(--bg-card)] px-4 py-3 text-sm font-semibold text-[var(--text-primary)] transition hover:bg-[var(--bg-elevated)]"
              onClick={onBackToLibrary}
              type="button"
            >
              <ArrowLeft size={16} />
              Biblioteca
            </button>

            <div className="inline-flex items-center gap-2 rounded-full bg-[var(--bg-elevated)] px-3 py-2 text-[11px] font-semibold uppercase tracking-[0.24em] text-[var(--accent)]">
              <Sparkles size={13} />
              Estudo focado
            </div>
          </div>

          <div className="grid gap-2 sm:grid-cols-3">
            {[
              ["Progresso", `${Math.min(session.currentIndex + 1, session.queue.length)}/${session.queue.length}`, Layers3],
              ["Revisados", `${session.reviewedCount}`, Sparkles],
              ["Na fila", `${dueCount}`, Clock3],
            ].map(([label, value, Icon]) => (
              <div
                className="rounded-[22px] bg-[var(--bg-elevated)] px-4 py-3"
                key={label}
              >
                <div className="flex items-center gap-2 text-[var(--text-muted)]">
                  <Icon size={14} />
                  <p className="text-[11px] font-semibold uppercase tracking-[0.22em]">{label}</p>
                </div>
                <p className="mt-1 text-lg font-semibold text-[var(--text-primary)]">{value}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <StudyCard
        card={activeCard}
        isFlipped={isFlipped}
        onFlip={() => setIsFlipped((state) => !state)}
        progress={Math.min(session.currentIndex + 1, session.queue.length)}
        total={session.queue.length}
      />

      <StudyControls
        canRate={isFlipped}
        onNext={() => {
          goToNextCard();
          setIsFlipped(false);
        }}
        onPrevious={() => {
          goToPreviousCard();
          setIsFlipped(false);
        }}
        onRate={handleRate}
        onShuffle={() => {
          reshuffleSession();
          setIsFlipped(false);
        }}
      />
    </div>
  );
}
