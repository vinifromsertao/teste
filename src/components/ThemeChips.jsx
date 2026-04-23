export function ThemeChips({ options, activeTheme, onChange }) {
  return (
    <div className="flex flex-wrap gap-2">
      {options.map((theme) => {
        const active = activeTheme === theme;

        return (
          <button
            className={`outline-focus rounded-full border px-4 py-2 text-sm font-semibold transition ${
              active
                ? "border-transparent bg-[var(--accent)] text-white"
                : "border-[var(--border-soft)] bg-[var(--bg-card)] text-[var(--text-secondary)] hover:bg-[var(--bg-elevated)]"
            }`}
            key={theme}
            onClick={() => onChange(theme)}
            type="button"
          >
            {theme}
          </button>
        );
      })}
    </div>
  );
}
