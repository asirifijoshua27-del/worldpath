"use client";

import { useActionState } from "react";
import { setPasswordAction, type FormState } from "@/app/actions/auth";

const initialState: FormState = {};

export function VerifyForm({ token }: { token: string }) {
  const [state, formAction, pending] = useActionState(setPasswordAction, initialState);

  return (
    <form action={formAction} className="space-y-5">
      <input type="hidden" name="token" value={token} />
      <label className="block">
        <span className="block text-sm font-medium mb-1.5">New password</span>
        <input name="password" type="password" required minLength={8} className="input" />
      </label>
      <label className="block">
        <span className="block text-sm font-medium mb-1.5">Confirm password</span>
        <input name="confirmPassword" type="password" required minLength={8} className="input" />
      </label>
      {state.error && (
        <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>
      )}
      <button type="submit" disabled={pending} className="w-full btn-primary disabled:opacity-60">
        {pending ? "Saving..." : "Set password and continue"}
      </button>
    </form>
  );
}
