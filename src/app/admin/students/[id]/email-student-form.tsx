"use client";

import { useActionState } from "react";
import { emailStudentAction, type FormState } from "@/app/actions/admin";

export function EmailStudentForm({ studentId, studentEmail }: { studentId: string; studentEmail: string }) {
  const action = emailStudentAction.bind(null, studentId);
  const [state, formAction, pending] = useActionState<FormState, FormData>(action, {});

  return (
    <form action={formAction} className="space-y-4 max-w-lg">
      <p className="text-sm text-ink/60">Sending to {studentEmail}</p>
      <label className="block">
        <span className="block text-sm font-medium mb-1.5">Subject</span>
        <input name="subject" required className="input" />
      </label>
      <label className="block">
        <span className="block text-sm font-medium mb-1.5">Message</span>
        <textarea name="body" required rows={6} className="input" />
      </label>
      <label className="block">
        <span className="block text-sm font-medium mb-1.5">Attachment (optional)</span>
        <input
          name="attachment"
          type="file"
          accept="image/jpeg,image/png,image/webp,image/gif,application/pdf,.doc,.docx"
          className="input"
        />
        <span className="block text-xs text-ink/50 mt-1">Up to 8MB.</span>
      </label>

      {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}
      {state.success && <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Sending..." : "Send email"}
      </button>
    </form>
  );
}

