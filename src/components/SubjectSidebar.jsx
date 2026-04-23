import { BookOpenText, ChevronRight } from "lucide-react";
import { colorOptions, getStripedCardBackground, getThemeVisual } from "../utils/colorThemes";
import { getThemeLabel } from "../utils/defaultDeck";

export function SubjectSidebar({ themes, activeTheme, onSelectTheme, cards, themeStyles }) {
  return (
    <aside className="glass-panel rounded-[34px] p-4 sm:p-5">
      <div className="mb-4 px-2">
        <p className="text-xs font-semibold uppercase tracking-[0.24em] text-[var(--text-muted)]">
          Assuntos
        </p>
        <h3 className="mt-2 font-display text-3xl tracking-[-0.04em] text-[var(--text-primary)]">
          Escolha o foco da revisão.
        </h3>
      </div>

      <div className="space-y-3">
        {themes.map((theme) => {
          const themeCards = theme === "Todos" ? cards : cards.filter((card) => card.theme === theme);
          const visual =
            theme === "Todos"
              ? {
                  ...colorOptions[4],
                  id: colorOptions[4].id,
                }
              : getThemeVisual(theme, themeStyles);
          const selected = activeTheme === theme;

          return (
            <button
              className={`outline-focus relative w-full overflow-hidden rounded-[24px] border px-4 py-4 text-left transition ${
                selected
                  ? "scale-[1.01] shadow-[0_18px_48px_rgba(0,0,0,0.18)]"
                  : "hover:translate-x-[2px] hover:brightness-[1.03]"
              }`}
              key={theme}
              onClick={() => onSelectTheme(theme)}
              style={{
                background: getStripedCardBackground(visual.id),
                borderColor: selected ? "rgba(255,255,255,0.45)" : visual.border,
                color: visual.text,
              }}
              type="button"
            >
              <div className="flex items-center justify-between gap-4">
                <div className="flex items-center gap-3">
                  <div
                    className="flex h-11 w-11 items-center justify-center rounded-2xl backdrop-blur-sm"
                    style={{ background: visual.chipBg }}
                  >
                    <BookOpenText size={18} />
                  </div>
                  <div>
                    <p
                      className="text-[11px] font-semibold uppercase tracking-[0.24em]"
                      style={{ color: visual.mutedText }}
                    >
                      {themeCards.length} cards
                    </p>
                    <p className="mt-1 text-base font-semibold">{getThemeLabel(theme)}</p>
                  </div>
                </div>

                <div
                  className="flex items-center gap-2 text-sm font-semibold"
                  style={{ color: visual.mutedText }}
                >
                  {selected ? "Ativo" : "Abrir"}
                  <ChevronRight size={16} />
                </div>
              </div>
            </button>
          );
        })}
      </div>
    </aside>
  );
}
