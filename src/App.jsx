import { useEffect, useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { BookText, Layers3, Sparkles } from "lucide-react";
import { AppShell } from "./components/AppShell";
import { ThemeToggle } from "./components/ThemeToggle";
import { LoadingScreen } from "./components/LoadingScreen";
import { LibraryPage } from "./pages/LibraryPage";
import { StudyPage } from "./pages/StudyPage";
import { useFlashcardsStore } from "./store/useFlashcardsStore";

const tabs = [
  { id: "library", label: "Biblioteca", icon: Layers3 },
  { id: "study", label: "Sessão de estudo", icon: BookText },
];

export default function App() {
  const cards = useFlashcardsStore((state) => state.cards);
  const [activeTab, setActiveTab] = useState("library");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const timer = window.setTimeout(() => setLoading(false), 1500);
    return () => window.clearTimeout(timer);
  }, []);

  return (
    <>
      <AnimatePresence>{loading ? <LoadingScreen key="loading" /> : null}</AnimatePresence>
      <AppShell
        header={
          activeTab === "library" ? (
            <div className="flex flex-col gap-6">
              <div className="flex flex-col gap-5 lg:flex-row lg:items-start lg:justify-between">
                <div className="max-w-3xl space-y-4">
                  <div className="inline-flex w-fit items-center gap-2 rounded-full border border-[var(--border-soft)] bg-[var(--bg-card)] px-3 py-1.5 text-xs font-semibold uppercase tracking-[0.32em] text-[var(--accent)]">
                    <Sparkles size={14} />
                    Atlas de Revisão
                  </div>
                  <div className="space-y-3">
                    <h1 className="font-display text-5xl leading-none tracking-[-0.04em] text-[var(--text-primary)] sm:text-6xl">
                      Flashcards premium para dominar Português no 9º ano.
                    </h1>
                    <p className="max-w-2xl text-base leading-7 text-[var(--text-secondary)] sm:text-lg">
                      Organize conteúdos, revise com repetição inteligente e estude em uma interface
                      que parece app de verdade, não um exercício escolar.
                    </p>
                  </div>
                </div>
                <ThemeToggle />
              </div>

              <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
                {[
                  ["Temas ativos", "4 áreas-chave"],
                  ["Cards disponíveis", `${cards.length} cards`],
                  ["Atalhos", "Espaço, setas e clique"],
                  ["Persistência", "Tudo salvo localmente"],
                ].map(([label, value]) => (
                  <div
                    className="soft-card rounded-[28px] px-5 py-4"
                    key={label}
                  >
                    <p className="text-xs font-semibold uppercase tracking-[0.26em] text-[var(--text-muted)]">
                      {label}
                    </p>
                    <p className="mt-2 text-xl font-semibold text-[var(--text-primary)]">{value}</p>
                  </div>
                ))}
              </div>

              <nav className="glass-panel flex w-fit flex-wrap gap-2 rounded-full p-2">
                {tabs.map(({ id, label, icon: Icon }) => {
                  const active = activeTab === id;
                  return (
                    <button
                      className={`outline-focus inline-flex items-center gap-2 rounded-full px-4 py-2.5 text-sm font-semibold transition ${
                        active
                          ? "bg-[var(--bg-card-strong)] text-[var(--text-primary)] shadow-[0_8px_24px_rgba(0,0,0,0.08)]"
                          : "text-[var(--text-secondary)] hover:bg-[var(--bg-elevated)]"
                      }`}
                      key={id}
                      onClick={() => setActiveTab(id)}
                      type="button"
                    >
                      <Icon size={16} />
                      {label}
                    </button>
                  );
                })}
              </nav>
            </div>
          ) : null
        }
      >
        <AnimatePresence mode="wait">
          {activeTab === "library" ? (
            <motion.div
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -24 }}
              initial={{ opacity: 0, y: 24 }}
              key="library"
              transition={{ duration: 0.35, ease: [0.22, 1, 0.36, 1] }}
            >
              <LibraryPage onStartStudy={() => setActiveTab("study")} />
            </motion.div>
          ) : (
            <motion.div
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -24 }}
              initial={{ opacity: 0, y: 24 }}
              key="study"
              transition={{ duration: 0.35, ease: [0.22, 1, 0.36, 1] }}
            >
              <StudyPage onBackToLibrary={() => setActiveTab("library")} />
            </motion.div>
          )}
        </AnimatePresence>
      </AppShell>
    </>
  );
}
