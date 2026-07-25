import { createFileRoute } from "@tanstack/react-router";
import { z } from "zod";

import { completeAuthCallback } from "@/lib/auth/auth.functions";

const callbackSearchSchema = z.object({
  code: z.string().optional(),
  next: z.string().optional(),
});

export const Route = createFileRoute("/auth/callback")({
  validateSearch: callbackSearchSchema,
  loaderDeps: ({ search }) => search,
  loader: async ({ deps }) => {
    if (!deps.code) {
      throw new Error("The authentication link is missing its code.");
    }
    return completeAuthCallback({
      data: { code: deps.code, next: deps.next },
    });
  },
  head: () => ({
    meta: [
      { title: "Completing sign in — Around The World" },
      { name: "robots", content: "noindex" },
    ],
  }),
  component: CallbackPage,
});

function CallbackPage() {
  return (
    <main className="flex min-h-[100dvh] items-center justify-center px-5 text-center">
      <div>
        <div className="mx-auto size-10 animate-spin rounded-full border-2 border-border border-t-primary" />
        <p className="mt-4 text-sm text-muted-foreground">
          Completing secure sign in…
        </p>
      </div>
    </main>
  );
}

