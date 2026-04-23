import { ArrowLeft, ArrowRight, Shuffle } from "lucide-react";

const ratingStyles = {
  hard: "bg-[rgba(127,64,56,0.12)] text-[var(--danger)] hover:bg-[rgba(127,64,56,0.18)]",
  medium: "bg-[rgba(138,103,56,0.12)] text-[var(--warning)] hover:bg-[rgba(138,103,56,0.18)]",
  easy: "bg-[rgba(66,102,82,0.14)] text-[var(--success)] hover:bg-[rgba(66,102,82,0.2)]",
};

export function StudyControls({
  canRate,
  onRate,
  onNext,
  onPrevious,
  onShuffle,
}) {
  return (
    <div className="grid gap-4 xl:grid-cols-[1fr_auto] xl:items-end">
      <div className="glass-panel rounded-[30px] p-4">
        <div className="flex flex-wrap gap-3">
          {[
            ["hard", "Difícil"],
            ["medium", "Médio"],
            ["easy", "Fácil"],
          ].map(([key, label]) => (
            <button
              className={`outline-focus rounded-2xl px-4 py-3 text-sm font-semibold transition ${ratingStyles[key]} ${!canRate ? "cursor-not-allowed opacity-40" : ""}`}
              disabled={!canRate}
              key={key}
              onClick={() => onRate(key)}
              type="button"
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      <div className="glass-panel flex flex-wrap gap-3 rounded-[30px] p-4">
        <button
          className="outline-focus inline-flex items-center gap-2 rounded-2xl border border-[var(--border-soft)] bg-[var(--bg-card)] px-4 py-3 text-sm font-semibold text-[var(--text-primary)] transition hover:bg-[var(--bg-elevated)]"
          onClick={onPrevious}
          type="button"
        >
          <ArrowLeft size={16} />
          Anterior
        </button>
        <button
          className="outline-focus inline-flex items-center gap-2 rounded-2xl border border-[var(--border-soft)] bg-[var(--bg-card)] px-4 py-3 text-sm font-semibold text-[var(--text-primary)] transition hover:bg-[var(--bg-elevated)]"
          onClick={onNext}
          type="button"
        >
          Próximo
          <ArrowRight size={16} />
        </button>
        <button
          className="outline-focus inline-flex items-center gap-2 rounded-2xl bg-[var(--accent)] px-4 py-3 text-sm font-semibold text-white transition hover:brightness-105"
          onClick={onShuffle}
          type="button"
        >
          <Shuffle size={16} />
          Embaralhar
        </button>
      </div>
    </div>
  );
}
