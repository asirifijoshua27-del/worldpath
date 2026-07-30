"use client";

import { markLeadHandledAction } from "@/app/actions/leads";

export function HandledToggle({ id, handled }: { id: string; handled: boolean }) {
  return (
    <form action={markLeadHandledAction}>
      <input type="hidden" name="id" value={id} />
      <input type="hidden" name="handled" value={(!handled).toString()} />
      <button
        type="submit"
        className={`text-xs px-3 py-1.5 rounded-full border transition-colors ${
          handled ? "border-line text-ink/50 hover:border-ink" : "border-teal text-teal hover:bg-teal/10"
        }`}
      >
        {handled ? "Mark not handled" : "Mark handled"}
      </button>
    </form>
  );
}
