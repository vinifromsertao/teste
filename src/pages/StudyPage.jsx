import { useEffect, useMemo, useState } from "react";
import { motion } from "framer-motion";
import { ArrowLeft, BadgeInfo, ChartNoAxesCombined, Sparkles } from "lucide-react";
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
          Sessao vazia
        </p>
        <h2 className="mt-3 font-display text-4xl tracking-[-0.04em] text-[var(--text-primary)]">
          Nao ha cards suficientes para revisar.
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
    <div className="space-y-6">
      <section className="grid gap-4 xl:grid-cols-[1.1fr_0.9fr]">
        <div className="glass-panel rounded-[34px] p-5 sm:p-6">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
            <div className="space-y-3">
              <div className="inline-flex items-center gap-2 rounded-full bg-[var(--bg-elevated)] px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.24em] text-[var(--accent)]">
                <Sparkles size={13} />
                Sessao imersiva
              </div>
              <div>
                <h2 className="font-display text-4xl tracking-[-0.04em] text-[var(--text-primary)]">
                  Estude um conceito por vez, com calma e criterio.
                </h2>
                <p className="mt-2 max-w-2xl text-sm leading-7 text-[var(--text-secondary)]">
                  O algoritmo basico prioriza o que esta mais dificil e reapresenta esses cards mais cedo.
                </p>
              </div>
            </div>

            <button
              className="outline-focus inline-flex items-center gap-2 rounded-2xl border border-[var(--border-soft)] bg-[var(--bg-card)] px-4 py-3 text-sm font-semibold text-[var(--text-primary)] transition hover:bg-[var(--bg-elevated)]"
              onClick={onBackToLibrary}
              type="button"
            >
              <ArrowLeft size={16} />
              Biblioteca
            </button>
          </div>
        </div>

        <div className="soft-card rounded-[34px] p-5 sm:p-6">
          <div className="grid gap-3 sm:grid-cols-3">
            {[
              ["Progresso", `${Math.min(session.currentIndex + 1, session.queue.length)}/${session.queue.length}`],
              ["Revisados hoje", `${session.reviewedCount}`],
              ["Cards em fila", `${dueCount}`],
            ].map(([label, value]) => (
              <div
                className="rounded-[24px] bg-[var(--bg-elevated)] px-4 py-4"
                key={label}
              >
                <p className="text-xs font-semibold uppercase tracking-[0.22em] text-[var(--text-muted)]">
                  {label}
                </p>
                <p className="mt-2 text-2xl font-semibold tracking-[-0.04em] text-[var(--text-primary)]">
                  {value}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="grid gap-5 xl:grid-cols-[minmax(0,1fr)_21rem]">
        <div className="space-y-5">
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

        <aside className="space-y-4">
          <motion.div
            animate={{ opacity: 1, y: 0 }}
            className="soft-card rounded-[30px] p-5"
            initial={{ opacity: 0, y: 16 }}
          >
            <div className="flex items-center gap-3">
              <div className="bg-accent-soft flex h-11 w-11 items-center justify-center rounded-2xl text-[var(--accent)]">
                <BadgeInfo size={18} />
              </div>
              <div>
                <p className="text-xs font-semibold uppercase tracking-[0.22em] text-[var(--text-muted)]">
                  Atalhos
                </p>
                <p className="text-sm text-[var(--text-primary)]">Espaco, seta esquerda e seta direita</p>
              </div>
            </div>
            <div className="mt-5 grid gap-3 text-sm text-[var(--text-secondary)]">
              <div className="rounded-2xl bg-[var(--bg-elevated)] px-4 py-3">Espaco revela e esconde a resposta.</div>
              <div className="rounded-2xl bg-[var(--bg-elevated)] px-4 py-3">Setas navegam entre os cards da fila atual.</div>
              <div className="rounded-2xl bg-[var(--bg-elevated)] px-4 py-3">Use a avaliacao para calibrar a repeticao.</div>
            </div>
          </motion.div>

          <motion.div
            animate={{ opacity: 1, y: 0 }}
            className="glass-panel rounded-[30px] p-5"
            initial={{ opacity: 0, y: 16 }}
            transition={{ delay: 0.06 }}
          >
            <div className="flex items-center gap-3">
              <div className="bg-accent-soft flex h-11 w-11 items-center justify-center rounded-2xl text-[var(--accent)]">
                <ChartNoAxesCombined size={18} />
              </div>
              <div>
                <p className="text-xs font-semibold uppercase tracking-[0.22em] text-[var(--text-muted)]">
                  Regra de repeticao
                </p>
                <p className="text-sm text-[var(--text-primary)]">Basica, mas util de verdade</p>
              </div>
            </div>
            <div className="mt-5 grid gap-3 text-sm leading-7 text-[var(--text-secondary)]">
              <p className="rounded-2xl bg-[var(--bg-card)] px-4 py-3">Dificil: volta cedo para reforcar memorias instaveis.</p>
              <p className="rounded-2xl bg-[var(--bg-card)] px-4 py-3">Medio: reaparece no meio da fila para consolidacao.</p>
              <p className="rounded-2xl bg-[var(--bg-card)] px-4 py-3">Facil: some por mais tempo e libera foco para lacunas reais.</p>
            </div>
          </motion.div>
        </aside>
      </section>
    </div>
  );
}
