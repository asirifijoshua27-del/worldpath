"use client";

import { useState, useTransition } from "react";
import { saveJobAction } from "@/app/actions/jobs";
import { JOB_VERIFICATION_LABELS, type JobRecord } from "@/types";

export function JobBrowseList({
  jobs,
  savedJobIds,
}: {
  jobs: JobRecord[];
  savedJobIds: string[];
}) {
  const [saved, setSaved] = useState<Set<string>>(new Set(savedJobIds));
  const [pending, startTransition] = useTransition();

  function handleSave(jobId: string) {
    startTransition(async () => {
      await saveJobAction(jobId);
      setSaved((prev) => new Set(prev).add(jobId));
    });
  }

  if (jobs.length === 0) {
    return <p className="text-sm text-ink/50 italic">No published opportunities yet - check back soon.</p>;
  }

  return (
    <div className="grid sm:grid-cols-2 gap-4">
      {jobs.map((job) => {
        const isSaved = saved.has(job.id);
        return (
          <div key={job.id} className="border border-line rounded-xl p-4">
            <div className="flex items-start justify-between gap-2 mb-1">
              <p className="font-medium text-sm">{job.title}</p>
              <span className="text-[10px] uppercase tracking-wide text-teal shrink-0 mt-0.5">
                {JOB_VERIFICATION_LABELS[job.verificationStatus]}
              </span>
            </div>
            <p className="text-xs text-ink/60 mb-3">
              {job.employer} &middot; {job.country}
              {job.city ? `, ${job.city}` : ""}
            </p>
            <button
              type="button"
              disabled={isSaved || pending}
              onClick={() => handleSave(job.id)}
              className="text-xs text-teal hover:underline disabled:no-underline disabled:text-ink/40"
            >
              {isSaved ? "Saved" : "Save this opportunity"}
            </button>
          </div>
        );
      })}
    </div>
  );
}
