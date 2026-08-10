import { createJobAction } from "@/app/actions/jobs";
import { JobForm } from "../job-form";

export default function NewJobPage() {
  return (
    <div>
      <h1 className="font-display text-3xl mb-8">Add a job listing</h1>
      <JobForm action={createJobAction} />
    </div>
  );
}
