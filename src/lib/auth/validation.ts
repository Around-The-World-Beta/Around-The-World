import { z } from "zod";

const email = z
  .string()
  .trim()
  .email("Enter a valid email address.")
  .max(254)
  .transform((value) => value.toLowerCase());

export const password = z
  .string()
  .min(12, "Use at least 12 characters.")
  .max(72, "Use no more than 72 characters.")
  .regex(/[a-z]/, "Add a lowercase letter.")
  .regex(/[A-Z]/, "Add an uppercase letter.")
  .regex(/[0-9]/, "Add a number.");

const captchaToken = z.string().trim().max(4096).optional();

export const signUpSchema = z.object({
  displayName: z
    .string()
    .trim()
    .min(2, "Enter your full name.")
    .max(60, "Name must be 60 characters or fewer."),
  email,
  password,
  acceptedTerms: z.literal(true, {
    error: "Accept the Terms and Privacy Policy to continue.",
  }),
  captchaToken,
});

export const signInSchema = z.object({
  email,
  password: z.string().min(1, "Enter your password.").max(72),
  captchaToken,
});

export const forgotPasswordSchema = z.object({
  email,
  captchaToken,
});

export const callbackSchema = z.object({
  code: z.string().min(8).max(2048),
  next: z.string().optional(),
});

export const safeReturnPathSchema = z
  .string()
  .max(500)
  .refine(
    (value) =>
      value.startsWith("/") &&
      !value.startsWith("//") &&
      !value.includes("\\") &&
      !value.includes("\0"),
    "Invalid return path.",
  );

export const profileSchema = z.object({
  displayName: z.string().trim().min(2).max(60),
  city: z.string().trim().max(100),
  bio: z.string().trim().max(200),
  favoritePosition: z
    .enum(["Goalkeeper", "Defender", "Midfielder", "Forward"])
    .nullable(),
  skillLevel: z
    .enum(["Casual", "Intermediate", "Baller", "Open to All"])
    .nullable(),
});

export const updatePasswordSchema = z.object({
  password,
});

export const deleteAccountSchema = z.object({
  confirmation: z.literal("DELETE"),
  password: z.string().max(72).optional(),
});

export const mfaCodeSchema = z.object({
  factorId: z.string().uuid(),
  code: z.string().regex(/^\d{6}$/, "Enter the six-digit code."),
});

export const factorIdSchema = z.object({
  factorId: z.string().uuid(),
});

