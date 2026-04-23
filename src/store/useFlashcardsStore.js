import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";
import { defaultCards } from "../utils/defaultDeck";
import { defaultThemeStyles, getThemeColorId } from "../utils/colorThemes";
import { applyRatingToCard, buildStudyQueue, scheduleReviewedCard } from "../utils/spacedRepetition";

function normalizeCardInput(input) {
  return {
    id: input.id ?? crypto.randomUUID(),
    theme: input.theme,
    colorId: input.colorId ?? getThemeColorId(input.theme, defaultThemeStyles),
    label: input.label.trim(),
    front: input.front.trim(),
    back: input.back.trim(),
    hint: input.hint.trim(),
    createdAt: input.createdAt ?? Date.now(),
    studyMeta: input.studyMeta ?? {
      streak: 0,
      totalReviews: 0,
      hardCount: 0,
      mediumCount: 0,
      easyCount: 0,
      nextDueAt: Date.now(),
    },
  };
}

export const useFlashcardsStore = create(
  persist(
    (set, get) => ({
      cards: defaultCards,
      filters: {
        theme: "Todos",
        search: "",
      },
      themeStyles: defaultThemeStyles,
      session: {
        queue: [],
        currentIndex: 0,
        selectedTheme: "Todos",
        shuffle: false,
        reviewedCount: 0,
      },

      addCard: (payload) =>
        set((state) => ({
          cards: [normalizeCardInput(payload), ...state.cards],
          themeStyles: {
            ...state.themeStyles,
            [payload.theme]: payload.colorId ?? getThemeColorId(payload.theme, state.themeStyles),
          },
        })),

      updateCard: (cardId, payload) =>
        set((state) => {
          const currentCard = state.cards.find((card) => card.id === cardId);
          const nextTheme = payload.theme ?? currentCard?.theme ?? "Figuras de linguagem";
          const nextColorId = payload.colorId ?? currentCard?.colorId ?? getThemeColorId(nextTheme, state.themeStyles);

          return {
            cards: state.cards.map((card) =>
              card.id === cardId
                ? normalizeCardInput({ ...card, ...payload, id: cardId, theme: nextTheme, colorId: nextColorId })
                : card,
            ),
            themeStyles: {
              ...state.themeStyles,
              [nextTheme]: nextColorId,
            },
          };
        }),

      deleteCard: (cardId) =>
        set((state) => ({
          cards: state.cards.filter((card) => card.id !== cardId),
          session: {
            ...state.session,
            queue: state.session.queue.filter((id) => id !== cardId),
            currentIndex:
              state.session.currentIndex >= Math.max(0, state.session.queue.length - 1)
                ? Math.max(0, state.session.currentIndex - 1)
                : state.session.currentIndex,
          },
        })),

      setThemeFilter: (theme) =>
        set((state) => ({
          filters: {
            ...state.filters,
            theme,
          },
        })),

      setSearchFilter: (search) =>
        set((state) => ({
          filters: {
            ...state.filters,
            search,
          },
        })),

      startSession: ({ selectedTheme = "Todos", shuffle = false } = {}) =>
        set((state) => ({
          session: {
            queue: buildStudyQueue(state.cards, { selectedTheme, shuffle }),
            currentIndex: 0,
            selectedTheme,
            shuffle,
            reviewedCount: 0,
          },
        })),

      reshuffleSession: () =>
        set((state) => ({
          session: {
            ...state.session,
            queue: buildStudyQueue(state.cards, {
              selectedTheme: state.session.selectedTheme,
              shuffle: true,
            }),
            currentIndex: 0,
          },
        })),

      goToNextCard: () =>
        set((state) => ({
          session: {
            ...state.session,
            currentIndex: Math.min(state.session.currentIndex + 1, Math.max(0, state.session.queue.length - 1)),
          },
        })),

      goToPreviousCard: () =>
        set((state) => ({
          session: {
            ...state.session,
            currentIndex: Math.max(0, state.session.currentIndex - 1),
          },
        })),

      rateCurrentCard: (rating) => {
        const state = get();
        const cardId = state.session.queue[state.session.currentIndex];
        if (!cardId) {
          return;
        }

        const updatedCards = state.cards.map((card) =>
          card.id === cardId ? applyRatingToCard(card, rating) : card,
        );
        const updatedQueue = scheduleReviewedCard(state.session.queue, cardId, rating);

        set({
          cards: updatedCards,
          session: {
            ...state.session,
            queue: updatedQueue,
            currentIndex: Math.min(state.session.currentIndex, Math.max(0, updatedQueue.length - 1)),
            reviewedCount: state.session.reviewedCount + 1,
          },
        });
      },
    }),
    {
      name: "atlas-flashcards-store",
      storage: createJSONStorage(() => window.localStorage),
      partialize: (state) => ({
        cards: state.cards,
        filters: state.filters,
        themeStyles: state.themeStyles,
      }),
    },
  ),
);
