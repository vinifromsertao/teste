const ratingConfig = {
  hard: {
    label: "Dificil",
    intervalMs: 2 * 60 * 60 * 1000,
    reinsertionOffset: 2,
    streakDelta: 0,
  },
  medium: {
    label: "Medio",
    intervalMs: 18 * 60 * 60 * 1000,
    reinsertionOffset: 4,
    streakDelta: 1,
  },
  easy: {
    label: "Facil",
    intervalMs: 3 * 24 * 60 * 60 * 1000,
    reinsertionOffset: 7,
    streakDelta: 2,
  },
};

export function getRatingConfig(rating) {
  return ratingConfig[rating] ?? ratingConfig.medium;
}

export function applyRatingToCard(card, rating) {
  const config = getRatingConfig(rating);
  const now = Date.now();
  const studyMeta = card.studyMeta ?? {};

  return {
    ...card,
    studyMeta: {
      streak: Math.max(0, (studyMeta.streak ?? 0) + config.streakDelta),
      totalReviews: (studyMeta.totalReviews ?? 0) + 1,
      hardCount: (studyMeta.hardCount ?? 0) + (rating === "hard" ? 1 : 0),
      mediumCount: (studyMeta.mediumCount ?? 0) + (rating === "medium" ? 1 : 0),
      easyCount: (studyMeta.easyCount ?? 0) + (rating === "easy" ? 1 : 0),
      lastReviewedAt: now,
      nextDueAt: now + config.intervalMs,
      lastRating: rating,
    },
  };
}

export function scheduleReviewedCard(queue, cardId, rating) {
  const config = getRatingConfig(rating);
  const nextQueue = queue.filter((id) => id !== cardId);
  const insertAt = Math.min(nextQueue.length, config.reinsertionOffset);

  nextQueue.splice(insertAt, 0, cardId);
  return nextQueue;
}

export function buildStudyQueue(cards, { selectedTheme = "Todos", shuffle = false } = {}) {
  const now = Date.now();
  const filtered = cards.filter((card) => selectedTheme === "Todos" || card.theme === selectedTheme);

  const sorted = [...filtered].sort((a, b) => {
    const aMeta = a.studyMeta ?? {};
    const bMeta = b.studyMeta ?? {};
    const aDue = (aMeta.nextDueAt ?? 0) <= now;
    const bDue = (bMeta.nextDueAt ?? 0) <= now;

    if (aDue !== bDue) {
      return aDue ? -1 : 1;
    }

    const aPressure = (aMeta.hardCount ?? 0) * 3 + (aMeta.mediumCount ?? 0) - (aMeta.easyCount ?? 0) * 2;
    const bPressure = (bMeta.hardCount ?? 0) * 3 + (bMeta.mediumCount ?? 0) - (bMeta.easyCount ?? 0) * 2;

    if (aPressure !== bPressure) {
      return bPressure - aPressure;
    }

    return (aMeta.lastReviewedAt ?? 0) - (bMeta.lastReviewedAt ?? 0);
  });

  const ids = sorted.map((card) => card.id);

  if (!shuffle) {
    return ids;
  }

  for (let index = ids.length - 1; index > 0; index -= 1) {
    const target = Math.floor(Math.random() * (index + 1));
    [ids[index], ids[target]] = [ids[target], ids[index]];
  }

  return ids;
}
