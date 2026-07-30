"use client";

import { useRef } from "react";
import { staffUpdateStatusAction } from "@/app/actions/staff";
import { APPLICATION_STATUSES } from "@/types";

export function StatusSelect({ studentId, status }: { studentId: string; status: string }) {
  const formRef = useRef<HTMLFormElement>(null);

  return (
    <form ref={formRef} action={staffUpdateStatusAction}>
      <input type="hidden" name="studentId" value={studentId} />
      <select
        name="status"
        defaultValue={status}
        className="input"
        onChange={() => formRef.current?.requestSubmit()}
      >
        {APPLICATION_STATUSES.map((s) => (
          <option key={s.value} value={s.value}>
            {s.label}
          </option>
        ))}
      </select>
    </form>
  );
}
