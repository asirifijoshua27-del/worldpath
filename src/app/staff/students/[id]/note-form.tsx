"use client";

import { useActionState } from "react";
import { staffAddNoteAction } from "@/app/actions/staff";
import type { FormState } from "@/app/actions/auth";

export function NoteForm({ studentId }: { studentId: string }) {
  const action = staffAddNoteAction.bind(null, studentId);
  const [state, formAction, pending] = useActionState<FormState, FormData>(action, {});

  return (
    <form action={formAction} className="space-y-3">
      <textarea name="text" rows={3} required className="input" placeholder="Add a note for this student..." />
      {state.error && <p className="text-sm text-red-700">{state.error}</p>}
      <button type="submit" disabled={pending} className="btn-secondary text-sm disabled:opacity-60">
        {pending ? "Saving..." : "Add note"}
      </button>
    </form>
  );
}
