"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { getSession } from "@/lib/auth";
import { createJob, updateJob, deleteJob, getJobById } from "@/lib/repo";
import { jobSchema } from "@/lib/validators";
import type { JobVerificationStatus } from "@/types";

export type FormState = { error?: string; success?: string };

async function requireAdmin() {
  const session = await getSession();
  if (!session || session.role !== "admin") {
    throw new Error("Not authorized");
  }
  return session;
}

function parseJobForm(formData: FormData) {
  return jobSchema.safeParse({
    title: String(formData.get("title") || ""),
    employer: String(formData.get("employer") || ""),
    country: String(formData.get("country") || ""),
    city: String(formData.get("city") || ""),
    industry: String(formData.get("industry") || ""),
    employmentType: String(formData.get("employmentType") || ""),
    experienceRequired: String(formData.get("experienceRequired") || ""),
    educationRequirement: String(formData.get("educationRequirement") || ""),
    languageRequirement: String(formData.get("languageRequirement") || ""),
    salary: String(formData.get("salary") || ""),
    sponsorshipInfo: String(formData.get("sponsorshipInfo") || ""),
    applicationDeadline: String(formData.get("applicationDeadline") || ""),
    lastVerifiedDate: String(formData.get("lastVerifiedDate") || ""),
    source: String(formData.get("source") || ""),
    verificationStatus: String(formData.get("verificationStatus") || "pending_verification") as JobVerificationStatus,
    applicationUrl: String(formData.get("applicationUrl") || ""),
    description: String(formData.get("description") || ""),
    published: formData.get("published") === "on",
  });
}

export async function createJobAction(_prev: FormState, formData: FormData): Promise<FormState> {
  await requireAdmin();
  const parsed = parseJobForm(formData);
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }
  const job = createJob({
    ...parsed.data,
    applicationDeadline: parsed.data.applicationDeadline || null,
    lastVerifiedDate: parsed.data.lastVerifiedDate || null,
  });
  revalidatePath("/admin/jobs");
  revalidatePath("/work-visa");
  redirect(`/admin/jobs/${job.id}`);
}

export async function updateJobAction(id: string, _prev: FormState, formData: FormData): Promise<FormState> {
  await requireAdmin();
  const parsed = parseJobForm(formData);
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }
  updateJob(id, {
    ...parsed.data,
    applicationDeadline: parsed.data.applicationDeadline || null,
    lastVerifiedDate: parsed.data.lastVerifiedDate || null,
  });
  revalidatePath("/admin/jobs");
  revalidatePath(`/admin/jobs/${id}`);
  revalidatePath("/work-visa");
  return { success: "Job listing updated." };
}

export async function deleteJobAction(id: string): Promise<void> {
  await requireAdmin();
  deleteJob(id);
  revalidatePath("/admin/jobs");
  revalidatePath("/work-visa");
}

export async function toggleJobPublishedAction(formData: FormData) {
  await requireAdmin();
  const id = String(formData.get("id") || "");
  const job = getJobById(id);
  if (!job) return;
  updateJob(id, { published: job.published ? 0 : 1 });
  revalidatePath("/admin/jobs");
  revalidatePath("/work-visa");
}
