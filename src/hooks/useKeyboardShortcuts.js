import { useEffect } from "react";

export function useKeyboardShortcuts(bindings) {
  useEffect(() => {
    const listener = (event) => {
      const target = event.target;
      const isTypingTarget =
        target instanceof HTMLElement &&
        (target.tagName === "INPUT" ||
          target.tagName === "TEXTAREA" ||
          target.isContentEditable);

      if (isTypingTarget) {
        return;
      }

      const key = event.key;
      const handler = bindings[key];

      if (handler) {
        event.preventDefault();
        handler(event);
      }
    };

    window.addEventListener("keydown", listener);
    return () => window.removeEventListener("keydown", listener);
  }, [bindings]);
}
