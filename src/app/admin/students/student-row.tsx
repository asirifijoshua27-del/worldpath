"use client";

import { useRef } from "react";
import { assignStudentAction, adminUpdateStatusAction } from "@/app/actions/admin";
import { APPLICATION_STATUSES } from "@/types";

export function StudentRow({
  student,
  staffOptions,
}: {
  student: {
    id: string;
    code: string;
    name: string;
    email: string;
    targetLevel: string;
    status: string;
    assignedStaffId: string | null;
    applicationType: string;
    schoolName: string;
  };
  staffOptions: { id: string; name: string }[];
}) {
  const assignFormRef = useRef<HTMLFormElement>(null);
  const statusFormRef = useRef<HTMLFormElement>(null);

  return (
    <tr className="border-b border-line last:border-0">
      <td className="py-3 pl-4 pr-4">
        <span className="font-mono text-xs bg-paper-dim border border-line rounded px-2 py-1">{student.code}</span>
      </td>
      <td className="py-3 pr-4">
        <p className="font-medium">{student.name}</p>
        <p className="text-xs text-ink/50">{student.email}</p>
      </td>
      <td className="py-3 pr-4">
        {student.applicationType === "free_shs" ? (
          <>
            <span className="text-xs uppercase tracking-wide text-gold-deep font-medium">Free Â· SHS</span>
            {student.schoolName && <p className="text-xs text-ink/50 mt-0.5">{student.schoolName}</p>}
          </>
        ) : (
          <span className="text-xs text-ink/50">Standard</span>
        )}
      </td>
      <td className="py-3 pr-4 text-sm capitalize">{student.targetLevel}</td>
      <td className="py-3 pr-4">
        <form ref={statusFormRef} action={adminUpdateStatusAction}>
          <input type="hidden" name="studentId" value={student.id} />
          <select
            name="status"
            defaultValue={student.status}
            className="input py-1.5 text-xs"
            onChange={() => statusFormRef.current?.requestSubmit()}
          >
            {APPLICATION_STATUSES.map((s) => (
              <option key={s.value} value={s.value}>
                {s.label}
              </option>
            ))}
          </select>
        </form>
      </td>
      <td className="py-3 pr-4">
        <form ref={assignFormRef} action={assignStudentAction}>
          <input type="hidden" name="studentId" value={student.id} />
          <select
            name="staffId"
            defaultValue={student.assignedStaffId ?? ""}
            className="input py-1.5 text-xs"
            onChange={() => assignFormRef.current?.requestSubmit()}
          >
            <option value="">Unassigned</option>
            {staffOptions.map((s) => (
              <option key={s.id} value={s.id}>
                {s.name}
              </option>
            ))}
          </select>
        </form>
      </td>
    </tr>
  );
}

