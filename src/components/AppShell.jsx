export function AppShell({ header, children }) {
  return (
    <div className="relative min-h-screen overflow-hidden px-4 py-4 sm:px-6 lg:px-8">
      <div
        className="pointer-events-none absolute left-[-10%] top-24 h-72 w-72 rounded-full blur-3xl"
        style={{ background: "rgba(214, 159, 111, 0.18)" }}
      />
      <div
        className="pointer-events-none absolute right-[-8%] top-80 h-80 w-80 rounded-full blur-3xl"
        style={{ background: "rgba(76, 50, 37, 0.14)" }}
      />

      <div className="mx-auto flex min-h-[calc(100vh-2rem)] max-w-7xl flex-col gap-8 rounded-[36px] border border-[var(--border-soft)] bg-[var(--bg-secondary)]/70 px-5 py-5 shadow-[0_24px_80px_rgba(0,0,0,0.08)] backdrop-blur-xl sm:px-8 sm:py-8">
        <header>{header}</header>
        <main className="flex-1">{children}</main>
      </div>
    </div>
  );
}
