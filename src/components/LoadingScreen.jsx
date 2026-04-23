import { motion } from "framer-motion";

export function LoadingScreen() {
  return (
    <motion.div
      animate={{ opacity: 1 }}
      className="fixed inset-0 z-50 flex items-center justify-center bg-[var(--bg-primary)]"
      exit={{ opacity: 0 }}
      initial={{ opacity: 0 }}
      transition={{ duration: 0.4 }}
    >
      <div className="flex flex-col items-center gap-5">
        <motion.div
          animate={{ rotate: 360 }}
          className="flex h-24 w-24 items-center justify-center rounded-[32px] border border-[var(--border-soft)] bg-[var(--bg-card)] shadow-[var(--shadow-card)]"
          transition={{ duration: 2.4, repeat: Infinity, ease: "linear" }}
        >
          <motion.div
            animate={{ scale: [1, 1.08, 1] }}
            className="h-8 w-8 rounded-full bg-[var(--accent)]"
            transition={{ duration: 1.6, repeat: Infinity, ease: "easeInOut" }}
          />
        </motion.div>
        <div className="space-y-2 text-center">
          <p className="font-display text-3xl tracking-[-0.04em]">Preparando a revisão</p>
          <p className="text-sm uppercase tracking-[0.32em] text-[var(--text-muted)]">
            animação suave, foco absoluto
          </p>
        </div>
      </div>
    </motion.div>
  );
}
