"use client";

import { useActionState } from "react";
import { broadcastMessageAction } from "@/app/actions/admin";
import type { FormState } from "@/app/actions/auth";

const initialState: FormState = {};

export function BroadcastForm() {
  const [state, formAction, pending] = useActionState<FormState, FormData>(broadcastMessageAction, initialState);

  return (
    <form action={formAction} className="space-y-5 max-w-lg">
      <label className="block">
        <span className="block text-sm font-medium mb-1.5">Send to</span>
        <select name="group" className="input" defaultValue="all">
          <option value="university">Students (university & scholarship applicants)</option>
          <option value="work_visa">Work visa applicants</option>
          <option value="all">Everyone (both groups)</option>
        </select>
      </label>

      <label className="block">
        <span className="block text-sm font-medium mb-1.5">Subject</span>
        <input name="subject" required className="input" />
      </label>

      <label className="block">
        <span className="block text-sm font-medium mb-1.5">Message</span>
        <textarea name="body" required rows={7} className="input" />
      </label>

      <label className="block">
        <span className="block text-sm font-medium mb-1.5">Attachment (optional)</span>
        <input
          name="attachment"
          type="file"
          accept="image/jpeg,image/png,image/webp,image/gif,application/pdf,.doc,.docx"
          className="input"
        />
        <span className="block text-xs text-ink/50 mt-1">Up to 8MB. Sent to every recipient.</span>
      </label>

      {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}
      {state.success && <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Sending..." : "Send to group"}
      </button>
    </form>
  );
}
