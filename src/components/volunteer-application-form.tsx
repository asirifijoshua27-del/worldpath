"use client";

import { useActionState } from "react";
import { submitLeadAction, type FormState } from "@/app/actions/leads";
import { VOLUNTEER_AREAS } from "@/types";

export function VolunteerApplicationForm() {
  const [state, formAction, pending] = useActionState<FormState, FormData>(submitLeadAction, {});

  if (state.success) {
    return <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>;
  }

  return (
    <form action={formAction} className="space-y-5">
      <input type="hidden" name="type" value="volunteer" />

      <div className="grid sm:grid-cols-2 gap-4">
        <Field label="Your name">
          <input name="name" required placeholder="Full name" className="input" />
        </Field>
        <Field label="Email address">
          <input name="email" type="email" required placeholder="you@example.com" className="input" />
        </Field>
      </div>

      <Field label="Phone (optional)">
        <input name="phone" placeholder="e.g. 024 000 0000" className="input" />
      </Field>

      <Field label="What would you like to help with? (choose all that apply)">
        <div className="grid sm:grid-cols-2 gap-2">
          {VOLUNTEER_AREAS.map((area) => (
            <label key={area} className="flex items-center gap-2 text-sm border border-line rounded-lg px-3 py-2">
              <input type="checkbox" name="areasOfInterest" value={area} className="accent-teal" />
              {area}
            </label>
          ))}
        </div>
      </Field>

      <Field label="Your availability (optional)">
        <input name="availability" placeholder="e.g. Weekday evenings, 2-3 hours/week" className="input" />
      </Field>

      <Field label="Anything else you'd like us to know? (optional)">
        <textarea name="message" rows={3} placeholder="Your background, motivation, or questions..." className="input" />
      </Field>

      {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Submitting..." : "Submit application"}
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

