# WorldPath Group - Phase 2b/2c: applicants can now save and track job
# applications through the full 9-stage pipeline (Saved through Accepted/
# Not Selected), with self-service status updates from students and
# oversight/updates from staff and admin. Status changes notify the
# student automatically (in-app + email, using the existing system).
# Run this from inside your worldpath project folder (where package.json lives)

$ErrorActionPreference = 'Stop'
[System.IO.Directory]::SetCurrentDirectory((Get-Location).Path)
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

New-Item -ItemType Directory -Force -Path "src/app/actions" | Out-Null
$content = @'
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

'@
[System.IO.File]::WriteAllText("src/app/actions/jobs.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/admin/students/[id]" | Out-Null
$content = @'
import { notFound } from "next/navigation";
import { getStudentById, getUserById, listNotesForStudent, listStaff, listJobApplicationsForStudent } from "@/lib/repo";
import { APPLICATION_STATUSES, CURRENT_EDUCATION_LEVELS } from "@/types";
import type { DocumentItem } from "@/types";
import { PhotoLightbox } from "@/components/photo-lightbox";
import { MessageThread } from "@/components/message-thread";
import { EmailStudentForm } from "./email-student-form";
import { DeleteButton } from "@/components/delete-button";
import { deleteUserAction } from "@/app/actions/admin";
import { CheckIcon } from "@/components/check-icon";
import { ApplicationsReview } from "@/components/applications-review";

export const dynamic = "force-dynamic";

export default async function AdminStudentDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const student = getStudentById(id);
  if (!student) notFound();

  const user = getUserById(student.userId);
  const staff = listStaff();
  const assignedStaff = staff.find((s) => s.id === student.assignedStaffId);
  const notes = listNotesForStudent(student.id);
  const documents = JSON.parse(student.documents) as DocumentItem[];
  const targetCountries = JSON.parse(student.targetCountries) as string[];
  const jobApplications = student.applicationTrack === "work_visa" ? listJobApplicationsForStudent(student.id) : [];
  const statusLabel = APPLICATION_STATUSES.find((s) => s.value === student.status)?.label ?? student.status;
  const eduLabel =
    student.currentEducationLevel === "shs_current"
      ? "Currently in Senior High School"
      : CURRENT_EDUCATION_LEVELS.find((l) => l.value === student.currentEducationLevel)?.label ||
        student.currentEducationLevel;

  return (
    <div className="max-w-3xl">
      <div className="flex items-start gap-5 mb-8">
        <div className="w-20 h-20 rounded-full bg-paper-dim border border-line overflow-hidden shrink-0">
          {student.photoUrl ? (
            <PhotoLightbox src={student.photoUrl} alt={user?.name || "Student"} className="w-full h-full object-cover" />
          ) : (
            <div className="w-full h-full grid place-items-center text-xl text-ink/40">
              {user?.name?.charAt(0) ?? "?"}
            </div>
          )}
        </div>
        <div>
          <p className="font-mono text-xs bg-paper-dim border border-line rounded px-2 py-1 inline-block mb-2">
            {student.code}
          </p>
          <h1 className="font-display text-3xl mb-1">{user?.name}</h1>
          <p className="text-ink/60">{user?.email}</p>
        </div>
      </div>

      <div className="grid sm:grid-cols-2 gap-6 mb-10">
        <InfoCard label="Application status" value={statusLabel} />
        <InfoCard
          label="Program"
          value={
            student.applicationTrack === "work_visa"
              ? "Work visa support"
              : student.applicationType === "free_shs"
                ? "Free &middot; SHS partnership"
                : "Standard"
          }
        />
        {student.applicationTrack === "work_visa" ? (
          <>
            <InfoCard label="Profession" value={`${student.profession} - ${targetCountries.join(", ")}`} />
            <InfoCard label="Current occupation" value={student.currentOccupation || "Not specified"} />
            <InfoCard label="Experience" value={student.yearsExperience} />
            <InfoCard label="Job offer" value={student.hasJobOffer ? "Yes" : "Not yet"} />
          </>
        ) : (
          <>
            <InfoCard label="Targeting" value={`${student.targetLevel} - ${targetCountries.join(", ")}`} />
            <InfoCard label="Current education" value={`${eduLabel}${student.schoolName ? ` (${student.schoolName})` : ""}`} />
          </>
        )}
        <InfoCard label="Assigned counselor" value={assignedStaff?.name || "Unassigned"} />
        <InfoCard label="Applied" value={new Date(student.createdAt).toLocaleDateString()} />
      </div>

      <div className="mb-10">
        <h2 className="font-display text-xl mb-4">Document checklist</h2>
        <ul className="space-y-2">
          {documents.map((doc) => (
            <li key={doc.name} className="flex items-center justify-between border border-line rounded-lg px-3 py-2 text-sm">
              <span className="flex items-center gap-3">
                <span
                  className={`w-4 h-4 rounded border grid place-items-center text-[10px] ${
                    doc.done ? "bg-teal border-teal text-white" : "border-line"
                  }`}
                >
                  {doc.done ? <CheckIcon className="w-3 h-3" /> : null}
                </span>
                {doc.name}
              </span>
              {doc.fileUrl && (
                <a href={doc.fileUrl} target="_blank" rel="noopener noreferrer" className="text-teal hover:underline">
                  View file
                </a>
              )}
            </li>
          ))}
        </ul>
      </div>

      {student.applicationTrack === "work_visa" && (
        <div className="mb-10">
          <h2 className="font-display text-xl mb-4">Job Applications</h2>
          <ApplicationsReview applications={jobApplications} />
        </div>
      )}

      <div className="mb-10">
        <h2 className="font-display text-xl mb-4">Message history</h2>
        <div className="border border-line rounded-xl p-5 max-h-80 overflow-y-auto">
          <MessageThread
            messages={notes.map((n) => ({
              id: n.id,
              text: n.text,
              attachmentUrl: n.attachmentUrl,
              authorName: n.authorName,
              authorRole: n.authorRole,
              createdAt: n.createdAt,
            }))}
            viewerRole="admin"
          />
        </div>
        <p className="text-xs text-ink/40 mt-2">
          This is the in-app conversation between the student and their counselor. To reach the student directly,
          use the email form below.
        </p>
      </div>

      <div>
        <h2 className="font-display text-xl mb-4">Email this student</h2>
        {user && <EmailStudentForm studentId={student.id} studentEmail={user.email} />}
      </div>

      {user && (
        <div className="mt-12 pt-8 border-t border-line max-w-lg">
          <h2 className="font-display text-xl mb-2 text-red-700">Danger zone</h2>
          <p className="text-sm text-ink/60 mb-4">
            Deletes {user.name}'s login and their application record, including documents and message
            history. This can't be undone.
          </p>
          <DeleteButton
            id={user.id}
            action={deleteUserAction}
            confirmLabel={`Delete ${user.name}'s account? This removes their login and their entire application record. This can't be undone.`}
          />
        </div>
      )}
    </div>
  );
}

function InfoCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="border border-line rounded-xl p-4">
      <p className="text-xs uppercase tracking-wide text-ink/50 mb-1">{label}</p>
      <p className="text-sm capitalize">{value}</p>
    </div>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/admin/students/[id]/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/staff/students/[id]" | Out-Null
$content = @'
import { notFound } from "next/navigation";
import { getSession } from "@/lib/auth";
import { getStaffByUserId, getStudentById, getUserById, listNotesForStudent, listJobApplicationsForStudent } from "@/lib/repo";
import { StatusSelect } from "./status-select";
import { DocumentChecklist } from "./document-checklist";
import { MessageThread } from "@/components/message-thread";
import { MessageForm } from "@/components/message-form";
import { PhotoLightbox } from "@/components/photo-lightbox";
import { ApplicationsReview } from "@/components/applications-review";
import { staffAddNoteAction } from "@/app/actions/staff";
import type { DocumentItem } from "@/types";

export const dynamic = "force-dynamic";

export default async function StaffStudentPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const session = await getSession();
  const staff = session ? getStaffByUserId(session.userId) : undefined;
  const student = getStudentById(id);

  if (!student || !staff || student.assignedStaffId !== staff.id) notFound();

  const user = getUserById(student.userId);
  const notes = listNotesForStudent(student.id);
  const documents = JSON.parse(student.documents) as DocumentItem[];
  const targetCountries = JSON.parse(student.targetCountries) as string[];
  const jobApplications = student.applicationTrack === "work_visa" ? listJobApplicationsForStudent(student.id) : [];
  const addNote = staffAddNoteAction.bind(null, student.id);

  return (
    <div className="max-w-3xl">
      <div className="flex items-start gap-5 mb-8">
        <div className="w-20 h-20 rounded-full bg-paper-dim border border-line overflow-hidden shrink-0">
          {student.photoUrl ? (
            <PhotoLightbox src={student.photoUrl} alt={user?.name || "Student"} className="w-full h-full object-cover" />
          ) : (
            <div className="w-full h-full grid place-items-center text-xl text-ink/40">
              {user?.name?.charAt(0) ?? "?"}
            </div>
          )}
        </div>
        <div>
          <p className="font-mono text-xs bg-paper-dim border border-line rounded px-2 py-1 inline-block mb-2">
            {student.code}
          </p>
          <h1 className="font-display text-3xl mb-1">{user?.name}</h1>
          <p className="text-ink/60">{user?.email}</p>
        </div>
      </div>

      <div className="grid sm:grid-cols-2 gap-8 mb-10">
        <div>
          <h2 className="text-sm font-medium mb-2">Application status</h2>
          <StatusSelect studentId={student.id} status={student.status} />
        </div>
        <div>
          {student.applicationTrack === "work_visa" ? (
            <>
              <h2 className="text-sm font-medium mb-2">Profession</h2>
              <p className="text-sm text-ink/70">{student.profession}</p>
              <p className="text-sm text-ink/70">{targetCountries.join(", ")}</p>
              <p className="text-sm text-ink/70 mt-2">
                {student.yearsExperience} experience &middot; {student.hasJobOffer ? "Has a job offer" : "No job offer yet"}
              </p>
            </>
          ) : (
            <>
              <h2 className="text-sm font-medium mb-2">Targeting</h2>
              <p className="text-sm text-ink/70 capitalize">{student.targetLevel}</p>
              <p className="text-sm text-ink/70">{targetCountries.join(", ")}</p>
            </>
          )}
        </div>
      </div>

      <div className="mb-10">
        <h2 className="font-display text-xl mb-4">Document checklist</h2>
        <DocumentChecklist studentId={student.id} documents={documents} />
      </div>

      {student.applicationTrack === "work_visa" && (
        <div className="mb-10">
          <h2 className="font-display text-xl mb-4">Job Applications</h2>
          <ApplicationsReview applications={jobApplications} />
        </div>
      )}

      <div>
        <h2 className="font-display text-xl mb-4">Messages</h2>
        <div className="border border-line rounded-xl p-5 mb-4 max-h-96 overflow-y-auto">
          <MessageThread
            messages={notes.map((n) => ({
              id: n.id,
              text: n.text,
              attachmentUrl: n.attachmentUrl,
              authorName: n.authorName,
              authorRole: n.authorRole,
              createdAt: n.createdAt,
            }))}
            viewerRole="staff"
          />
        </div>
        <MessageForm action={addNote} placeholder="Send a message to this student..." />
      </div>
    </div>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/staff/students/[id]/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/student" | Out-Null
$content = @'
import { getSession } from "@/lib/auth";
import { getStudentByUserId, getStaffById, listNotesForStudent, listPublishedJobs, listJobApplicationsForStudent, countJobApplicationsByStatus } from "@/lib/repo";
import { APPLICATION_STATUSES } from "@/types";
import type { DocumentItem } from "@/types";
import { DocumentUploadRow } from "./document-upload-row";
import { MessageThread } from "@/components/message-thread";
import { MessageForm } from "@/components/message-form";
import { studentAddNoteAction } from "@/app/actions/student";
import { RequestFormButton } from "./request-form-button";
import { JobBrowseList } from "./job-browse-list";
import { MyApplicationsList } from "./my-applications-list";

export const dynamic = "force-dynamic";

export default async function StudentHomePage() {
  const session = await getSession();
  const student = session ? getStudentByUserId(session.userId) : undefined;

  if (!student) {
    return <p className="text-ink/60">We couldn't find your application record. Please contact WorldPath Group.</p>;
  }

  const staff = student.assignedStaffId ? getStaffById(student.assignedStaffId) : undefined;
  const notes = listNotesForStudent(student.id);
  const documents = JSON.parse(student.documents) as DocumentItem[];
  const targetCountries = JSON.parse(student.targetCountries) as string[];
  const statusLabel = APPLICATION_STATUSES.find((s) => s.value === student.status)?.label ?? student.status;
  const completedDocs = documents.filter((d) => d.done).length;
  const myApplications = student.applicationTrack === "work_visa" ? listJobApplicationsForStudent(student.id) : [];
  const applicationCounts = student.applicationTrack === "work_visa" ? countJobApplicationsByStatus(student.id) : {};
  const savedJobIds = new Set(myApplications.map((a) => a.jobId));
  const availableJobs =
    student.applicationTrack === "work_visa" ? listPublishedJobs().filter((j) => !savedJobIds.has(j.id)) : [];

  return (
    <div>
      <div className="flex items-center gap-4 mb-3">
        <div className="w-14 h-14 rounded-full bg-paper-dim border border-line overflow-hidden shrink-0">
          {student.photoUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={student.photoUrl} alt={session?.name || ""} className="w-full h-full object-cover" />
          ) : (
            <div className="w-full h-full grid place-items-center text-ink/40">{session?.name?.charAt(0) ?? "?"}</div>
          )}
        </div>
        <p className="font-mono text-xs bg-paper-dim border border-line rounded px-2 py-1 inline-block">
          {student.code}
        </p>
      </div>
      <h1 className="font-display text-3xl mb-2">Welcome, {session?.name}</h1>
      <p className="text-ink/60 mb-10">
 {staff ? `Your counselor is ${staff.name}.` : "A counselor hasn't been assigned yet - one will be soon."}
      </p>

      <div className="grid sm:grid-cols-2 gap-6 mb-10">
        <div className="border border-line rounded-xl p-5">
          <p className="text-xs uppercase tracking-wide text-ink/50 mb-1">Application status</p>
          <p className="font-display text-xl text-gold-deep">{statusLabel}</p>
        </div>
        <div className="border border-line rounded-xl p-5">
          {student.applicationTrack === "work_visa" ? (
            <>
              <p className="text-xs uppercase tracking-wide text-ink/50 mb-1">Profession</p>
              <p>{student.profession}</p>
              <p className="text-sm text-ink/70">{targetCountries.join(", ")}</p>
            </>
          ) : (
            <>
              <p className="text-xs uppercase tracking-wide text-ink/50 mb-1">Targeting</p>
              <p className="capitalize">{student.targetLevel}</p>
              <p className="text-sm text-ink/70">{targetCountries.join(", ")}</p>
            </>
          )}
        </div>
      </div>

      {student.applicationTrack === "work_visa" && (
        <div className="grid sm:grid-cols-3 gap-6 mb-10">
          <div className="border border-line rounded-xl p-5">
            <p className="text-xs uppercase tracking-wide text-ink/50 mb-1">Current occupation</p>
            <p className="text-sm">{student.currentOccupation || "Not specified"}</p>
          </div>
          <div className="border border-line rounded-xl p-5">
            <p className="text-xs uppercase tracking-wide text-ink/50 mb-1">Experience</p>
            <p className="text-sm">{student.yearsExperience}</p>
          </div>
          <div className="border border-line rounded-xl p-5">
            <p className="text-xs uppercase tracking-wide text-ink/50 mb-1">Job offer</p>
            <p className="text-sm">{student.hasJobOffer ? "Yes" : "Not yet"}</p>
          </div>
        </div>
      )}

      {student.applicationTrack === "work_visa" && (
        <>
          <div className="mb-10">
            <div className="flex items-center justify-between mb-4">
              <h2 className="font-display text-xl">My Applications</h2>
              <span className="text-sm text-ink/50">
                {Object.entries(applicationCounts)
                  .filter(([status]) => status !== "withdrawn")
                  .map(([status, count]) => `${status.replace(/_/g, " ")}: ${count}`)
                  .join(" · ") || "None yet"}
              </span>
            </div>
            <MyApplicationsList applications={myApplications} />
          </div>

          <div className="mb-10">
            <h2 className="font-display text-xl mb-4">Browse Opportunities</h2>
            <JobBrowseList jobs={availableJobs} savedJobIds={myApplications.map((a) => a.jobId)} />
          </div>
        </>
      )}

      {student.applicationTrack === "university" && student.applicationType === "standard" && student.assignedStaffId && (
        <div className="border border-gold-deep/30 bg-gold/5 rounded-xl p-5 mb-10 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <p className="font-medium mb-1">Need your application form?</p>
            <p className="text-sm text-ink/60">
              Standard applications start with a request to your counselor rather than a default
              checklist. They'll reply in your message thread with the form attached.
            </p>
          </div>
          <RequestFormButton />
        </div>
      )}

      <div className="mb-10">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-display text-xl">Document checklist</h2>
          <span className="text-sm text-ink/50">
            {completedDocs}/{documents.length} complete
          </span>
        </div>
        <p className="text-xs text-ink/50 mb-3">
          Upload a photo or PDF of each document. Uploading automatically marks it complete.
        </p>
        <ul className="space-y-2">
          {documents.map((doc, index) => (
            <DocumentUploadRow key={doc.name} doc={doc} index={index} />
          ))}
        </ul>
      </div>

      <div>
        <h2 className="font-display text-xl mb-4">Messages with your counselor</h2>
        <div className="border border-line rounded-xl p-5 mb-4 max-h-96 overflow-y-auto">
          <MessageThread
            messages={notes.map((n) => ({
              id: n.id,
              text: n.text,
              attachmentUrl: n.attachmentUrl,
              authorName: n.authorName,
              authorRole: n.authorRole,
              createdAt: n.createdAt,
            }))}
            viewerRole="student"
          />
        </div>
        <MessageForm action={studentAddNoteAction} placeholder="Send a message to your counselor..." />
      </div>
    </div>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/student/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/lib" | Out-Null
$content = @'
import { DatabaseSync } from "node:sqlite";
import path from "node:path";
import fs from "node:fs";
import bcrypt from "bcryptjs";
import { randomUUID } from "node:crypto";

// This project uses Node's built-in `node:sqlite` module as its database
// driver so the app runs with zero native-binary installs. The data model
// mirrors docs/schema.prisma.reference exactly, so migrating to Prisma +
// Postgres later is a mechanical port, not a redesign. See README.md.

const DB_PATH = process.env.DATABASE_FILE || path.join(process.cwd(), "data", "worldpath.db");

function getDb(): DatabaseSync {
  const g = globalThis as unknown as { __worldpathDb?: DatabaseSync };
  if (g.__worldpathDb) return g.__worldpathDb;

  fs.mkdirSync(path.dirname(DB_PATH), { recursive: true });
  const db = new DatabaseSync(DB_PATH);
  db.exec("PRAGMA journal_mode = WAL;");
  db.exec("PRAGMA foreign_keys = ON;");
  migrate(db);
  seed(db);
  g.__worldpathDb = db;
  return db;
}

function migrate(db: DatabaseSync) {
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      username TEXT UNIQUE NOT NULL,
      email TEXT UNIQUE NOT NULL,
      passwordHash TEXT,
      role TEXT NOT NULL DEFAULT 'student',
      name TEXT NOT NULL,
      emailVerified INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS staff_profiles (
      id TEXT PRIMARY KEY,
      userId TEXT UNIQUE REFERENCES users(id),
      name TEXT NOT NULL,
      title TEXT NOT NULL,
      bio TEXT NOT NULL DEFAULT '',
      photoUrl TEXT,
      sortOrder INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS board_members (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      title TEXT NOT NULL,
      bio TEXT NOT NULL DEFAULT '',
      photoUrl TEXT,
      sortOrder INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS students (
      id TEXT PRIMARY KEY,
      code TEXT UNIQUE NOT NULL,
      userId TEXT UNIQUE NOT NULL REFERENCES users(id),
      targetLevel TEXT NOT NULL DEFAULT 'undergrad',
      targetCountries TEXT NOT NULL DEFAULT '[]',
      status TEXT NOT NULL DEFAULT 'new',
      assignedStaffId TEXT REFERENCES staff_profiles(id),
      documents TEXT NOT NULL DEFAULT '[]',
      scholarshipInterest INTEGER NOT NULL DEFAULT 1,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS student_notes (
      id TEXT PRIMARY KEY,
      studentId TEXT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
      authorId TEXT NOT NULL REFERENCES users(id),
      text TEXT NOT NULL,
      createdAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS site_content (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      orgName TEXT NOT NULL DEFAULT 'WorldPath Group',
      tagline TEXT NOT NULL DEFAULT '',
      mission TEXT NOT NULL DEFAULT '',
      vision TEXT NOT NULL DEFAULT '',
      contactEmail TEXT NOT NULL DEFAULT '',
      contactPhone TEXT NOT NULL DEFAULT '',
      address TEXT NOT NULL DEFAULT ''
    );

    CREATE TABLE IF NOT EXISTS email_verifications (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      token TEXT UNIQUE NOT NULL,
      expiresAt TEXT NOT NULL,
      used INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS counters (
      id TEXT PRIMARY KEY,
      value INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS notifications (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      type TEXT NOT NULL,
      title TEXT NOT NULL,
      body TEXT NOT NULL DEFAULT '',
      link TEXT,
      read INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS jobs (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      employer TEXT NOT NULL,
      country TEXT NOT NULL,
      city TEXT NOT NULL DEFAULT '',
      industry TEXT NOT NULL DEFAULT '',
      employmentType TEXT NOT NULL DEFAULT '',
      experienceRequired TEXT NOT NULL DEFAULT '',
      educationRequirement TEXT NOT NULL DEFAULT '',
      languageRequirement TEXT NOT NULL DEFAULT '',
      salary TEXT NOT NULL DEFAULT '',
      sponsorshipInfo TEXT NOT NULL DEFAULT '',
      applicationDeadline TEXT,
      lastVerifiedDate TEXT,
      source TEXT NOT NULL DEFAULT '',
      verificationStatus TEXT NOT NULL DEFAULT 'pending_verification',
      applicationUrl TEXT NOT NULL DEFAULT '',
      description TEXT NOT NULL DEFAULT '',
      published INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS job_applications (
      id TEXT PRIMARY KEY,
      studentId TEXT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
      jobId TEXT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
      status TEXT NOT NULL DEFAULT 'saved',
      notes TEXT NOT NULL DEFAULT '',
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      UNIQUE(studentId, jobId)
    );

    CREATE TABLE IF NOT EXISTS blog_posts (
      id TEXT PRIMARY KEY,
      slug TEXT UNIQUE NOT NULL,
      title TEXT NOT NULL,
      excerpt TEXT NOT NULL DEFAULT '',
      body TEXT NOT NULL DEFAULT '',
      coverImageUrl TEXT,
      tags TEXT NOT NULL DEFAULT '[]',
      authorName TEXT NOT NULL DEFAULT '',
      published INTEGER NOT NULL DEFAULT 0,
      publishedAt TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS impact_stories (
      id TEXT PRIMARY KEY,
      studentName TEXT NOT NULL,
      headline TEXT NOT NULL,
      story TEXT NOT NULL DEFAULT '',
      photoUrl TEXT,
      destinationCountry TEXT NOT NULL DEFAULT '',
      targetLevel TEXT NOT NULL DEFAULT 'undergrad',
      featured INTEGER NOT NULL DEFAULT 0,
      sortOrder INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS volunteer_leads (
      id TEXT PRIMARY KEY,
      type TEXT NOT NULL DEFAULT 'volunteer',
      name TEXT NOT NULL,
      email TEXT NOT NULL,
      phone TEXT,
      message TEXT NOT NULL DEFAULT '',
      handled INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    );
  `);

  // Columns added after the initial release go here as best-effort ALTERs
  // (existing databases won't have them; CREATE TABLE IF NOT EXISTS above
  // only helps brand-new installs). Safe to ignore "duplicate column".
  const alters = [
    "ALTER TABLE site_content ADD COLUMN donateInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN logoUrl TEXT",
    "ALTER TABLE site_content ADD COLUMN caretakingInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE student_notes ADD COLUMN attachmentUrl TEXT",
    "ALTER TABLE students ADD COLUMN currentEducationLevel TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE students ADD COLUMN schoolName TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE students ADD COLUMN applicationType TEXT NOT NULL DEFAULT 'standard'",
    "ALTER TABLE students ADD COLUMN photoUrl TEXT",
    "ALTER TABLE volunteer_leads ADD COLUMN areasOfInterest TEXT NOT NULL DEFAULT '[]'",
    "ALTER TABLE volunteer_leads ADD COLUMN availability TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN heroImageUrl TEXT",
    "ALTER TABLE site_content ADD COLUMN founderName TEXT NOT NULL DEFAULT 'Cyril Asirifi Kwame'",
    "ALTER TABLE site_content ADD COLUMN founderTitle TEXT NOT NULL DEFAULT 'Founder & Executive Director'",
    "ALTER TABLE site_content ADD COLUMN founderBio TEXT NOT NULL DEFAULT 'Passionate about expanding access to international education and scholarship opportunities for students across Ghana.'",
    "ALTER TABLE site_content ADD COLUMN founderPhotoUrl TEXT",
    "ALTER TABLE site_content ADD COLUMN undergradInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN mastersInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN phdInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN scholarshipsInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN workVisaInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE students ADD COLUMN applicationTrack TEXT NOT NULL DEFAULT 'university'",
    "ALTER TABLE students ADD COLUMN profession TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE students ADD COLUMN currentOccupation TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE students ADD COLUMN yearsExperience TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE students ADD COLUMN hasJobOffer INTEGER NOT NULL DEFAULT 0",
  ];
  for (const sql of alters) {
    try {
      db.exec(sql);
    } catch {
      // Column already exists ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â fine.
    }
  }
}

function seed(db: DatabaseSync) {
  const now = new Date().toISOString();

  const contentRow = db.prepare("SELECT id FROM site_content WHERE id = 1").get();
  if (!contentRow) {
    db.prepare(
      `INSERT INTO site_content (id, orgName, tagline, mission, vision, contactEmail, contactPhone, address, donateInfo, caretakingInfo)
       VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    ).run(
      "WorldPath Group",
      "Opening the world's classrooms to Ghana's brightest students.",
      "WorldPath Group helps talented undergraduate, master's, and PhD students across Ghana apply to universities abroad and secure the scholarships that make it possible \u2014 with priority access for students whose families cannot otherwise afford it, including orphans.",
      "A future where a student's potential, not their family's income, determines which universities are open to them.",
      "hello@worldpathgroup.org",
      "",
      "Accra, Ghana",
      "Update this from Admin \u2192 Site content with your bank account or mobile money details.",
      "Beyond university placement, our parent foundation supports caretaking homes with food and daily necessities \u2014 because a student's wellbeing at home is part of their path to university too."
    );
  }

  const adminRow = db.prepare("SELECT id FROM users WHERE role = 'admin' LIMIT 1").get();
  if (!adminRow) {
    const id = randomUUID();
    const passwordHash = bcrypt.hashSync("ChangeMe123!", 10);
    db.prepare(
      `INSERT INTO users (id, username, email, passwordHash, role, name, emailVerified, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, 'admin', ?, 1, ?, ?)`
    ).run(id, "admin", "admin@worldpathgroup.org", passwordHash, "WorldPath Admin", now, now);
  }
}

// node:sqlite returns row objects with a null prototype. That's invisible
// almost everywhere, but React Server Components refuse to serialize
// null-prototype objects when passing data to Client Components ("Only
// plain objects... can be passed"). This thin wrapper spreads every row
// into a genuine plain object so callers never have to think about it.
type SQLInputValue = null | number | bigint | string | NodeJS.ArrayBufferView;

interface PlainStatement {
  get(...params: SQLInputValue[]): Record<string, unknown> | undefined;
  all(...params: SQLInputValue[]): Record<string, unknown>[];
  run(...params: SQLInputValue[]): unknown;
}

interface PlainDb {
  prepare(sql: string): PlainStatement;
}

function wrapDb(raw: DatabaseSync): PlainDb {
  return {
    prepare(sql: string) {
      const stmt = raw.prepare(sql);
      return {
        get: (...params: SQLInputValue[]) => {
          const row = stmt.get(...params);
          return row ? { ...(row as object) } : undefined;
        },
        all: (...params: SQLInputValue[]) => {
          return stmt.all(...params).map((row) => ({ ...(row as object) }));
        },
        run: (...params: SQLInputValue[]) => stmt.run(...params),
      };
    },
  };
}

export function db(): PlainDb {
  return wrapDb(getDb());
}

/**
 * Temporarily disables foreign key enforcement, runs fn, then re-enables it.
 * Used only for account deletion: a deleted staff/admin's authored messages
 * are kept (for the student's record) rather than deleted, which would
 * otherwise violate the foreign key on student_notes.authorId.
 */
export function withForeignKeysOff<T>(fn: () => T): T {
  const raw = getDb();
  raw.exec("PRAGMA foreign_keys = OFF;");
  try {
    return fn();
  } finally {
    raw.exec("PRAGMA foreign_keys = ON;");
  }
}

export function nowIso(): string {
  return new Date().toISOString();
}

export function newId(): string {
  return randomUUID();
}

/** Generates the next sequential student code for the current year, e.g. WPG-2026-0001 */
export function nextStudentCode(): string {
  const year = new Date().getFullYear();
  const counterId = `student-${year}`;
  const database = getDb();
  const existing = database.prepare("SELECT value FROM counters WHERE id = ?").get(counterId) as
    | { value: number }
    | undefined;
  const next = (existing?.value ?? 0) + 1;
  if (existing) {
    database.prepare("UPDATE counters SET value = ? WHERE id = ?").run(next, counterId);
  } else {
    database.prepare("INSERT INTO counters (id, value) VALUES (?, ?)").run(counterId, next);
  }
  return `WPG-${year}-${String(next).padStart(4, "0")}`;
}


'@
[System.IO.File]::WriteAllText("src/lib/db.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/lib" | Out-Null
$content = @'
import { db, newId, nowIso, nextStudentCode, withForeignKeysOff } from "@/lib/db";
import type {
  UserRecord,
  StaffProfileRecord,
  BoardMemberRecord,
  StudentRecord,
  StudentNoteRecord,
  SiteContentRecord,
  BlogPostRecord,
  ImpactStoryRecord,
  VolunteerLeadRecord,
  LeadType,
  Role,
  TargetLevel,
  DocumentItem,
  NotificationRecord,
  NotificationType,
  JobRecord,
  JobVerificationStatus,
  JobApplicationRecord,
  JobApplicationStatus,
} from "@/types";

const DEFAULT_CHECKLIST: DocumentItem[] = [
  { name: "Passport / national ID", done: false },
  { name: "Academic transcripts", done: false },
  { name: "Personal statement / essay", done: false },
  { name: "Recommendation letters", done: false },
  { name: "English proficiency test (if required)", done: false },
  { name: "Financial / sponsorship documents", done: false },
];

const WORK_VISA_CHECKLIST: DocumentItem[] = [
  { name: "Passport", done: false },
  { name: "CV / resume", done: false },
  { name: "Professional qualification / certification", done: false },
  { name: "Reference letters from past employers", done: false },
  { name: "Language proficiency test (if required)", done: false },
  { name: "Job offer letter (if you have one)", done: false },
  { name: "Police clearance certificate", done: false },
  { name: "Medical certificate", done: false },
];

// ---------- Users ----------

export function getUserByEmail(email: string): UserRecord | undefined {
  return db().prepare("SELECT * FROM users WHERE email = ?").get(email) as UserRecord | undefined;
}

export function getUserByUsername(username: string): UserRecord | undefined {
  return db().prepare("SELECT * FROM users WHERE username = ?").get(username) as UserRecord | undefined;
}

export function getUserById(id: string): UserRecord | undefined {
  return db().prepare("SELECT * FROM users WHERE id = ?").get(id) as UserRecord | undefined;
}

export function listUsers(): UserRecord[] {
  return db().prepare("SELECT * FROM users ORDER BY createdAt DESC").all() as unknown as UserRecord[];
}

export function countAdmins(): number {
  const row = db().prepare("SELECT COUNT(*) as count FROM users WHERE role = 'admin'").get() as
    | { count: number }
    | undefined;
  return row?.count ?? 0;
}

/**
 * Deletes a user account and whatever it owns: for staff, their public
 * profile (and unassigns any students); for students, their application
 * record. Messages the account authored are kept for the record ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â see
 * listNotesForStudent ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â rather than deleted.
 */
export function deleteUserAccount(userId: string): { staffPhotoUrl: string | null; studentPhotoUrl: string | null; documentUrls: string[] } {
  const database = db();
  let staffPhotoUrl: string | null = null;
  let studentPhotoUrl: string | null = null;
  let documentUrls: string[] = [];

  withForeignKeysOff(() => {
    const staff = database.prepare("SELECT * FROM staff_profiles WHERE userId = ?").get(userId) as
      | StaffProfileRecord
      | undefined;
    if (staff) {
      staffPhotoUrl = staff.photoUrl;
      database.prepare("UPDATE students SET assignedStaffId = NULL WHERE assignedStaffId = ?").run(staff.id);
      database.prepare("DELETE FROM staff_profiles WHERE id = ?").run(staff.id);
    }

    const student = database.prepare("SELECT * FROM students WHERE userId = ?").get(userId) as
      | StudentRecord
      | undefined;
    if (student) {
      studentPhotoUrl = student.photoUrl;
      documentUrls = (JSON.parse(student.documents) as { fileUrl?: string | null }[])
        .map((d) => d.fileUrl)
        .filter((u): u is string => Boolean(u));
      database.prepare("DELETE FROM students WHERE id = ?").run(student.id);
    }

    database.prepare("DELETE FROM email_verifications WHERE userId = ?").run(userId);
    database.prepare("DELETE FROM users WHERE id = ?").run(userId);
  });

  return { staffPhotoUrl, studentPhotoUrl, documentUrls };
}

export function createUser(input: {
  username: string;
  email: string;
  name: string;
  role: Role;
  passwordHash?: string | null;
  emailVerified?: boolean;
}): UserRecord {
  const id = newId();
  const now = nowIso();
  db()
    .prepare(
      `INSERT INTO users (id, username, email, passwordHash, role, name, emailVerified, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      id,
      input.username,
      input.email,
      input.passwordHash ?? null,
      input.role,
      input.name,
      input.emailVerified ? 1 : 0,
      now,
      now
    );
  return getUserById(id)!;
}

export function setUserPassword(userId: string, passwordHash: string) {
  db()
    .prepare("UPDATE users SET passwordHash = ?, updatedAt = ? WHERE id = ?")
    .run(passwordHash, nowIso(), userId);
}

export function markEmailVerified(userId: string) {
  db().prepare("UPDATE users SET emailVerified = 1, updatedAt = ? WHERE id = ?").run(nowIso(), userId);
}

// ---------- Email verification tokens ----------

export function createVerificationToken(userId: string, token: string, ttlHours = 48) {
  const expiresAt = new Date(Date.now() + ttlHours * 3600 * 1000).toISOString();
  db()
    .prepare(
      `INSERT INTO email_verifications (id, userId, token, expiresAt, used, createdAt)
       VALUES (?, ?, ?, ?, 0, ?)`
    )
    .run(newId(), userId, token, expiresAt, nowIso());
}

export function getVerificationToken(token: string) {
  return db().prepare("SELECT * FROM email_verifications WHERE token = ?").get(token) as
    | { id: string; userId: string; token: string; expiresAt: string; used: number }
    | undefined;
}

export function consumeVerificationToken(token: string) {
  db().prepare("UPDATE email_verifications SET used = 1 WHERE token = ?").run(token);
}

// ---------- Staff profiles ----------

export function listStaff(): StaffProfileRecord[] {
  return db().prepare("SELECT * FROM staff_profiles ORDER BY sortOrder ASC, name ASC").all() as unknown as StaffProfileRecord[];
}

export function getStaffById(id: string): StaffProfileRecord | undefined {
  return db().prepare("SELECT * FROM staff_profiles WHERE id = ?").get(id) as StaffProfileRecord | undefined;
}

export function getStaffByUserId(userId: string): StaffProfileRecord | undefined {
  return db().prepare("SELECT * FROM staff_profiles WHERE userId = ?").get(userId) as
    | StaffProfileRecord
    | undefined;
}

export function createStaff(input: {
  name: string;
  title: string;
  bio: string;
  photoUrl?: string;
  userId?: string | null;
  sortOrder?: number;
}): StaffProfileRecord {
  const id = newId();
  db()
    .prepare(
      `INSERT INTO staff_profiles (id, userId, name, title, bio, photoUrl, sortOrder)
       VALUES (?, ?, ?, ?, ?, ?, ?)`
    )
    .run(id, input.userId ?? null, input.name, input.title, input.bio, input.photoUrl ?? null, input.sortOrder ?? 0);
  return getStaffById(id)!;
}

export function updateStaff(
  id: string,
  input: { name: string; title: string; bio: string; photoUrl?: string; sortOrder?: number }
) {
  db()
    .prepare(
      `UPDATE staff_profiles SET name = ?, title = ?, bio = ?, photoUrl = ?, sortOrder = ? WHERE id = ?`
    )
    .run(input.name, input.title, input.bio, input.photoUrl ?? null, input.sortOrder ?? 0, id);
}

export function deleteStaff(id: string) {
  db().prepare("UPDATE students SET assignedStaffId = NULL WHERE assignedStaffId = ?").run(id);
  db().prepare("DELETE FROM staff_profiles WHERE id = ?").run(id);
}

// ---------- Board members ----------

export function listBoardMembers(): BoardMemberRecord[] {
  return db().prepare("SELECT * FROM board_members ORDER BY sortOrder ASC, name ASC").all() as unknown as BoardMemberRecord[];
}

export function getBoardMemberById(id: string): BoardMemberRecord | undefined {
  return db().prepare("SELECT * FROM board_members WHERE id = ?").get(id) as BoardMemberRecord | undefined;
}

export function createBoardMember(input: {
  name: string;
  title: string;
  bio: string;
  photoUrl?: string;
  sortOrder?: number;
}): BoardMemberRecord {
  const id = newId();
  db()
    .prepare(`INSERT INTO board_members (id, name, title, bio, photoUrl, sortOrder) VALUES (?, ?, ?, ?, ?, ?)`)
    .run(id, input.name, input.title, input.bio, input.photoUrl ?? null, input.sortOrder ?? 0);
  return getBoardMemberById(id)!;
}

export function updateBoardMember(
  id: string,
  input: { name: string; title: string; bio: string; photoUrl?: string; sortOrder?: number }
) {
  db()
    .prepare(`UPDATE board_members SET name = ?, title = ?, bio = ?, photoUrl = ?, sortOrder = ? WHERE id = ?`)
    .run(input.name, input.title, input.bio, input.photoUrl ?? null, input.sortOrder ?? 0, id);
}

export function deleteBoardMember(id: string) {
  db().prepare("DELETE FROM board_members WHERE id = ?").run(id);
}

// ---------- Students ----------

export function listStudents(): StudentRecord[] {
  return db().prepare("SELECT * FROM students ORDER BY createdAt DESC").all() as unknown as StudentRecord[];
}

export function listStudentsByStaff(staffId: string): StudentRecord[] {
  return db()
    .prepare("SELECT * FROM students WHERE assignedStaffId = ? ORDER BY createdAt DESC")
    .all(staffId) as unknown as StudentRecord[];
}

export function getStudentById(id: string): StudentRecord | undefined {
  return db().prepare("SELECT * FROM students WHERE id = ?").get(id) as StudentRecord | undefined;
}

export function getStudentByUserId(userId: string): StudentRecord | undefined {
  return db().prepare("SELECT * FROM students WHERE userId = ?").get(userId) as StudentRecord | undefined;
}

export function createStudentForUser(input: {
  userId: string;
  targetLevel: TargetLevel;
  targetCountries: string[];
  scholarshipInterest: boolean;
  currentEducationLevel?: string;
  schoolName?: string;
  applicationType?: "standard" | "free_shs";
  photoUrl?: string | null;
  applicationTrack?: "university" | "work_visa";
  profession?: string;
  currentOccupation?: string;
  yearsExperience?: string;
  hasJobOffer?: boolean;
}): StudentRecord {
  const id = newId();
  const now = nowIso();
  const code = nextStudentCode();
  const track = input.applicationTrack ?? "university";
  const checklist = track === "work_visa" ? WORK_VISA_CHECKLIST : DEFAULT_CHECKLIST;
  db()
    .prepare(
      `INSERT INTO students
        (id, code, userId, targetLevel, targetCountries, status, assignedStaffId, documents, scholarshipInterest, currentEducationLevel, schoolName, applicationType, photoUrl, applicationTrack, profession, currentOccupation, yearsExperience, hasJobOffer, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?, 'new', NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      id,
      code,
      input.userId,
      input.targetLevel,
      JSON.stringify(input.targetCountries),
      JSON.stringify(checklist),
      input.scholarshipInterest ? 1 : 0,
      input.currentEducationLevel ?? "",
      input.schoolName ?? "",
      input.applicationType ?? "standard",
      input.photoUrl ?? null,
      track,
      input.profession ?? "",
      input.currentOccupation ?? "",
      input.yearsExperience ?? "",
      input.hasJobOffer ? 1 : 0,
      now,
      now
    );
  return getStudentById(id)!;
}

export function updateStudentStatus(id: string, status: string) {
  db().prepare("UPDATE students SET status = ?, updatedAt = ? WHERE id = ?").run(status, nowIso(), id);
}

export function assignStudentStaff(id: string, staffId: string | null) {
  db().prepare("UPDATE students SET assignedStaffId = ?, updatedAt = ? WHERE id = ?").run(staffId, nowIso(), id);
}

export function updateStudentDocuments(id: string, documents: DocumentItem[]) {
  db()
    .prepare("UPDATE students SET documents = ?, updatedAt = ? WHERE id = ?")
    .run(JSON.stringify(documents), nowIso(), id);
}

export function updateStudentTargets(
  id: string,
  input: { targetLevel: TargetLevel; targetCountries: string[]; scholarshipInterest: boolean }
) {
  db()
    .prepare(
      "UPDATE students SET targetLevel = ?, targetCountries = ?, scholarshipInterest = ?, updatedAt = ? WHERE id = ?"
    )
    .run(input.targetLevel, JSON.stringify(input.targetCountries), input.scholarshipInterest ? 1 : 0, nowIso(), id);
}

// ---------- Student notes ----------

export function listNotesForStudent(
  studentId: string
): (StudentNoteRecord & { authorName: string; authorRole: Role })[] {
  return db()
    .prepare(
      `SELECT n.*, COALESCE(u.name, 'Former team member') as authorName, COALESCE(u.role, 'staff') as authorRole
       FROM student_notes n
       LEFT JOIN users u ON u.id = n.authorId
       WHERE n.studentId = ? ORDER BY n.createdAt ASC`
    )
    .all(studentId) as unknown as (StudentNoteRecord & { authorName: string; authorRole: Role })[];
}

export function addNote(studentId: string, authorId: string, text: string, attachmentUrl?: string | null) {
  db()
    .prepare(
      `INSERT INTO student_notes (id, studentId, authorId, text, attachmentUrl, createdAt) VALUES (?, ?, ?, ?, ?, ?)`
    )
    .run(newId(), studentId, authorId, text, attachmentUrl ?? null, nowIso());
}

// ---------- Site content ----------

export function getSiteContent(): SiteContentRecord {
  return db().prepare("SELECT * FROM site_content WHERE id = 1").get() as unknown as SiteContentRecord;
}

export function updateSiteContent(input: Omit<SiteContentRecord, "id">) {
  db()
    .prepare(
      `UPDATE site_content SET orgName = ?, tagline = ?, mission = ?, vision = ?, contactEmail = ?, contactPhone = ?, address = ?, donateInfo = ?, logoUrl = ?, heroImageUrl = ?, founderName = ?, founderTitle = ?, founderBio = ?, founderPhotoUrl = ?, undergradInfo = ?, mastersInfo = ?, phdInfo = ?, scholarshipsInfo = ?, workVisaInfo = ?, caretakingInfo = ?
       WHERE id = 1`
    )
    .run(
      input.orgName,
      input.tagline,
      input.mission,
      input.vision,
      input.contactEmail,
      input.contactPhone,
      input.address,
      input.donateInfo,
      input.logoUrl,
      input.heroImageUrl,
      input.founderName,
      input.founderTitle,
      input.founderBio,
      input.founderPhotoUrl,
      input.undergradInfo,
      input.mastersInfo,
      input.phdInfo,
      input.scholarshipsInfo,
      input.workVisaInfo,
      input.caretakingInfo
    );
}

// ---------- Blog posts ----------

function slugify(title: string): string {
  return title
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "")
    .slice(0, 80);
}

export function uniqueSlug(title: string, excludeId?: string): string {
  const base = slugify(title) || "post";
  let slug = base;
  let n = 1;
  while (true) {
    const existing = db().prepare("SELECT id FROM blog_posts WHERE slug = ?").get(slug) as
      | { id: string }
      | undefined;
    if (!existing || existing.id === excludeId) return slug;
    n += 1;
    slug = `${base}-${n}`;
  }
}

export function listPublishedPosts(): BlogPostRecord[] {
  return db()
    .prepare("SELECT * FROM blog_posts WHERE published = 1 ORDER BY publishedAt DESC")
    .all() as unknown as BlogPostRecord[];
}

export function listAllPosts(): BlogPostRecord[] {
  return db().prepare("SELECT * FROM blog_posts ORDER BY createdAt DESC").all() as unknown as BlogPostRecord[];
}

export function getPostBySlug(slug: string): BlogPostRecord | undefined {
  return db().prepare("SELECT * FROM blog_posts WHERE slug = ?").get(slug) as unknown as
    | BlogPostRecord
    | undefined;
}

export function getPostById(id: string): BlogPostRecord | undefined {
  return db().prepare("SELECT * FROM blog_posts WHERE id = ?").get(id) as unknown as BlogPostRecord | undefined;
}

export function createPost(input: {
  title: string;
  excerpt: string;
  body: string;
  coverImageUrl?: string;
  tags: string[];
  authorName: string;
  published: boolean;
}): BlogPostRecord {
  const id = newId();
  const now = nowIso();
  const slug = uniqueSlug(input.title);
  db()
    .prepare(
      `INSERT INTO blog_posts
        (id, slug, title, excerpt, body, coverImageUrl, tags, authorName, published, publishedAt, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      id,
      slug,
      input.title,
      input.excerpt,
      input.body,
      input.coverImageUrl ?? null,
      JSON.stringify(input.tags),
      input.authorName,
      input.published ? 1 : 0,
      input.published ? now : null,
      now,
      now
    );
  return getPostById(id)!;
}

export function updatePost(
  id: string,
  input: {
    title: string;
    excerpt: string;
    body: string;
    coverImageUrl?: string;
    tags: string[];
    authorName: string;
    published: boolean;
  }
) {
  const existing = getPostById(id);
  if (!existing) return;
  const slug = existing.title === input.title ? existing.slug : uniqueSlug(input.title, id);
  const publishedAt = input.published ? existing.publishedAt || nowIso() : null;
  db()
    .prepare(
      `UPDATE blog_posts SET slug = ?, title = ?, excerpt = ?, body = ?, coverImageUrl = ?, tags = ?, authorName = ?, published = ?, publishedAt = ?, updatedAt = ?
       WHERE id = ?`
    )
    .run(
      slug,
      input.title,
      input.excerpt,
      input.body,
      input.coverImageUrl ?? null,
      JSON.stringify(input.tags),
      input.authorName,
      input.published ? 1 : 0,
      publishedAt,
      nowIso(),
      id
    );
}

export function deletePost(id: string) {
  db().prepare("DELETE FROM blog_posts WHERE id = ?").run(id);
}

// ---------- Impact stories ----------

export function listImpactStories(): ImpactStoryRecord[] {
  return db()
    .prepare("SELECT * FROM impact_stories ORDER BY sortOrder ASC, createdAt DESC")
    .all() as unknown as ImpactStoryRecord[];
}

export function getImpactStoryById(id: string): ImpactStoryRecord | undefined {
  return db().prepare("SELECT * FROM impact_stories WHERE id = ?").get(id) as unknown as
    | ImpactStoryRecord
    | undefined;
}

export function createImpactStory(input: {
  studentName: string;
  headline: string;
  story: string;
  photoUrl?: string;
  destinationCountry: string;
  targetLevel: TargetLevel;
  featured: boolean;
  sortOrder?: number;
}): ImpactStoryRecord {
  const id = newId();
  db()
    .prepare(
      `INSERT INTO impact_stories
        (id, studentName, headline, story, photoUrl, destinationCountry, targetLevel, featured, sortOrder, createdAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      id,
      input.studentName,
      input.headline,
      input.story,
      input.photoUrl ?? null,
      input.destinationCountry,
      input.targetLevel,
      input.featured ? 1 : 0,
      input.sortOrder ?? 0,
      nowIso()
    );
  return getImpactStoryById(id)!;
}

export function updateImpactStory(
  id: string,
  input: {
    studentName: string;
    headline: string;
    story: string;
    photoUrl?: string;
    destinationCountry: string;
    targetLevel: TargetLevel;
    featured: boolean;
    sortOrder?: number;
  }
) {
  db()
    .prepare(
      `UPDATE impact_stories SET studentName = ?, headline = ?, story = ?, photoUrl = ?, destinationCountry = ?, targetLevel = ?, featured = ?, sortOrder = ?
       WHERE id = ?`
    )
    .run(
      input.studentName,
      input.headline,
      input.story,
      input.photoUrl ?? null,
      input.destinationCountry,
      input.targetLevel,
      input.featured ? 1 : 0,
      input.sortOrder ?? 0,
      id
    );
}

export function deleteImpactStory(id: string) {
  db().prepare("DELETE FROM impact_stories WHERE id = ?").run(id);
}

// ---------- Volunteer / donate / apply leads ----------

export function listLeads(): VolunteerLeadRecord[] {
  return db().prepare("SELECT * FROM volunteer_leads ORDER BY createdAt DESC").all() as unknown as VolunteerLeadRecord[];
}

export function createLead(input: {
  type: LeadType;
  name: string;
  email: string;
  phone?: string;
  message: string;
  areasOfInterest?: string[];
  availability?: string;
}) {
  db()
    .prepare(
      `INSERT INTO volunteer_leads (id, type, name, email, phone, message, areasOfInterest, availability, handled, createdAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?)`
    )
    .run(
      newId(),
      input.type,
      input.name,
      input.email,
      input.phone ?? null,
      input.message,
      JSON.stringify(input.areasOfInterest ?? []),
      input.availability ?? "",
      nowIso()
    );
}

export function markLeadHandled(id: string, handled: boolean) {
  db().prepare("UPDATE volunteer_leads SET handled = ? WHERE id = ?").run(handled ? 1 : 0, id);
}


// ---------- Notifications ----------

export function createNotification(input: {
  userId: string;
  type: NotificationType;
  title: string;
  body?: string;
  link?: string;
}) {
  db()
    .prepare(
      `INSERT INTO notifications (id, userId, type, title, body, link, read, createdAt)
       VALUES (?, ?, ?, ?, ?, ?, 0, ?)`
    )
    .run(newId(), input.userId, input.type, input.title, input.body ?? "", input.link ?? null, nowIso());
}

/** Notify every admin at once - used for events any admin should see (new student, new lead). */
export function notifyAllAdmins(input: { type: NotificationType; title: string; body?: string; link?: string }) {
  const admins = db().prepare("SELECT id FROM users WHERE role = 'admin'").all() as unknown as { id: string }[];
  for (const admin of admins) {
    createNotification({ ...input, userId: admin.id });
  }
}

/** Full admin user records (id, email, name) - used to email every admin, not just notify in-app. */
export function listAdminUsers(): UserRecord[] {
  return db().prepare("SELECT * FROM users WHERE role = 'admin'").all() as unknown as UserRecord[];
}

export function listNotifications(userId: string, limit = 20): NotificationRecord[] {
  return db()
    .prepare("SELECT * FROM notifications WHERE userId = ? ORDER BY createdAt DESC LIMIT ?")
    .all(userId, limit) as unknown as NotificationRecord[];
}

export function countUnreadNotifications(userId: string): number {
  const row = db().prepare("SELECT COUNT(*) as count FROM notifications WHERE userId = ? AND read = 0").get(userId) as
    | { count: number }
    | undefined;
  return row?.count ?? 0;
}

export function markNotificationRead(id: string, userId: string) {
  db().prepare("UPDATE notifications SET read = 1 WHERE id = ? AND userId = ?").run(id, userId);
}

export function markAllNotificationsRead(userId: string) {
  db().prepare("UPDATE notifications SET read = 1 WHERE userId = ? AND read = 0").run(userId);
}

// ---------- Jobs ----------

export function createJob(input: {
  title: string;
  employer: string;
  country: string;
  city?: string;
  industry?: string;
  employmentType?: string;
  experienceRequired?: string;
  educationRequirement?: string;
  languageRequirement?: string;
  salary?: string;
  sponsorshipInfo?: string;
  applicationDeadline?: string | null;
  lastVerifiedDate?: string | null;
  source?: string;
  verificationStatus?: JobVerificationStatus;
  applicationUrl?: string;
  description?: string;
  published?: boolean;
}): JobRecord {
  const id = newId();
  const now = nowIso();
  db()
    .prepare(
      `INSERT INTO jobs
        (id, title, employer, country, city, industry, employmentType, experienceRequired, educationRequirement, languageRequirement, salary, sponsorshipInfo, applicationDeadline, lastVerifiedDate, source, verificationStatus, applicationUrl, description, published, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      id,
      input.title,
      input.employer,
      input.country,
      input.city ?? "",
      input.industry ?? "",
      input.employmentType ?? "",
      input.experienceRequired ?? "",
      input.educationRequirement ?? "",
      input.languageRequirement ?? "",
      input.salary ?? "",
      input.sponsorshipInfo ?? "",
      input.applicationDeadline ?? null,
      input.lastVerifiedDate ?? null,
      input.source ?? "",
      input.verificationStatus ?? "pending_verification",
      input.applicationUrl ?? "",
      input.description ?? "",
      input.published ? 1 : 0,
      now,
      now
    );
  return getJobById(id)!;
}

export function updateJob(
  id: string,
  input: Partial<Omit<JobRecord, "id" | "createdAt" | "updatedAt" | "published">> & { published?: boolean | number }
) {
  const current = getJobById(id);
  if (!current) return;
  const merged = {
    ...current,
    ...input,
    published: input.published === undefined ? current.published : input.published ? 1 : 0,
  };
  db()
    .prepare(
      `UPDATE jobs SET title = ?, employer = ?, country = ?, city = ?, industry = ?, employmentType = ?, experienceRequired = ?, educationRequirement = ?, languageRequirement = ?, salary = ?, sponsorshipInfo = ?, applicationDeadline = ?, lastVerifiedDate = ?, source = ?, verificationStatus = ?, applicationUrl = ?, description = ?, published = ?, updatedAt = ?
       WHERE id = ?`
    )
    .run(
      merged.title,
      merged.employer,
      merged.country,
      merged.city,
      merged.industry,
      merged.employmentType,
      merged.experienceRequired,
      merged.educationRequirement,
      merged.languageRequirement,
      merged.salary,
      merged.sponsorshipInfo,
      merged.applicationDeadline,
      merged.lastVerifiedDate,
      merged.source,
      merged.verificationStatus,
      merged.applicationUrl,
      merged.description,
      merged.published ? 1 : 0,
      nowIso(),
      id
    );
}

export function deleteJob(id: string) {
  db().prepare("DELETE FROM jobs WHERE id = ?").run(id);
}

export function getJobById(id: string): JobRecord | undefined {
  return db().prepare("SELECT * FROM jobs WHERE id = ?").get(id) as JobRecord | undefined;
}

/** All jobs, newest first - for the admin list (includes unpublished/expired). */
export function listAllJobs(): JobRecord[] {
  return db().prepare("SELECT * FROM jobs ORDER BY createdAt DESC").all() as unknown as JobRecord[];
}

/** Published, non-expired jobs only - for the public site. */
export function listPublishedJobs(): JobRecord[] {
  return db()
    .prepare("SELECT * FROM jobs WHERE published = 1 AND verificationStatus != 'expired' ORDER BY createdAt DESC")
    .all() as unknown as JobRecord[];
}

// ---------- Job applications ----------

/** Saves a job for a student (status "saved") if not already tracked. Safe to call repeatedly. */
export function saveJobForStudent(studentId: string, jobId: string): JobApplicationRecord {
  const existing = getJobApplication(studentId, jobId);
  if (existing) return existing;
  const id = newId();
  const now = nowIso();
  db()
    .prepare(
      `INSERT INTO job_applications (id, studentId, jobId, status, notes, createdAt, updatedAt)
       VALUES (?, ?, ?, 'saved', '', ?, ?)`
    )
    .run(id, studentId, jobId, now, now);
  return getJobApplicationById(id)!;
}

export function getJobApplication(studentId: string, jobId: string): JobApplicationRecord | undefined {
  return db()
    .prepare("SELECT * FROM job_applications WHERE studentId = ? AND jobId = ?")
    .get(studentId, jobId) as JobApplicationRecord | undefined;
}

export function getJobApplicationById(id: string): JobApplicationRecord | undefined {
  return db().prepare("SELECT * FROM job_applications WHERE id = ?").get(id) as JobApplicationRecord | undefined;
}

export function updateJobApplicationStatus(id: string, status: JobApplicationStatus) {
  db().prepare("UPDATE job_applications SET status = ?, updatedAt = ? WHERE id = ?").run(status, nowIso(), id);
}

export function withdrawJobApplication(id: string) {
  db().prepare("UPDATE job_applications SET status = 'withdrawn', updatedAt = ? WHERE id = ?").run(nowIso(), id);
}

export function deleteJobApplication(id: string) {
  db().prepare("DELETE FROM job_applications WHERE id = ?").run(id);
}

/** A student's tracked applications, newest first, with the job details joined in. */
export function listJobApplicationsForStudent(studentId: string): (JobApplicationRecord & { job: JobRecord })[] {
  const rows = db()
    .prepare(
      `SELECT ja.*, 
        j.id as job_id, j.title as job_title, j.employer as job_employer, j.country as job_country,
        j.city as job_city, j.industry as job_industry, j.employmentType as job_employmentType,
        j.applicationUrl as job_applicationUrl, j.verificationStatus as job_verificationStatus
       FROM job_applications ja
       JOIN jobs j ON j.id = ja.jobId
       WHERE ja.studentId = ?
       ORDER BY ja.updatedAt DESC`
    )
    .all(studentId) as unknown as Record<string, unknown>[];

  return rows.map((r) => ({
    id: r.id as string,
    studentId: r.studentId as string,
    jobId: r.jobId as string,
    status: r.status as JobApplicationStatus,
    notes: r.notes as string,
    createdAt: r.createdAt as string,
    updatedAt: r.updatedAt as string,
    job: {
      id: r.job_id as string,
      title: r.job_title as string,
      employer: r.job_employer as string,
      country: r.job_country as string,
      city: r.job_city as string,
      industry: r.job_industry as string,
      employmentType: r.job_employmentType as string,
      applicationUrl: r.job_applicationUrl as string,
      verificationStatus: r.job_verificationStatus as JobVerificationStatus,
    } as JobRecord,
  }));
}

export function countJobApplicationsByStatus(studentId: string): Record<string, number> {
  const rows = db()
    .prepare("SELECT status, COUNT(*) as count FROM job_applications WHERE studentId = ? GROUP BY status")
    .all(studentId) as unknown as { status: string; count: number }[];
  const counts: Record<string, number> = {};
  for (const row of rows) counts[row.status] = row.count;
  return counts;
}

'@
[System.IO.File]::WriteAllText("src/lib/repo.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/types" | Out-Null
$content = @'
export type Role = "admin" | "staff" | "student";

export type TargetLevel = "undergrad" | "masters" | "phd";

export type ApplicationStatus =
  | "new"
  | "documents_pending"
  | "in_review"
  | "submitted"
  | "scholarship_review"
  | "accepted"
  | "not_proceeding";

export const APPLICATION_STATUSES: { value: ApplicationStatus; label: string }[] = [
  { value: "new", label: "New" },
  { value: "documents_pending", label: "Documents pending" },
  { value: "in_review", label: "In review" },
  { value: "submitted", label: "Submitted" },
  { value: "scholarship_review", label: "Scholarship review" },
  { value: "accepted", label: "Accepted" },
  { value: "not_proceeding", label: "Not proceeding" },
];

export const TARGET_LEVELS: { value: TargetLevel; label: string }[] = [
  { value: "undergrad", label: "Undergraduate" },
  { value: "masters", label: "Master's" },
  { value: "phd", label: "PhD" },
];

export const TARGET_COUNTRIES = ["USA", "Canada", "UK", "Germany", "Other Europe", "Asia"];

export type CurrentEducationLevel = "shs_current" | "shs_graduate" | "tertiary" | "graduate" | "other";

export const CURRENT_EDUCATION_LEVELS: { value: CurrentEducationLevel; label: string }[] = [
  { value: "shs_graduate", label: "Completed Senior High School / awaiting results" },
  { value: "tertiary", label: "Currently in university / tertiary institution" },
  { value: "graduate", label: "Already completed a university degree" },
  { value: "other", label: "Other" },
];

export type ApplicationType = "standard" | "free_shs";

export interface DocumentItem {
  name: string;
  done: boolean;
  fileUrl?: string | null;
  uploadedAt?: string | null;
}

export interface UserRecord {
  id: string;
  username: string;
  email: string;
  passwordHash: string | null;
  role: Role;
  name: string;
  emailVerified: number;
  createdAt: string;
  updatedAt: string;
}

export interface StaffProfileRecord {
  id: string;
  userId: string | null;
  name: string;
  title: string;
  bio: string;
  photoUrl: string | null;
  sortOrder: number;
}

export interface BoardMemberRecord {
  id: string;
  name: string;
  title: string;
  bio: string;
  photoUrl: string | null;
  sortOrder: number;
}

export type ApplicationTrack = "university" | "work_visa";

export const YEARS_EXPERIENCE_OPTIONS = [
  "Less than 1 year",
  "1-3 years",
  "3-5 years",
  "5-10 years",
  "10+ years",
];

export interface StudentRecord {
  id: string;
  code: string;
  userId: string;
  targetLevel: TargetLevel;
  targetCountries: string; // JSON-encoded string[]
  status: ApplicationStatus;
  assignedStaffId: string | null;
  documents: string; // JSON-encoded DocumentItem[]
  scholarshipInterest: number;
  currentEducationLevel: CurrentEducationLevel | "";
  schoolName: string;
  applicationType: ApplicationType;
  photoUrl: string | null;
  applicationTrack: ApplicationTrack;
  profession: string;
  currentOccupation: string;
  yearsExperience: string;
  hasJobOffer: number;
  createdAt: string;
  updatedAt: string;
}

export interface StudentNoteRecord {
  id: string;
  studentId: string;
  authorId: string;
  text: string;
  attachmentUrl: string | null;
  createdAt: string;
}

export interface SiteContentRecord {
  id: number;
  orgName: string;
  tagline: string;
  mission: string;
  vision: string;
  contactEmail: string;
  contactPhone: string;
  address: string;
  donateInfo: string;
  logoUrl: string | null;
  heroImageUrl: string | null;
  founderName: string;
  founderTitle: string;
  founderBio: string;
  founderPhotoUrl: string | null;
  undergradInfo: string;
  mastersInfo: string;
  phdInfo: string;
  scholarshipsInfo: string;
  workVisaInfo: string;
  caretakingInfo: string;
}

export interface BlogPostRecord {
  id: string;
  slug: string;
  title: string;
  excerpt: string;
  body: string;
  coverImageUrl: string | null;
  tags: string; // JSON-encoded string[]
  authorName: string;
  published: number;
  publishedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface ImpactStoryRecord {
  id: string;
  studentName: string;
  headline: string;
  story: string;
  photoUrl: string | null;
  destinationCountry: string;
  targetLevel: TargetLevel;
  featured: number;
  sortOrder: number;
  createdAt: string;
}

export type LeadType = "volunteer" | "donate" | "apply_interest" | "contact";

export interface VolunteerLeadRecord {
  id: string;
  type: LeadType;
  name: string;
  email: string;
  phone: string | null;
  message: string;
  areasOfInterest: string; // JSON-encoded string[], only meaningful for type "volunteer"
  availability: string;
  handled: number;
  createdAt: string;
}

export const VOLUNTEER_AREAS = [
  "Essay review",
  "Mock interviews",
  "Mentoring a student",
  "Fundraising",
  "Event support",
  "Social media / content",
  "Other",
];

export interface SessionPayload {
  userId: string;
  role: Role;
  name: string;
}

export type NotificationType =
  | "message"
  | "document_uploaded"
  | "status_changed"
  | "student_assigned"
  | "new_student"
  | "new_lead"
  | "form_requested";

export interface NotificationRecord {
  id: string;
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  link: string | null;
  read: number;
  createdAt: string;
}

export type JobVerificationStatus =
  | "verified"
  | "employer_source"
  | "government_source"
  | "pending_verification"
  | "expired";

export const JOB_VERIFICATION_LABELS: Record<JobVerificationStatus, string> = {
  verified: "Verified",
  employer_source: "Employer Source",
  government_source: "Government/Official Source",
  pending_verification: "Pending Verification",
  expired: "Expired",
};

export const JOB_COUNTRIES = ["USA", "Germany", "Other"];

export interface JobRecord {
  id: string;
  title: string;
  employer: string;
  country: string;
  city: string;
  industry: string;
  employmentType: string;
  experienceRequired: string;
  educationRequirement: string;
  languageRequirement: string;
  salary: string;
  sponsorshipInfo: string;
  applicationDeadline: string | null;
  lastVerifiedDate: string | null;
  source: string;
  verificationStatus: JobVerificationStatus;
  applicationUrl: string;
  description: string;
  published: number;
  createdAt: string;
  updatedAt: string;
}

export type JobApplicationStatus =
  | "saved"
  | "preparing"
  | "applied"
  | "employer_review"
  | "interview"
  | "offer_received"
  | "accepted"
  | "not_selected"
  | "withdrawn";

export const JOB_APPLICATION_STATUSES: { value: JobApplicationStatus; label: string }[] = [
  { value: "saved", label: "Saved" },
  { value: "preparing", label: "Preparing" },
  { value: "applied", label: "Applied" },
  { value: "employer_review", label: "Employer Review" },
  { value: "interview", label: "Interview" },
  { value: "offer_received", label: "Offer Received" },
  { value: "accepted", label: "Accepted" },
  { value: "not_selected", label: "Not Selected" },
  { value: "withdrawn", label: "Withdrawn" },
];

export interface JobApplicationRecord {
  id: string;
  studentId: string;
  jobId: string;
  status: JobApplicationStatus;
  notes: string;
  createdAt: string;
  updatedAt: string;
}

'@
[System.IO.File]::WriteAllText("src/types/index.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/student" | Out-Null
$content = @'
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

'@
[System.IO.File]::WriteAllText("src/app/student/job-browse-list.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/student" | Out-Null
$content = @'
"use client";

import { useTransition } from "react";
import { updateMyApplicationStatusAction, withdrawMyApplicationAction } from "@/app/actions/jobs";
import { JOB_APPLICATION_STATUSES, type JobApplicationStatus, type JobRecord } from "@/types";

interface TrackedApplication {
  id: string;
  status: JobApplicationStatus;
  job: JobRecord;
}

export function MyApplicationsList({ applications }: { applications: TrackedApplication[] }) {
  const [pending, startTransition] = useTransition();

  function handleStatusChange(applicationId: string, formData: FormData) {
    startTransition(() => updateMyApplicationStatusAction(applicationId, formData));
  }

  function handleWithdraw(applicationId: string) {
    if (!confirm("Withdraw this application? You can still see it, but its status will be marked withdrawn.")) return;
    startTransition(() => withdrawMyApplicationAction(applicationId));
  }

  if (applications.length === 0) {
    return <p className="text-sm text-ink/50 italic">You haven't saved or applied to any opportunities yet.</p>;
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
          <div className="flex items-center gap-3 shrink-0">
            <form action={(fd) => handleStatusChange(app.id, fd)}>
              <select
                name="status"
                defaultValue={app.status}
                disabled={pending || app.status === "withdrawn"}
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
            {app.status !== "withdrawn" && (
              <button
                type="button"
                onClick={() => handleWithdraw(app.id)}
                disabled={pending}
                className="text-xs text-red-700 hover:underline"
              >
                Withdraw
              </button>
            )}
          </div>
        </div>
      ))}
    </div>
  );
}

'@
[System.IO.File]::WriteAllText("src/app/student/my-applications-list.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
$content = @'
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

'@
[System.IO.File]::WriteAllText("src/components/applications-review.tsx", $content, $Utf8NoBom)

git add -A
git commit -m "Add job application tracking: save jobs, 9-stage status pipeline, staff/admin oversight (Phase 2b/2c)"
git push

Write-Host 'Done. Files written and pushed.'