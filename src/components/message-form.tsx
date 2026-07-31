"use client";

import { useActionState, useRef, useState } from "react";
import type { FormState } from "@/app/actions/auth";

export function MessageForm({
  action,
  placeholder,
}: {
  action: (prevState: FormState, formData: FormData) => Promise<FormState>;
  placeholder: string;
}) {
  const [state, formAction, pending] = useActionState<FormState, FormData>(action, {});
  const [preview, setPreview] = useState<string | null>(null);
  const fileRef = useRef<HTMLInputElement>(null);
  const formRef = useRef<HTMLFormElement>(null);

  return (
    <form
      ref={formRef}
      action={async (formData) => {
        await formAction(formData);
        formRef.current?.reset();
        setPreview(null);
      }}
      className="space-y-3"
    >
      <textarea name="text" rows={2} placeholder={placeholder} className="input" />

      {preview && (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={preview} alt="Attachment preview" className="h-20 rounded-lg border border-line" />
      )}

      <div className="flex items-center justify-between gap-3">
        <label className="text-sm text-teal hover:underline cursor-pointer">
          {preview ? "Change picture" : "+ Attach a picture"}
          <input
            ref={fileRef}
            type="file"
            name="image"
            accept="image/jpeg,image/png,image/webp,image/gif"
            className="hidden"
            onChange={(e) => {
              const file = e.target.files?.[0];
              if (!file) return;
              const reader = new FileReader();
              reader.onload = () => setPreview(reader.result as string);
              reader.readAsDataURL(file);
            }}
          />
        </label>
        <button type="submit" disabled={pending} className="btn-secondary text-sm disabled:opacity-60">
          {pending ? "Sending..." : "Send"}
        </button>
      </div>

      {state.error && <p className="text-sm text-red-700">{state.error}</p>}
    </form>
  );
}

