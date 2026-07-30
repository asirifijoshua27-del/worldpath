"use client";

import { useActionState } from "react";
import { updateSiteContentAction, type FormState } from "@/app/actions/admin";

export function ContentForm({
  content,
}: {
  content: {
    orgName: string;
    tagline: string;
    mission: string;
    vision: string;
    contactEmail: string;
    contactPhone: string;
    address: string;
    donateInfo: string;
  };
}) {
  const [state, formAction, pending] = useActionState<FormState, FormData>(updateSiteContentAction, {});

  return (
    <form action={formAction} className="space-y-5 max-w-2xl">
      <Field label="Organization name">
        <input name="orgName" defaultValue={content.orgName} required className="input" />
      </Field>
      <Field label="Tagline">
        <input name="tagline" defaultValue={content.tagline} required className="input" />
      </Field>
      <Field label="Mission">
        <textarea name="mission" defaultValue={content.mission} required rows={4} className="input" />
      </Field>
      <Field label="Vision">
        <textarea name="vision" defaultValue={content.vision} required rows={3} className="input" />
      </Field>
      <div className="grid sm:grid-cols-2 gap-5">
        <Field label="Contact email">
          <input name="contactEmail" type="email" defaultValue={content.contactEmail} required className="input" />
        </Field>
        <Field label="Contact phone">
          <input name="contactPhone" defaultValue={content.contactPhone} className="input" />
        </Field>
      </div>
      <Field label="Address">
        <input name="address" defaultValue={content.address} className="input" />
      </Field>
      <Field label="Donate details (bank account / mobile money — shown on the Get Involved page)">
        <textarea name="donateInfo" defaultValue={content.donateInfo} rows={4} className="input" />
      </Field>

      {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}
      {state.success && <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Saving..." : "Save changes"}
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
