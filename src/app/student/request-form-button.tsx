"use client";

import { useActionState } from "react";
import { requestApplicationFormAction } from "@/app/actions/student";
import type { FormState } from "@/app/actions/auth";

const initialState: FormState = {};

export function RequestFormButton() {
  const [state, formAction, pending] = useActionState(async (_prev: FormState) => requestApplicationFormAction(), initialState);

  if (state.success) {
    return <p className="text-sm text-teal">{state.success}</p>;
  }

  return (
    <form action={formAction}>
      <button type="submit" disabled={pending} className="btn-secondary text-sm disabled:opacity-60">
        {pending ? "Requesting..." : "Request application form"}
      </button>
      {state.error && <p className="text-sm text-red-700 mt-2">{state.error}</p>}
    </form>
  );
}

