import { useMemo, useState } from "react";
import { PenSquare, PlayCircle, Search } from "lucide-react";
import { FlashcardComposer } from "../components/FlashcardComposer";
import { FlashcardGrid } from "../components/FlashcardGrid";
import { StatsPanel } from "../components/StatsPanel";
import { SubjectSidebar } from "../components/SubjectSidebar";
import { ThemeChips } from "../components/ThemeChips";
import { useFlashcardsStore } from "../store/useFlashcardsStore";
import { themeOptions } from "../utils/defaultDeck";

export function LibraryPage({ onStartStudy }) {
  const cards = useFlashcardsStore((state) => state.cards);
  const filters = useFlashcardsStore((state) => state.filters);
  const addCard = useFlashcardsStore((state) => state.addCard);
  const updateCard = useFlashcardsStore((state) => state.updateCard);
  const deleteCard = useFlashcardsStore((state) => state.deleteCard);
  const themeStyles = useFlashcardsStore((state) => state.themeStyles);
  const setThemeFilter = useFlashcardsStore((state) => state.setThemeFilter);
  const setSearchFilter = useFlashcardsStore((state) => state.setSearchFilter);
  const startSession = useFlashcardsStore((state) => state.startSession);

  const [editorOpen, setEditorOpen] = useState(false);
  const [editingCard, setEditingCard] = useState(null);

  const visibleCards = useMemo(() => {
    const search = filters.search.trim().toLowerCase();

    return cards.filter((card) => {
      const matchesTheme = filters.theme === "Todos" || card.theme === filters.theme;
      const matchesSearch =
        !search ||
        [card.front, card.back, card.label, card.theme, card.hint].some((value) =>
          value.toLowerCase().includes(search),
        );

      return matchesTheme && matchesSearch;
    });
  }, [cards, filters]);

  const openCreate = () => {
    setEditingCard(null);
    setEditorOpen(true);
  };

  const openEdit = (card) => {
    setEditingCard(card);
    setEditorOpen(true);
  };

  const handleSave = (form) => {
    if (editingCard) {
      updateCard(editingCard.id, form);
      return;
    }

    addCard(form);
  };

  const handleStartStudy = () => {
    startSession({
      selectedTheme: filters.theme,
      shuffle: false,
    });
    onStartStudy();
  };

  return (
    <div className="space-y-6">
      <StatsPanel
        cards={cards}
        selectedTheme={filters.theme}
      />

      <section className="grid gap-4 xl:grid-cols-[22rem_minmax(0,1fr)]">
        <SubjectSidebar
          activeTheme={filters.theme}
          cards={cards}
          onSelectTheme={setThemeFilter}
          themeStyles={themeStyles}
          themes={["Todos", ...themeOptions]}
        />

        <div className="space-y-4">
          <div className="glass-panel rounded-[34px] p-5 sm:p-6">
            <div className="flex flex-col gap-5">
              <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
                <div>
                  <p className="text-xs font-semibold uppercase tracking-[0.24em] text-[var(--text-muted)]">
                    Biblioteca curada
                  </p>
                  <h2 className="mt-2 font-display text-4xl tracking-[-0.04em] text-[var(--text-primary)]">
                    Organize por assunto, personalize cores e refine o seu baralho.
                  </h2>
                </div>

                <div className="flex flex-col gap-3 sm:flex-row">
                  <button
                    className="outline-focus inline-flex items-center justify-center gap-2 rounded-2xl border border-[var(--border-soft)] bg-[var(--bg-card)] px-4 py-3 text-sm font-semibold text-[var(--text-primary)] transition hover:bg-[var(--bg-elevated)]"
                    onClick={openCreate}
                    type="button"
                  >
                    <PenSquare size={16} />
                    Criar card
                  </button>
                  <button
                    className="outline-focus inline-flex items-center justify-center gap-2 rounded-2xl bg-[var(--accent)] px-4 py-3 text-sm font-semibold text-white transition hover:brightness-105"
                    onClick={handleStartStudy}
                    type="button"
                  >
                    <PlayCircle size={16} />
                    Estudar agora
                  </button>
                </div>
              </div>

              <div className="grid gap-4">
                <div className="xl:hidden">
                  <ThemeChips
                    activeTheme={filters.theme}
                    onChange={setThemeFilter}
                    options={["Todos", ...themeOptions]}
                  />
                </div>

                <label className="relative block">
                  <Search
                    className="absolute left-4 top-1/2 -translate-y-1/2 text-[var(--text-muted)]"
                    size={18}
                  />
                  <input
                    className="outline-focus w-full rounded-[24px] border border-[var(--border-soft)] bg-[var(--bg-card)] py-3 pl-12 pr-4 text-sm text-[var(--text-primary)]"
                    onChange={(event) => setSearchFilter(event.target.value)}
                    placeholder="Busque por conceito, tema ou explicacao"
                    value={filters.search}
                  />
                </label>
              </div>
            </div>
          </div>

          <aside className="soft-card rounded-[34px] p-5 sm:p-6">
            <p className="text-xs font-semibold uppercase tracking-[0.24em] text-[var(--text-muted)]">
              Direcao visual
            </p>
            <h3 className="mt-2 font-display text-3xl tracking-[-0.04em] text-[var(--text-primary)]">
              Cada assunto ganha sua propria assinatura cromatica.
            </h3>
            <p className="mt-3 text-sm leading-7 text-[var(--text-secondary)]">
              A cor escolhida ao criar o card passa a orientar a barra lateral e deixa a biblioteca mais
              escaneavel, especialmente quando voce alterna entre conteudos.
            </p>
            <div className="mt-5 grid gap-3">
              {[
                "Barra lateral inspirada em apps mobile curados",
                "Escolha de cor no cadastro e na edicao",
                "Cards com faixa superior alinhada ao assunto",
                "Filtro rapido por assunto direto na lateral",
              ].map((item) => (
                <div
                  className="rounded-2xl border border-[var(--border-soft)] bg-[var(--bg-elevated)] px-4 py-3 text-sm text-[var(--text-secondary)]"
                  key={item}
                >
                  {item}
                </div>
              ))}
            </div>
          </aside>
        </div>
      </section>

      <FlashcardGrid
        cards={visibleCards}
        onDelete={deleteCard}
        onEdit={openEdit}
        themeStyles={themeStyles}
      />

      <FlashcardComposer
        card={editingCard}
        onClose={() => setEditorOpen(false)}
        onSave={handleSave}
        open={editorOpen}
        themeOptions={themeOptions}
      />
    </div>
  );
}
