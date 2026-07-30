"use client";

import { useActionState } from "react";
import { saveImpactStoryAction, type FormState } from "@/app/actions/impact";
import { PhotoUploadField } from "@/components/photo-upload-field";
import { TARGET_LEVELS, TARGET_COUNTRIES } from "@/types";

export function ImpactStoryForm({
  story,
}: {
  story?: {
    id: string;
    studentName: string;
    headline: string;
    story: string;
    photoUrl: string | null;
    destinationCountry: string;
    targetLevel: string;
    featured: number;
  };
}) {
  const [state, formAction, pending] = useActionState<FormState, FormData>(saveImpactStoryAction, {});

  return (
    <form action={formAction} className="space-y-5 max-w-xl">
      {story && <input type="hidden" name="id" value={story.id} />}

      <div>
        <span className="block text-sm font-medium mb-1.5">Photo</span>
        <PhotoUploadField existingUrl={story?.photoUrl} />
      </div>

      <Field label="Student name">
        <input name="studentName" defaultValue={story?.studentName} required className="input" />
      </Field>

      <Field label="Headline">
        <input
          name="headline"
          defaultValue={story?.headline}
          required
          className="input"
          placeholder="e.g. From Kumasi to a full-ride at Boston University"
        />
      </Field>

      <Field label="Story">
        <textarea name="story" defaultValue={story?.story} required rows={6} className="input" />
      </Field>

      <div className="grid sm:grid-cols-2 gap-5">
        <Field label="Destination">
          <select name="destinationCountry" defaultValue={story?.destinationCountry || TARGET_COUNTRIES[0]} className="input">
            {TARGET_COUNTRIES.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Level">
          <select name="targetLevel" defaultValue={story?.targetLevel || "undergrad"} className="input">
            {TARGET_LEVELS.map((l) => (
              <option key={l.value} value={l.value}>
                {l.label}
              </option>
            ))}
          </select>
        </Field>
      </div>

      <label className="flex items-center gap-2 text-sm">
        <input type="checkbox" name="featured" defaultChecked={story ? story.featured === 1 : false} className="accent-teal" />
        Feature at the top of the Impact page
      </label>

      {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}
      {state.success && <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Saving..." : story ? "Save changes" : "Add story"}
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
