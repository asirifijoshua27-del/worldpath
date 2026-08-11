"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { getSession } from "@/lib/auth";
import {
  createJob,
  updateJob,
  deleteJob,
  getJobById,
  getStudentByUserId,
  saveJobForStudent,
  getJobApplicationById,
  updateJobApplicationStatus,
  withdrawJobApplication,
  getStaffByUserId,
  getStudentById,
} from "@/lib/repo";
import { notifyUser } from "@/lib/notify";
import { jobSchema } from "@/lib/validators";
import type { JobVerificationStatus, JobApplicationStatus } from "@/types";

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

// ---------- Student-facing: saving jobs and tracking applications ----------

async function requireWorkVisaStudent() {
  const session = await getSession();
  if (!session || session.role !== "student") {
    throw new Error("Not authorized");
  }
  const student = getStudentByUserId(session.userId);
  if (!student) {
    throw new Error("No application record found");
  }
  return { session, student };
}

export async function saveJobAction(jobId: string): Promise<void> {
  const { student } = await requireWorkVisaStudent();
  saveJobForStudent(student.id, jobId);
  revalidatePath("/student");
}

export async function updateMyApplicationStatusAction(applicationId: string, formData: FormData): Promise<void> {
  const { student } = await requireWorkVisaStudent();
  const application = getJobApplicationById(applicationId);
  if (!application || application.studentId !== student.id) {
    throw new Error("Not authorized for this application");
  }
  const status = String(formData.get("status") || "") as JobApplicationStatus;
  updateJobApplicationStatus(applicationId, status);
  revalidatePath("/student");
}

export async function withdrawMyApplicationAction(applicationId: string): Promise<void> {
  const { student } = await requireWorkVisaStudent();
  const application = getJobApplicationById(applicationId);
  if (!application || application.studentId !== student.id) {
    throw new Error("Not authorized for this application");
  }
  withdrawJobApplication(applicationId);
  revalidatePath("/student");
}

// ---------- Staff/admin: updating an applicant's job application status ----------

export async function staffUpdateApplicationStatusAction(applicationId: string, formData: FormData): Promise<void> {
  const session = await getSession();
  if (!session || (session.role !== "staff" && session.role !== "admin")) {
    throw new Error("Not authorized");
  }
  const application = getJobApplicationById(applicationId);
  if (!application) return;

  if (session.role === "staff") {
    const staff = getStaffByUserId(session.userId);
    const student = getStudentById(application.studentId);
    if (!staff || !student || student.assignedStaffId !== staff.id) {
      throw new Error("Not authorized for this student");
    }
  }

  const status = String(formData.get("status") || "") as JobApplicationStatus;
  updateJobApplicationStatus(applicationId, status);

  const student = getStudentById(application.studentId);
  const job = getJobById(application.jobId);
  if (student && job) {
    await notifyUser({
      userId: student.userId,
      type: "status_changed",
      title: `Application update: ${job.title}`,
      body: `Your application to ${job.employer} is now "${status.replace(/_/g, " ")}".`,
      link: "/student",
    });
  }

  revalidatePath(`/staff/students/${application.studentId}`);
  revalidatePath(`/admin/students/${application.studentId}`);
}
