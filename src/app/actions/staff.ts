"use server";

import { revalidatePath } from "next/cache";
import { getSession } from "@/lib/auth";
import {
  getStaffByUserId,
  getStudentById,
  updateStudentStatus,
  updateStudentDocuments,
  addNote,
  createNotification,
} from "@/lib/repo";
import { APPLICATION_STATUSES } from "@/types";
import { noteSchema } from "@/lib/validators";
import { saveUploadedDocument, UploadError } from "@/lib/uploads";
import type { FormState } from "@/app/actions/auth";
import type { DocumentItem } from "@/types";

async function requireOwningStaff(studentId: string) {
  const session = await getSession();
  if (!session || session.role !== "staff") {
    throw new Error("Not authorized");
  }
  const staff = getStaffByUserId(session.userId);
  const student = getStudentById(studentId);
  if (!staff || !student || student.assignedStaffId !== staff.id) {
    throw new Error("Not authorized for this student");
  }
  return { session, staff, student };
}

export async function staffUpdateStatusAction(formData: FormData) {
  const studentId = String(formData.get("studentId") || "");
  const { student } = await requireOwningStaff(studentId);
  const status = String(formData.get("status") || "");
  updateStudentStatus(studentId, status);

  const statusLabel = APPLICATION_STATUSES.find((s) => s.value === status)?.label ?? status;
  createNotification({
    userId: student.userId,
    type: "status_changed",
    title: "Your application status changed",
    body: `Your status is now "${statusLabel}".`,
    link: "/student",
  });

  revalidatePath(`/staff/students/${studentId}`);
  revalidatePath("/staff");
}

export async function staffToggleDocumentAction(formData: FormData) {
  const studentId = String(formData.get("studentId") || "");
  const index = Number(formData.get("index") || 0);
  const { student } = await requireOwningStaff(studentId);
  const docs = JSON.parse(student.documents) as DocumentItem[];
  if (docs[index]) {
    docs[index] = { ...docs[index], done: !docs[index].done };
  }
  updateStudentDocuments(studentId, docs);
  revalidatePath(`/staff/students/${studentId}`);
}

export async function staffAddNoteAction(
  studentId: string,
  _prev: FormState,
  formData: FormData
): Promise<FormState> {
  const { session, student } = await requireOwningStaff(studentId);
  const parsed = noteSchema.safeParse({ text: String(formData.get("text") || "") });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }

  const attachmentFile = formData.get("image");
  let attachmentUrl: string | null = null;
  if (attachmentFile instanceof File && attachmentFile.size > 0) {
    try {
      attachmentUrl = await saveUploadedDocument(attachmentFile);
    } catch (e) {
      if (e instanceof UploadError) return { error: e.message };
      throw e;
    }
  }

  if (!parsed.data.text.trim() && !attachmentUrl) {
    return { error: "Add a note or attach a file." };
  }

  addNote(studentId, session.userId, parsed.data.text.trim(), attachmentUrl);

  createNotification({
    userId: student.userId,
    type: "message",
    title: `New message from ${session.name}`,
    body: parsed.data.text.trim().slice(0, 80) || "Sent an attachment.",
    link: "/student",
  });

  revalidatePath(`/staff/students/${studentId}`);
  return { success: "Note added." };
}

