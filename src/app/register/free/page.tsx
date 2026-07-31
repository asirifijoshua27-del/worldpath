"use client";

import { useActionState, startTransition } from "react";
import Link from "next/link";
import { registerFreeAction, type FormState } from "@/app/actions/auth";
import { TARGET_COUNTRIES } from "@/types";
import { PhotoUploadField } from "@/components/photo-upload-field";

const initialState: FormState = {};

export default function FreeRegisterPage() {
  const [state, formAction, pending] = useActionState(registerFreeAction, initialState);

  // See the comment in /register/page.tsx: submitting manually (instead of
  // wiring `action` directly to the form) keeps the student's answers on
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
        <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">Free application program</p>
        <h1 className="font-display text-3xl mt-3 mb-2">For current Senior High School students</h1>
        <p className="text-sm text-ink/70 mb-8">
          Through our partnership with Wesley Senior High School, current SHS students get full
          undergraduate application support at no cost. You'll get a WorldPath student code and a
          link to verify your email and set a password.
        </p>

        <form onSubmit={handleSubmit} className="space-y-5">
          <div>
            <span className="block text-sm font-medium mb-1.5">Your photo</span>
            <PhotoUploadField />
          </div>

          <Field label="Full name">
            <input name="name" required className="input" placeholder="e.g. Ama Serwaa Owusu" />
          </Field>

          <Field label="Email address">
            <input name="email" type="email" required className="input" placeholder="you@example.com" />
          </Field>

          <Field label="Your school's name">
            <input name="schoolName" required className="input" placeholder="e.g. Wesley Senior High School" />
          </Field>

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
            {pending ? "Creating account..." : "Apply for free"}
          </button>
        </form>

        <p className="text-sm text-ink/60 mt-6">
          Not currently in Senior High School?{" "}
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

