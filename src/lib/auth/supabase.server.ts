import { createServerClient, type CookieOptions } from "@supabase/ssr";
import { createClient } from "@supabase/supabase-js";
import {
  getCookies,
  setCookie,
  setResponseHeader,
} from "@tanstack/react-start/server";

import { getPublicAuthConfig } from "./config";
import type { Database } from "./database.types";

function requirePublicConfig() {
  const config = getPublicAuthConfig();
  if (!config.supabaseUrl || !config.supabasePublishableKey) {
    throw new Error("Authentication is not configured for this environment.");
  }
  return config;
}

export function createSupabaseServerClient() {
  const config = requirePublicConfig();

  return createServerClient<Database>(
    config.supabaseUrl,
    config.supabasePublishableKey,
    {
      cookies: {
        getAll() {
          return Object.entries(getCookies()).map(([name, value]) => ({
            name,
            value,
          }));
        },
        setAll(cookiesToSet) {
          for (const { name, value, options } of cookiesToSet) {
            setCookie(name, value, {
              ...(options as CookieOptions),
              sameSite: options.sameSite ?? "lax",
              secure:
                options.secure ??
                (process.env.APP_ENV === "production"),
            });
          }
        },
      },
    },
  );
}

export function createSupabaseAdminClient() {
  const config = requirePublicConfig();
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY?.trim();

  if (!serviceRoleKey) {
    throw new Error(
      "Account administration is not configured for this environment.",
    );
  }

  return createClient<Database>(config.supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
      detectSessionInUrl: false,
    },
  });
}

export function markAuthResponsePrivate() {
  setResponseHeader("Cache-Control", "no-store");
  setResponseHeader("Vary", "Cookie, Authorization");
}

