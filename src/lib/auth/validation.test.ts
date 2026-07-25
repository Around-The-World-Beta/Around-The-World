import { describe, expect, test } from "bun:test";

import {
  password,
  profileSchema,
  safeReturnPathSchema,
  signUpSchema,
} from "./validation";

describe("authentication validation", () => {
  test("accepts a strong password", () => {
    expect(password.safeParse("CorrectHorse9Battery").success).toBe(true);
  });

  test("rejects short and weak passwords", () => {
    expect(password.safeParse("password").success).toBe(false);
    expect(password.safeParse("alllowercasebutlong9").success).toBe(false);
  });

  test("normalizes signup emails", () => {
    const result = signUpSchema.parse({
      displayName: "Alex Rivera",
      email: " Alex@Example.COM ",
      password: "CorrectHorse9Battery",
      acceptedTerms: true,
    });
    expect(result.email).toBe("alex@example.com");
  });

  test("rejects off-site return paths", () => {
    expect(safeReturnPathSchema.safeParse("/profile").success).toBe(true);
    expect(safeReturnPathSchema.safeParse("//evil.example").success).toBe(false);
    expect(
      safeReturnPathSchema.safeParse("https://evil.example").success,
    ).toBe(false);
    expect(safeReturnPathSchema.safeParse("/\\evil").success).toBe(false);
  });

  test("limits profile fields that other players may see", () => {
    expect(
      profileSchema.safeParse({
        displayName: "Alex",
        city: "Brooklyn, NY",
        bio: "a".repeat(201),
        favoritePosition: "Midfielder",
        skillLevel: "Intermediate",
      }).success,
    ).toBe(false);
  });
});

