"use client";

import { useActionState } from "react";
import { saveStaffAction, type FormState } from "@/app/actions/admin";
import { PhotoUploadField } from "@/components/photo-upload-field";

export function StaffForm({
  staff,
}: {
  staff?: { id: string; name: string; title: string; bio: string; photoUrl: string | null };
}) {
  const [state, formAction, pending] = useActionState<FormState, FormData>(saveStaffAction, {});

  return (
    <form action={formAction} className="space-y-5 max-w-xl">
      {staff && <input type="hidden" name="id" value={staff.id} />}
      <div>
        <span className="block text-sm font-medium mb-1.5">Photo</span>
        <PhotoUploadField existingUrl={staff?.photoUrl} />
      </div>
      <Field label="Name">
        <input name="name" defaultValue={staff?.name} required className="input" />
      </Field>
      <Field label="Title / role">
        <input name="title" defaultValue={staff?.title} required className="input" placeholder="e.g. Lead Counselor" />
      </Field>
      <Field label="Bio">
        <textarea name="bio" defaultValue={staff?.bio} rows={4} className="input" />
      </Field>

      {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}
      {state.success && <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Saving..." : staff ? "Save changes" : "Add staff member"}
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
