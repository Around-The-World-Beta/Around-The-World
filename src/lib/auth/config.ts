export interface PublicAuthConfig {
  supabaseUrl: string;
  supabasePublishableKey: string;
  turnstileSiteKey: string;
}

export function getPublicAuthConfig(): PublicAuthConfig {
  return {
    supabaseUrl: import.meta.env.VITE_SUPABASE_URL?.trim() ?? "",
    supabasePublishableKey:
      import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY?.trim() ?? "",
    turnstileSiteKey:
      import.meta.env.VITE_TURNSTILE_SITE_KEY?.trim() ?? "",
  };
}

export function isAuthConfigured(): boolean {
  const config = getPublicAuthConfig();
  return Boolean(config.supabaseUrl && config.supabasePublishableKey);
}

export function isTurnstileConfigured(): boolean {
  return Boolean(getPublicAuthConfig().turnstileSiteKey);
}

