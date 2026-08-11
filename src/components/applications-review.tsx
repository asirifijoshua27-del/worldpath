"use client";

import { useTransition } from "react";
import { staffUpdateApplicationStatusAction } from "@/app/actions/jobs";
import { JOB_APPLICATION_STATUSES, type JobApplicationStatus, type JobRecord } from "@/types";

interface TrackedApplication {
  id: string;
  status: JobApplicationStatus;
  job: JobRecord;
}

export function ApplicationsReview({ applications }: { applications: TrackedApplication[] }) {
  const [pending, startTransition] = useTransition();

  function handleStatusChange(applicationId: string, formData: FormData) {
    startTransition(() => staffUpdateApplicationStatusAction(applicationId, formData));
  }

  if (applications.length === 0) {
    return <p className="text-sm text-ink/50 italic">This applicant hasn't saved or applied to any job listings yet.</p>;
  }

  return (
    <div className="space-y-3">
      {applications.map((app) => (
        <div key={app.id} className="border border-line rounded-xl p-4 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
          <div>
            <p className="font-medium text-sm">{app.job.title}</p>
            <p className="text-xs text-ink/60">
              {app.job.employer} &middot; {app.job.country}
              {app.job.city ? `, ${app.job.city}` : ""}
            </p>
          </div>
          <form action={(fd) => handleStatusChange(app.id, fd)}>
            <select
              name="status"
              defaultValue={app.status}
              disabled={pending}
              onChange={(e) => e.currentTarget.form?.requestSubmit()}
              className="input py-1.5 text-xs"
            >
              {JOB_APPLICATION_STATUSES.map((s) => (
                <option key={s.value} value={s.value}>
                  {s.label}
                </option>
              ))}
            </select>
          </form>
        </div>
      ))}
    </div>
  );
}
