import { useEffect, useRef } from "react";

import { getPublicAuthConfig } from "@/lib/auth/config";

declare global {
  interface Window {
    turnstile?: {
      render: (
        target: HTMLElement,
        options: {
          sitekey: string;
          callback: (token: string) => void;
          "expired-callback": () => void;
          "error-callback": () => void;
          theme: "dark" | "light" | "auto";
        },
      ) => string;
      remove: (widgetId: string) => void;
    };
  }
}

export function Turnstile({
  onToken,
}: {
  onToken: (token: string | undefined) => void;
}) {
  const hostRef = useRef<HTMLDivElement>(null);
  const siteKey = getPublicAuthConfig().turnstileSiteKey;

  useEffect(() => {
    if (!siteKey || !hostRef.current) return;
    let cancelled = false;
    let widgetId: string | undefined;
    let attempts = 0;

    const mount = () => {
      if (cancelled || !hostRef.current) return;
      if (!window.turnstile) {
        attempts += 1;
        if (attempts < 100) window.setTimeout(mount, 100);
        return;
      }
      widgetId = window.turnstile.render(hostRef.current, {
        sitekey: siteKey,
        callback: (token) => onToken(token),
        "expired-callback": () => onToken(undefined),
        "error-callback": () => onToken(undefined),
        theme: "dark",
      });
    };

    mount();
    return () => {
      cancelled = true;
      if (widgetId) window.turnstile?.remove(widgetId);
    };
  }, [siteKey, onToken]);

  if (!siteKey) return null;
  return <div ref={hostRef} className="flex min-h-16 justify-center" />;
}

