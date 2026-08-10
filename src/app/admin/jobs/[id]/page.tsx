import { notFound } from "next/navigation";
import { getJobById } from "@/lib/repo";
import { updateJobAction } from "@/app/actions/jobs";
import { JobForm } from "../job-form";

export const dynamic = "force-dynamic";

export default async function EditJobPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const job = getJobById(id);
  if (!job) notFound();

  const action = updateJobAction.bind(null, job.id);

  return (
    <div>
      <h1 className="font-display text-3xl mb-8">Edit job listing</h1>
      <JobForm job={job} action={action} />
    </div>
  );
}
