import { motion } from "framer-motion";
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
              ? { ...colorOptions[4], id: colorOptions[4].id }
              : getThemeVisual(theme, themeStyles);

          const selected = activeTheme === theme;

          return (
            <motion.button
              whileHover={{
                y: -4,
                scale: 1.022,
                filter: "brightness(1.06) saturate(1.04)",
              }}
              whileTap={{ scale: 0.992 }}
              className="outline-focus group relative w-full overflow-hidden rounded-[24px] border px-4 py-4 text-left"
              key={theme}
              onClick={() => onSelectTheme(theme)}
              style={{
                background: getStripedCardBackground(visual.id),
                color: visual.text,
                borderColor: selected ? "rgba(255,255,255,0.7)" : visual.border,
                boxShadow: selected
                  ? "0 24px 60px rgba(0,0,0,0.24), 0 0 0 1px rgba(255,255,255,0.14) inset"
                  : "0 14px 30px rgba(0,0,0,0.12), 0 0 0 1px rgba(255,255,255,0.08) inset",
              }}
              transition={{ duration: 0.18, ease: "easeOut" }}
              type="button"
            >
              <motion.div
                aria-hidden="true"
                className="pointer-events-none absolute inset-0"
                initial={false}
                style={{
                  background:
                    "linear-gradient(135deg, rgba(255,255,255,0.24), rgba(255,255,255,0.08) 24%, transparent 52%)",
                }}
                whileHover={{ opacity: 1 }}
                transition={{ duration: 0.18 }}
              />

              <motion.div
                aria-hidden="true"
                className="pointer-events-none absolute inset-y-0 right-0 w-16"
                style={{
                  background: "linear-gradient(90deg, transparent, rgba(255,255,255,0.28))",
                }}
                initial={{ x: 18, opacity: 0.72 }}
                whileHover={{ x: 0, opacity: 1 }}
                transition={{ duration: 0.18 }}
              />

              <motion.div
                aria-hidden="true"
                className="pointer-events-none absolute inset-0 rounded-[24px]"
                style={{
                  boxShadow: selected
                    ? "0 0 0 2px rgba(255,255,255,0.22) inset"
                    : "0 0 0 0 rgba(255,255,255,0) inset",
                }}
                whileHover={{
                  boxShadow: "0 0 0 2px rgba(255,255,255,0.26) inset, 0 0 28px rgba(255,255,255,0.12)",
                }}
                transition={{ duration: 0.18 }}
              />

              <div className="relative flex items-center justify-between gap-4">
                <div className="flex items-center gap-3">
                  <motion.div
                    className="flex h-11 w-11 items-center justify-center rounded-2xl backdrop-blur-sm"
                    style={{ background: visual.chipBg }}
                    whileHover={{ scale: 1.08, rotate: -2 }}
                    transition={{ duration: 0.18 }}
                  >
                    <BookOpenText size={18} />
                  </motion.div>

                  <div>
                    <p
                      className="text-[11px] font-semibold uppercase tracking-[0.24em]"
                      style={{ color: visual.mutedText }}
                    >
                      {themeCards.length} cards
                    </p>
                    <p className="mt-1 text-base font-semibold leading-5">{getThemeLabel(theme)}</p>
                  </div>
                </div>

                <motion.div
                  animate={{
                    x: selected ? 2 : 0,
                    opacity: selected ? 1 : 0.94,
                  }}
                  className="flex items-center gap-2 text-sm font-semibold"
                  style={{ color: visual.mutedText }}
                  whileHover={{ x: 6 }}
                  transition={{ duration: 0.18 }}
                >
                  {selected ? "Ativo" : "Abrir"}
                  <ChevronRight size={16} />
                </motion.div>
              </div>
            </motion.button>
          );
        })}
      </div>
    </aside>
  );
}
