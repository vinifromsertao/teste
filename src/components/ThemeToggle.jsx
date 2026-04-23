import { MoonStar, SunMedium } from "lucide-react";
import { useTheme } from "../hooks/useTheme";

export function ThemeToggle() {
  const { theme, effectiveTheme, toggleTheme, setTheme } = useTheme();

  return (
    <div className="glass-panel flex w-full max-w-sm flex-col gap-3 rounded-[28px] p-3 sm:w-auto">
      <div className="flex items-center justify-between gap-4">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.24em] text-[var(--text-muted)]">
            Aparencia
          </p>
          <p className="mt-1 text-sm text-[var(--text-secondary)]">
            Segue o sistema ou escolha o clima do estudo.
          </p>
        </div>
        <button
          className="outline-focus inline-flex h-12 w-12 items-center justify-center rounded-2xl border border-[var(--border-soft)] bg-[var(--bg-card)] text-[var(--text-primary)] transition hover:scale-[1.02]"
          onClick={toggleTheme}
          type="button"
        >
          {effectiveTheme === "dark" ? <SunMedium size={18} /> : <MoonStar size={18} />}
        </button>
      </div>

      <div className="grid grid-cols-3 gap-2">
        {[
          ["system", "Auto"],
          ["light", "Claro"],
          ["dark", "Escuro"],
        ].map(([value, label]) => {
          const active = theme === value;
          return (
            <button
              className={`outline-focus rounded-2xl px-3 py-2 text-sm font-semibold transition ${
                active
                  ? "bg-[var(--bg-card-strong)] text-[var(--text-primary)]"
                  : "bg-[var(--bg-elevated)] text-[var(--text-secondary)] hover:bg-[var(--bg-card)]"
              }`}
              key={value}
              onClick={() => setTheme(value)}
              type="button"
            >
              {label}
            </button>
          );
        })}
      </div>
    </div>
  );
}
