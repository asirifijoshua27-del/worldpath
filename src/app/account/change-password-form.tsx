"use client";

import { useActionState } from "react";
import { changePasswordAction, type FormState } from "@/app/actions/account";

const initialState: FormState = {};

export function ChangePasswordForm() {
  const [state, formAction, pending] = useActionState(changePasswordAction, initialState);

  return (
    <form action={formAction} className="space-y-5 max-w-sm">
      <label className="block">
        <span className="block text-sm font-medium mb-1.5">Current password</span>
        <input name="currentPassword" type="password" required className="input" />
      </label>
      <label className="block">
        <span className="block text-sm font-medium mb-1.5">New password</span>
        <input name="newPassword" type="password" required minLength={8} className="input" />
      </label>
      <label className="block">
        <span className="block text-sm font-medium mb-1.5">Confirm new password</span>
        <input name="confirmPassword" type="password" required minLength={8} className="input" />
      </label>

      {state.error && (
        <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>
      )}
      {state.success && (
        <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>
      )}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Saving..." : "Update password"}
      </button>
    </form>
  );
}

