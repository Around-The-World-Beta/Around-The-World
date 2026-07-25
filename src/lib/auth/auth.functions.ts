import { createServerFn } from "@tanstack/react-start";
import { getRequestUrl } from "@tanstack/react-start/server";
import { redirect } from "@tanstack/react-router";

import {
  createSupabaseAdminClient,
  createSupabaseServerClient,
  markAuthResponsePrivate,
} from "./supabase.server";
import { isAuthConfigured, isTurnstileConfigured } from "./config";
import type { AppRole, Profile } from "./database.types";
import {
  callbackSchema,
  deleteAccountSchema,
  factorIdSchema,
  forgotPasswordSchema,
  mfaCodeSchema,
  profileSchema,
  safeReturnPathSchema,
  signInSchema,
  signUpSchema,
  updatePasswordSchema,
} from "./validation";

export interface SafeAuthUser {
  id: string;
  email: string;
  emailVerified: boolean;
  provider: string;
  role: AppRole;
}

export interface AuthState {
  configured: boolean;
  user: SafeAuthUser | null;
  profile: Profile | null;
  mfaRequired: boolean;
}

export interface AuthActionResult {
  ok: boolean;
  message: string;
  redirectTo?: string;
  mfaRequired?: boolean;
}

function safeNextPath(next: string | undefined, fallback = "/profile") {
  const parsed = safeReturnPathSchema.safeParse(next ?? fallback);
  return parsed.success ? parsed.data : fallback;
}

function getConfiguredSiteOrigin() {
  const configured = process.env.AUTH_SITE_URL?.trim();
  if (configured) return new URL(configured).origin;
  return getRequestUrl().origin;
}

function callbackUrl(next: string) {
  const url = new URL("/auth/callback", getConfiguredSiteOrigin());
  url.searchParams.set("next", safeNextPath(next));
  return url.toString();
}

function captchaIsMissing(token?: string) {
  return isTurnstileConfigured() && !token;
}

async function loadAuthState(): Promise<AuthState> {
  markAuthResponsePrivate();
  if (!isAuthConfigured()) {
    return {
      configured: false,
      user: null,
      profile: null,
      mfaRequired: false,
    };
  }

  const supabase = createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return {
      configured: true,
      user: null,
      profile: null,
      mfaRequired: false,
    };
  }

  const [{ data: profile }, { data: roleRow }, { data: aal }] =
    await Promise.all([
      supabase.from("profiles").select("*").eq("id", user.id).maybeSingle(),
      supabase
        .from("user_roles")
        .select("role")
        .eq("user_id", user.id)
        .maybeSingle(),
      supabase.auth.mfa.getAuthenticatorAssuranceLevel(),
    ]);

  const role = roleRow?.role ?? "user";
  const mfaRequired =
    aal?.nextLevel === "aal2" && aal.currentLevel !== "aal2";

  return {
    configured: true,
    user: {
      id: user.id,
      email: user.email ?? "",
      emailVerified: Boolean(user.email_confirmed_at),
      provider:
        typeof user.app_metadata.provider === "string"
          ? user.app_metadata.provider
          : "email",
      role,
    },
    profile: profile ?? null,
    mfaRequired,
  };
}

export const getAuthState = createServerFn({ method: "GET" }).handler(
  loadAuthState,
);

export const requireAuthenticatedUser = createServerFn({ method: "GET" })
  .validator((input: { returnTo: string }) => ({
    returnTo: safeNextPath(input.returnTo),
  }))
  .handler(async ({ data }) => {
    const state = await loadAuthState();
    if (!state.user) {
      throw redirect({
        to: "/auth",
        search: { mode: "login", next: data.returnTo, message: undefined },
      });
    }
    if (state.mfaRequired) {
      throw redirect({
        to: "/auth/mfa",
        search: { next: data.returnTo },
      });
    }
    return state;
  });

export const signUp = createServerFn({ method: "POST" })
  .validator((input: unknown) => signUpSchema.parse(input))
  .handler(async ({ data }): Promise<AuthActionResult> => {
    markAuthResponsePrivate();
    if (!isAuthConfigured()) {
      return { ok: false, message: "Accounts are not configured yet." };
    }
    if (captchaIsMissing(data.captchaToken)) {
      return { ok: false, message: "Complete the security check." };
    }

    const supabase = createSupabaseServerClient();
    const { error } = await supabase.auth.signUp({
      email: data.email,
      password: data.password,
      options: {
        emailRedirectTo: callbackUrl("/profile"),
        data: { display_name: data.displayName },
        captchaToken: data.captchaToken,
      },
    });

    if (error) {
      return {
        ok: false,
        message:
          error.status === 429
            ? "Too many attempts. Wait a few minutes and try again."
            : "We couldn't create the account. Check the details and try again.",
      };
    }

    return {
      ok: true,
      message:
        "Check your email to verify your account. For privacy, we show the same message if the address is already registered.",
    };
  });

export const signIn = createServerFn({ method: "POST" })
  .validator((input: unknown) => signInSchema.parse(input))
  .handler(async ({ data }): Promise<AuthActionResult> => {
    markAuthResponsePrivate();
    if (!isAuthConfigured()) {
      return { ok: false, message: "Accounts are not configured yet." };
    }
    if (captchaIsMissing(data.captchaToken)) {
      return { ok: false, message: "Complete the security check." };
    }

    const supabase = createSupabaseServerClient();
    const { error } = await supabase.auth.signInWithPassword({
      email: data.email,
      password: data.password,
      options: { captchaToken: data.captchaToken },
    });

    if (error) {
      return {
        ok: false,
        message:
          error.status === 429
            ? "Too many attempts. Wait a few minutes and try again."
            : "Email or password is incorrect.",
      };
    }

    const state = await loadAuthState();
    return {
      ok: true,
      message: "Signed in.",
      mfaRequired: state.mfaRequired,
    };
  });

export const beginAppleSignIn = createServerFn({ method: "POST" })
  .validator((input: { next?: string }) => ({
    next: safeNextPath(input.next),
  }))
  .handler(async ({ data }): Promise<AuthActionResult> => {
    markAuthResponsePrivate();
    if (!isAuthConfigured()) {
      return { ok: false, message: "Accounts are not configured yet." };
    }

    const supabase = createSupabaseServerClient();
    const { data: authData, error } = await supabase.auth.signInWithOAuth({
      provider: "apple",
      options: {
        redirectTo: callbackUrl(data.next),
        skipBrowserRedirect: true,
      },
    });

    if (error || !authData.url) {
      return {
        ok: false,
        message: "Sign in with Apple is unavailable right now.",
      };
    }

    return {
      ok: true,
      message: "Continue with Apple.",
      redirectTo: authData.url,
    };
  });

export const completeAuthCallback = createServerFn({ method: "POST" })
  .validator((input: unknown) => callbackSchema.parse(input))
  .handler(async ({ data }) => {
    markAuthResponsePrivate();
    if (!isAuthConfigured()) {
      throw redirect({
        to: "/auth",
        search: {
          mode: "login",
          next: undefined,
          message: "Accounts are not configured yet.",
        },
      });
    }

    const supabase = createSupabaseServerClient();
    const { error } = await supabase.auth.exchangeCodeForSession(data.code);
    if (error) {
      throw redirect({
        to: "/auth",
        search: {
          mode: "login",
          next: undefined,
          message: "That sign-in link is invalid or expired.",
        },
      });
    }

    const state = await loadAuthState();
    throw redirect({
      to: state.mfaRequired ? "/auth/mfa" : safeNextPath(data.next),
      search: state.mfaRequired ? { next: safeNextPath(data.next) } : undefined,
    });
  });

export const requestPasswordReset = createServerFn({ method: "POST" })
  .validator((input: unknown) => forgotPasswordSchema.parse(input))
  .handler(async ({ data }): Promise<AuthActionResult> => {
    markAuthResponsePrivate();
    if (!isAuthConfigured()) {
      return { ok: false, message: "Accounts are not configured yet." };
    }
    if (captchaIsMissing(data.captchaToken)) {
      return { ok: false, message: "Complete the security check." };
    }

    const supabase = createSupabaseServerClient();
    const { error } = await supabase.auth.resetPasswordForEmail(data.email, {
      redirectTo: callbackUrl("/auth/reset-password"),
      captchaToken: data.captchaToken,
    });

    if (error?.status === 429) {
      return {
        ok: false,
        message: "Too many attempts. Wait a few minutes and try again.",
      };
    }

    return {
      ok: true,
      message:
        "If an account matches that email, a password reset link is on its way.",
    };
  });

export const updatePassword = createServerFn({ method: "POST" })
  .validator((input: unknown) => updatePasswordSchema.parse(input))
  .handler(async ({ data }): Promise<AuthActionResult> => {
    markAuthResponsePrivate();
    const state = await loadAuthState();
    if (!state.user) return { ok: false, message: "Sign in again to continue." };

    const supabase = createSupabaseServerClient();
    const { error } = await supabase.auth.updateUser({
      password: data.password,
    });
    return error
      ? { ok: false, message: "The password could not be updated." }
      : { ok: true, message: "Your password has been updated." };
  });

export const updateProfile = createServerFn({ method: "POST" })
  .validator((input: unknown) => profileSchema.parse(input))
  .handler(async ({ data }): Promise<AuthActionResult> => {
    markAuthResponsePrivate();
    const state = await loadAuthState();
    if (!state.user || state.mfaRequired) {
      return { ok: false, message: "Sign in again to continue." };
    }

    const supabase = createSupabaseServerClient();
    const { error } = await supabase
      .from("profiles")
      .update({
        display_name: data.displayName,
        city: data.city || null,
        bio: data.bio || null,
        favorite_position: data.favoritePosition,
        skill_level: data.skillLevel,
        updated_at: new Date().toISOString(),
      })
      .eq("id", state.user.id);

    return error
      ? { ok: false, message: "Your profile could not be saved." }
      : { ok: true, message: "Profile saved." };
  });

export const signOut = createServerFn({ method: "POST" })
  .validator((input: { allDevices?: boolean }) => ({
    allDevices: Boolean(input.allDevices),
  }))
  .handler(async ({ data }): Promise<AuthActionResult> => {
    markAuthResponsePrivate();
    if (!isAuthConfigured()) return { ok: true, message: "Signed out." };
    const supabase = createSupabaseServerClient();
    const { error } = await supabase.auth.signOut({
      scope: data.allDevices ? "global" : "local",
    });
    return error
      ? { ok: false, message: "We couldn't sign you out. Try again." }
      : { ok: true, message: "Signed out." };
  });

export const getMfaFactors = createServerFn({ method: "GET" }).handler(
  async () => {
    markAuthResponsePrivate();
    const state = await loadAuthState();
    if (!state.user) return [];
    const supabase = createSupabaseServerClient();
    const { data } = await supabase.auth.mfa.listFactors();
    return data?.totp ?? [];
  },
);

export const enrollMfa = createServerFn({ method: "POST" }).handler(
  async () => {
    markAuthResponsePrivate();
    const state = await loadAuthState();
    if (!state.user) {
      return { ok: false as const, message: "Sign in again to continue." };
    }
    const supabase = createSupabaseServerClient();
    const { data, error } = await supabase.auth.mfa.enroll({
      factorType: "totp",
      friendlyName: "Around The World",
    });
    if (error) {
      return {
        ok: false as const,
        message: "Two-step verification could not be started.",
      };
    }
    return {
      ok: true as const,
      factorId: data.id,
      qrCode: data.totp.qr_code,
      secret: data.totp.secret,
    };
  },
);

export const verifyMfa = createServerFn({ method: "POST" })
  .validator((input: unknown) => mfaCodeSchema.parse(input))
  .handler(async ({ data }): Promise<AuthActionResult> => {
    markAuthResponsePrivate();
    const supabase = createSupabaseServerClient();
    const { error } = await supabase.auth.mfa.challengeAndVerify({
      factorId: data.factorId,
      code: data.code,
    });
    return error
      ? { ok: false, message: "That verification code is not valid." }
      : { ok: true, message: "Two-step verification confirmed." };
  });

export const unenrollMfa = createServerFn({ method: "POST" })
  .validator((input: unknown) => factorIdSchema.parse(input))
  .handler(async ({ data }): Promise<AuthActionResult> => {
    markAuthResponsePrivate();
    const state = await loadAuthState();
    if (!state.user || state.mfaRequired) {
      return { ok: false, message: "Complete verification first." };
    }
    const supabase = createSupabaseServerClient();
    const { error } = await supabase.auth.mfa.unenroll({
      factorId: data.factorId,
    });
    return error
      ? { ok: false, message: "Two-step verification could not be removed." }
      : { ok: true, message: "Two-step verification removed." };
  });

export const deleteAccount = createServerFn({ method: "POST" })
  .validator((input: unknown) => deleteAccountSchema.parse(input))
  .handler(async ({ data }): Promise<AuthActionResult> => {
    markAuthResponsePrivate();
    const state = await loadAuthState();
    if (!state.user || state.mfaRequired) {
      return { ok: false, message: "Sign in again to continue." };
    }

    const supabase = createSupabaseServerClient();
    if (state.user.provider === "email") {
      if (!data.password) {
        return { ok: false, message: "Enter your current password." };
      }
      const { error: reauthError } = await supabase.auth.signInWithPassword({
        email: state.user.email,
        password: data.password,
      });
      if (reauthError) {
        return { ok: false, message: "Current password is incorrect." };
      }
    } else {
      const {
        data: { user },
      } = await supabase.auth.getUser();
      const signedInAt = user?.last_sign_in_at
        ? new Date(user.last_sign_in_at).getTime()
        : 0;
      if (Date.now() - signedInAt > 10 * 60 * 1000) {
        return {
          ok: false,
          message:
            "For security, sign out and sign in with Apple again before deleting your account.",
        };
      }
    }

    const admin = createSupabaseAdminClient();
    await admin.from("audit_events").insert({
      actor_user_id: state.user.id,
      action: "account.deletion_requested",
      target_type: "account",
      target_id: state.user.id,
    });
    const { error } = await admin.auth.admin.deleteUser(state.user.id, false);
    if (error) {
      return {
        ok: false,
        message: "Your account could not be deleted. Contact support.",
      };
    }

    return { ok: true, message: "Your account has been deleted." };
  });
