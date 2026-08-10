"use client";

import { useActionState } from "react";
import { JOB_COUNTRIES, JOB_VERIFICATION_LABELS, type JobRecord } from "@/types";
import type { FormState } from "@/app/actions/jobs";

export function JobForm({
  job,
  action,
}: {
  job?: JobRecord;
  action: (prevState: FormState, formData: FormData) => Promise<FormState>;
}) {
  const [state, formAction, pending] = useActionState<FormState, FormData>(action, {});

  return (
    <form action={formAction} className="space-y-5 max-w-2xl">
      <div className="grid sm:grid-cols-2 gap-5">
        <Field label="Job title">
          <input name="title" defaultValue={job?.title} required className="input" placeholder="e.g. Registered Nurse" />
        </Field>
        <Field label="Employer">
          <input name="employer" defaultValue={job?.employer} required className="input" placeholder="e.g. Charite Berlin" />
        </Field>
      </div>

      <div className="grid sm:grid-cols-3 gap-5">
        <Field label="Country">
          <select name="country" defaultValue={job?.country ?? "USA"} className="input">
            {JOB_COUNTRIES.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>
        </Field>
        <Field label="City">
          <input name="city" defaultValue={job?.city} className="input" placeholder="e.g. Berlin" />
        </Field>
        <Field label="Industry">
          <input name="industry" defaultValue={job?.industry} className="input" placeholder="e.g. Healthcare" />
        </Field>
      </div>

      <div className="grid sm:grid-cols-2 gap-5">
        <Field label="Employment type">
          <input name="employmentType" defaultValue={job?.employmentType} className="input" placeholder="e.g. Full-time" />
        </Field>
        <Field label="Experience required">
          <input name="experienceRequired" defaultValue={job?.experienceRequired} className="input" placeholder="e.g. 2+ years" />
        </Field>
        <Field label="Education requirement">
          <input name="educationRequirement" defaultValue={job?.educationRequirement} className="input" placeholder="e.g. Bachelor's degree" />
        </Field>
        <Field label="Language requirement">
          <input name="languageRequirement" defaultValue={job?.languageRequirement} className="input" placeholder="e.g. English, German B2" />
        </Field>
        <Field label="Salary (only if publicly available)">
          <input name="salary" defaultValue={job?.salary} className="input" placeholder="Leave blank if not public" />
        </Field>
        <Field label="Sponsorship information">
          <input name="sponsorshipInfo" defaultValue={job?.sponsorshipInfo} className="input" placeholder="e.g. Verify eligibility" />
        </Field>
      </div>

      <div className="grid sm:grid-cols-2 gap-5">
        <Field label="Application deadline (optional)">
          <input type="date" name="applicationDeadline" defaultValue={job?.applicationDeadline ?? ""} className="input" />
        </Field>
        <Field label="Last verified date">
          <input type="date" name="lastVerifiedDate" defaultValue={job?.lastVerifiedDate ?? ""} className="input" />
        </Field>
      </div>

      <div className="grid sm:grid-cols-2 gap-5">
        <Field label="Source">
          <input name="source" defaultValue={job?.source} className="input" placeholder="e.g. Official employer careers page" />
        </Field>
        <Field label="Verification status">
          <select name="verificationStatus" defaultValue={job?.verificationStatus ?? "pending_verification"} className="input">
            {Object.entries(JOB_VERIFICATION_LABELS).map(([value, label]) => (
              <option key={value} value={value}>
                {label}
              </option>
            ))}
          </select>
        </Field>
      </div>

      <Field label="Application URL (the employer's real application page)">
        <input name="applicationUrl" type="url" defaultValue={job?.applicationUrl} className="input" placeholder="https://..." />
      </Field>

      <Field label="Description (optional)">
        <textarea name="description" defaultValue={job?.description} rows={5} className="input" />
      </Field>

      <label className="flex items-center gap-2 text-sm">
        <input type="checkbox" name="published" defaultChecked={job ? job.published === 1 : false} className="accent-teal" />
        Published (visible on the public Work Visa page)
      </label>

      {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}
      {state.success && <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Saving..." : job ? "Save changes" : "Add job"}
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
