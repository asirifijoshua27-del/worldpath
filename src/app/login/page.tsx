"use client";

import { useActionState } from "react";
import Link from "next/link";
import { loginAction, type FormState } from "@/app/actions/auth";

const initialState: FormState = {};

export default function LoginPage() {
  const [state, formAction, pending] = useActionState(loginAction, initialState);

  return (
    <main className="flex-1 flex items-center justify-center px-6 py-16">
      <div className="w-full max-w-sm">
        <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">Welcome back</p>
        <h1 className="font-display text-3xl mt-3 mb-8">Log in</h1>

        <form action={formAction} className="space-y-5">
          <label className="block">
            <span className="block text-sm font-medium mb-1.5">Email</span>
            <input name="email" type="email" required className="input" />
          </label>
          <label className="block">
            <span className="block text-sm font-medium mb-1.5">Password</span>
            <input name="password" type="password" required className="input" />
          </label>

          {state.error && (
            <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">
              {state.error}
            </p>
          )}

          <button type="submit" disabled={pending} className="w-full btn-primary disabled:opacity-60">
            {pending ? "Logging in..." : "Log in"}
          </button>
        </form>

        <p className="text-sm text-ink/60 mt-6">
          New student?{" "}
          <Link href="/register" className="text-teal hover:underline">
            Create an account
          </Link>
        </p>
      </div>
    </main>
  );
}
