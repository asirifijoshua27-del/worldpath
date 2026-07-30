"use client";

import { useActionState } from "react";
import { createStaffUserAction, type FormState } from "@/app/actions/admin";

export function CreateStaffUserForm() {
  const [state, formAction, pending] = useActionState<FormState, FormData>(createStaffUserAction, {});

  return (
    <form action={formAction} className="space-y-5 max-w-lg border border-line rounded-xl p-6">
      <h2 className="font-display text-xl">Create a staff account</h2>
      <Field label="Full name">
        <input name="name" required className="input" />
      </Field>
      <Field label="Email">
        <input name="email" type="email" required className="input" />
      </Field>
      <Field label="Username">
        <input name="username" required className="input" />
      </Field>
      <Field label="Title / role">
        <input name="title" required className="input" placeholder="e.g. Application Counselor" />
      </Field>
      <Field label="Short bio (optional)">
        <textarea name="bio" rows={2} className="input" />
      </Field>
      <Field label="Temporary password">
        <input name="tempPassword" type="text" required minLength={8} className="input" />
      </Field>

      {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}
      {state.success && <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Creating..." : "Create staff account"}
      </button>
    </form>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="block text-sm font-medium mb-1.5">{label}</span>
      {children}
    </label>
  );
}
