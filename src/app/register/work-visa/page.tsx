"use client";

import { useActionState, startTransition } from "react";
import Link from "next/link";
import { registerWorkVisaAction, type FormState } from "@/app/actions/auth";
import { TARGET_COUNTRIES, YEARS_EXPERIENCE_OPTIONS } from "@/types";
import { PhotoUploadField } from "@/components/photo-upload-field";

const initialState: FormState = {};

export default function WorkVisaRegisterPage() {
  const [state, formAction, pending] = useActionState(registerWorkVisaAction, initialState);

  // See the comment in /register/page.tsx: submitting manually (instead of
  // wiring `action` directly to the form) keeps the applicant's answers on
  // screen if a field needs fixing, rather than wiping the whole form.
  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    startTransition(() => {
      formAction(formData);
    });
  }

  return (
    <main className="flex-1 flex items-start justify-center py-16 px-6">
      <div className="w-full max-w-lg">
        <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">Work visa support</p>
        <h1 className="font-display text-3xl mt-3 mb-2">Apply for work visa guidance</h1>
        <p className="text-sm text-ink/70 mb-8">
          For any Ghanaian pursuing a work visa abroad, in any profession or destination. You'll get
          a WorldPath applicant code, your own portal, and a counselor to guide your application.
        </p>

        <form onSubmit={handleSubmit} className="space-y-5">
          <div>
            <span className="block text-sm font-medium mb-1.5">Your photo</span>
            <PhotoUploadField />
          </div>

          <Field label="Full name">
            <input name="name" required className="input" placeholder="e.g. Kwame Owusu" />
          </Field>

          <Field label="Email address">
            <input name="email" type="email" required className="input" placeholder="you@example.com" />
          </Field>

          <Field label="Phone number">
            <input name="phone" type="tel" required className="input" placeholder="e.g. 024 000 0000" />
          </Field>

          <Field label="Profession / field">
            <input name="profession" required className="input" placeholder="e.g. Nursing, Software Engineering, Hospitality" />
          </Field>

          <Field label="Current occupation (optional)">
            <input name="currentOccupation" className="input" placeholder="e.g. Staff Nurse at Korle Bu" />
          </Field>

          <Field label="Years of experience">
            <select name="yearsExperience" required className="input" defaultValue="">
              <option value="" disabled>
                Select...
              </option>
              {YEARS_EXPERIENCE_OPTIONS.map((y) => (
                <option key={y} value={y}>
                  {y}
                </option>
              ))}
            </select>
          </Field>

          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" name="hasJobOffer" className="accent-teal" />
            I already have a job offer from an employer abroad
          </label>

          <Field label="Destination countries (choose all that interest you)">
            <div className="grid grid-cols-2 gap-2">
              {TARGET_COUNTRIES.map((c) => (
                <label key={c} className="flex items-center gap-2 text-sm border border-line rounded-lg px-3 py-2">
                  <input type="checkbox" name="targetCountries" value={c} className="accent-teal" />
                  {c}
                </label>
              ))}
            </div>
          </Field>

          {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}

          <button
            type="submit"
            disabled={pending}
            className="w-full rounded-full bg-ink text-paper px-6 py-3 hover:bg-teal transition-colors disabled:opacity-60"
          >
            {pending ? "Creating account..." : "Apply for work visa support"}
          </button>
        </form>

        <p className="text-sm text-ink/60 mt-6">
          Applying for university or a scholarship instead?{" "}
          <Link href="/register" className="text-teal hover:underline">
            Use the standard application
          </Link>
        </p>
      </div>
    </main>
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
