import Link from "next/link";
import { listAllJobs } from "@/lib/repo";
import { JOB_VERIFICATION_LABELS } from "@/types";
import { DeleteButton } from "@/components/delete-button";
import { deleteJobAction, toggleJobPublishedAction } from "@/app/actions/jobs";

export const dynamic = "force-dynamic";

export default function AdminJobsPage() {
  const jobs = listAllJobs();

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="font-display text-3xl mb-2">Job listings</h1>
          <p className="text-ink/60">
            Real, verified international job opportunities shown on the Work Visa page. Never publish a
            listing you haven't personally verified.
          </p>
        </div>
        <Link href="/admin/jobs/new" className="btn-primary">
          + Add job
        </Link>
      </div>

      <div className="divide-y divide-line border border-line rounded-xl">
        {jobs.length === 0 && <p className="p-6 text-sm text-ink/50 italic">No job listings yet.</p>}
        {jobs.map((j) => (
          <div key={j.id} className="p-4 flex items-center justify-between gap-4">
            <div>
              <p className="font-medium">
                {j.title} <span className="text-ink/50 font-normal">&middot; {j.employer}</span>
              </p>
              <p className="text-xs text-ink/50 mt-0.5">
                {j.country}
                {j.city ? ` \u00b7 ${j.city}` : ""} &middot; {JOB_VERIFICATION_LABELS[j.verificationStatus]}
                {j.published ? (
                  <span className="text-teal"> &middot; Published</span>
                ) : (
                  <span className="text-gold-deep"> &middot; Unpublished</span>
                )}
              </p>
            </div>
            <div className="flex items-center gap-4 text-sm shrink-0">
              <form action={toggleJobPublishedAction}>
                <input type="hidden" name="id" value={j.id} />
                <button type="submit" className="text-teal hover:underline">
                  {j.published ? "Unpublish" : "Publish"}
                </button>
              </form>
              <Link href={`/admin/jobs/${j.id}`} className="text-teal hover:underline">
                Edit
              </Link>
              <DeleteButton id={j.id} action={deleteJobAction} confirmLabel={`Delete "${j.title}" at ${j.employer}?`} />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
