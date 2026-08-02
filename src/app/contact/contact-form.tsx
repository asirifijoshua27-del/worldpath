"use client";

import { useActionState } from "react";
import { submitLeadAction, type FormState } from "@/app/actions/leads";

export function ContactForm() {
  const [state, formAction, pending] = useActionState<FormState, FormData>(submitLeadAction, {});

  if (state.success) {
    return <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>;
  }

  return (
    <form action={formAction} className="space-y-4">
      <input type="hidden" name="type" value="contact" />
      <input name="name" required placeholder="Your name" className="input" />
      <input name="email" type="email" required placeholder="Email address" className="input" />
      <textarea name="message" required rows={4} placeholder="How can we help?" className="input" />

      {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Sending..." : "Send message"}
      </button>
    </form>
  );
}

