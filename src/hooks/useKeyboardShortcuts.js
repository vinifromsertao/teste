import { useEffect } from "react";

function getBindingHandler(bindings, event) {
  const directHandler = bindings[event.key];
  if (directHandler) {
    return directHandler;
  }

  if (event.code === "Space") {
    return bindings[" "] ?? bindings.Space ?? bindings.Spacebar;
  }

  return undefined;
}

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

      const handler = getBindingHandler(bindings, event);

      if (handler) {
        event.preventDefault();
        handler(event);
      }
    };

    window.addEventListener("keydown", listener);
    return () => window.removeEventListener("keydown", listener);
  }, [bindings]);
}
