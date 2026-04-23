import { useEffect, useState } from "react";

const THEME_KEY = "atlas-theme";

function getInitialTheme() {
  if (typeof window === "undefined") {
    return "system";
  }

  return window.localStorage.getItem(THEME_KEY) ?? "system";
}

function resolveTheme(theme) {
  if (theme !== "system") {
    return theme;
  }

  if (typeof window === "undefined") {
    return "light";
  }

  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}

export function useTheme() {
  const [theme, setThemeState] = useState(getInitialTheme);
  const [effectiveTheme, setEffectiveTheme] = useState(resolveTheme(theme));

  useEffect(() => {
    const media = window.matchMedia("(prefers-color-scheme: dark)");

    const syncTheme = () => {
      const next = resolveTheme(theme);
      setEffectiveTheme(next);
      document.documentElement.classList.toggle("dark", next === "dark");
    };

    syncTheme();

    const listener = () => {
      if (theme === "system") {
        syncTheme();
      }
    };

    media.addEventListener("change", listener);

    return () => media.removeEventListener("change", listener);
  }, [theme]);

  const setTheme = (value) => {
    setThemeState(value);
    window.localStorage.setItem(THEME_KEY, value);
  };

  const toggleTheme = () => {
    const next = effectiveTheme === "dark" ? "light" : "dark";
    setTheme(next);
  };

  return {
    theme,
    effectiveTheme,
    setTheme,
    toggleTheme,
  };
}
