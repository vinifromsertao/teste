import { Brain, Clock3, Layers2, Trophy } from "lucide-react";

export function StatsPanel({ cards, selectedTheme }) {
  const filteredCards = cards.filter((card) => selectedTheme === "Todos" || card.theme === selectedTheme);
  const difficult = filteredCards.filter((card) => (card.studyMeta?.hardCount ?? 0) > (card.studyMeta?.easyCount ?? 0)).length;
  const reviewed = filteredCards.reduce((sum, card) => sum + (card.studyMeta?.totalReviews ?? 0), 0);
  const due = filteredCards.filter((card) => (card.studyMeta?.nextDueAt ?? 0) <= Date.now()).length;
  const bestStreak = filteredCards.reduce((max, card) => Math.max(max, card.studyMeta?.streak ?? 0), 0);

  const items = [
    { label: "Cards em foco", value: `${filteredCards.length}`, icon: Layers2 },
    { label: "Revisoes feitas", value: `${reviewed}`, icon: Brain },
    { label: "Vencendo hoje", value: `${due}`, icon: Clock3 },
    { label: "Melhor sequencia", value: `${bestStreak}`, icon: Trophy },
  ];

  return (
    <section className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
      {items.map(({ label, value, icon: Icon }) => (
        <article
          className="soft-card rounded-[28px] px-5 py-5"
          key={label}
        >
          <div className="flex items-center justify-between gap-4">
            <div className="space-y-2">
              <p className="text-xs font-semibold uppercase tracking-[0.26em] text-[var(--text-muted)]">
                {label}
              </p>
              <p className="text-3xl font-semibold tracking-[-0.04em] text-[var(--text-primary)]">{value}</p>
            </div>
            <div className="bg-accent-soft flex h-12 w-12 items-center justify-center rounded-2xl text-[var(--accent)]">
              <Icon size={20} />
            </div>
          </div>
          {label === "Cards em foco" ? (
            <p className="mt-4 text-sm text-[var(--text-secondary)]">
              {difficult > 0 ? `${difficult} precisam de reforco extra.` : "Seu ritmo esta equilibrado."}
            </p>
          ) : null}
        </article>
      ))}
    </section>
  );
}
