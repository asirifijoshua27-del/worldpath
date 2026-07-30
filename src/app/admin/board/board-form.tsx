"use client";

import { useActionState } from "react";
import { saveBoardMemberAction, type FormState } from "@/app/actions/admin";
import { PhotoUploadField } from "@/components/photo-upload-field";

export function BoardMemberForm({
  member,
}: {
  member?: { id: string; name: string; title: string; bio: string; photoUrl: string | null };
}) {
  const [state, formAction, pending] = useActionState<FormState, FormData>(saveBoardMemberAction, {});

  return (
    <form action={formAction} className="space-y-5 max-w-xl">
      {member && <input type="hidden" name="id" value={member.id} />}
      <div>
        <span className="block text-sm font-medium mb-1.5">Photo</span>
        <PhotoUploadField existingUrl={member?.photoUrl} />
      </div>
      <Field label="Name">
        <input name="name" defaultValue={member?.name} required className="input" />
      </Field>
      <Field label="Title / role">
        <input name="title" defaultValue={member?.title} required className="input" placeholder="e.g. Board Chair" />
      </Field>
      <Field label="Bio">
        <textarea name="bio" defaultValue={member?.bio} rows={4} className="input" />
      </Field>

      {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}
      {state.success && <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Saving..." : member ? "Save changes" : "Add board member"}
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
