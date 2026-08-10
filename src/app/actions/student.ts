"use server";

import { revalidatePath } from "next/cache";
import { getSession } from "@/lib/auth";
import { getStudentByUserId, updateStudentDocuments, addNote, getStaffById } from "@/lib/repo";
import { notifyUser } from "@/lib/notify";
import { noteSchema } from "@/lib/validators";
import { saveUploadedDocument, UploadError, deleteUploadedImage } from "@/lib/uploads";
import type { FormState } from "@/app/actions/auth";
import type { DocumentItem } from "@/types";
export type { FormState } from "@/app/actions/auth";

async function requireOwnStudentRecord() {
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

async function notifyAssignedStaff(
  assignedStaffId: string | null,
  studentId: string,
  input: { type: "message" | "document_uploaded" | "form_requested"; title: string; body: string }
) {
  if (!assignedStaffId) return;
  const staff = getStaffById(assignedStaffId);
  if (!staff?.userId) return;
  await notifyUser({
    userId: staff.userId,
    type: input.type,
    title: input.title,
    body: input.body,
    link: `/staff/students/${studentId}`,
  });
}

export async function studentUploadDocumentAction(formData: FormData): Promise<FormState> {
  const { session, student } = await requireOwnStudentRecord();
  const index = Number(formData.get("index") || -1);
  const file = formData.get("file");

  if (!(file instanceof File) || file.size === 0) {
    return { error: "Please choose a file first." };
  }

  const docs = JSON.parse(student.documents) as DocumentItem[];
  if (!docs[index]) {
    return { error: "That document slot doesn't exist." };
  }

  let fileUrl: string;
  try {
    fileUrl = await saveUploadedDocument(file);
  } catch (e) {
    if (e instanceof UploadError) return { error: e.message };
    throw e;
  }

  if (docs[index].fileUrl) await deleteUploadedImage(docs[index].fileUrl);

  docs[index] = { ...docs[index], fileUrl, done: true, uploadedAt: new Date().toISOString() };
  updateStudentDocuments(student.id, docs);

  await notifyAssignedStaff(student.assignedStaffId, student.id, {
    type: "document_uploaded",
    title: `${session.name} uploaded a document`,
    body: docs[index].name,
  });

  revalidatePath("/student");
  return { success: "Document uploaded." };
}

export async function studentAddNoteAction(_prev: FormState, formData: FormData): Promise<FormState> {
  const { session, student } = await requireOwnStudentRecord();

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
    return { error: "Add a message or attach a file." };
  }

  addNote(student.id, session.userId, parsed.data.text.trim(), attachmentUrl);

  await notifyAssignedStaff(student.assignedStaffId, student.id, {
    type: "message",
    title: `New message from ${session.name}`,
    body: parsed.data.text.trim().slice(0, 80) || "Sent an attachment.",
  });

  revalidatePath("/student");
  return { success: "Message sent." };
}

/**
 * Standard (non-free) applicants request their application form from their
 * assigned counselor, rather than getting one automatically. This notifies
 * the counselor and drops a message in the shared thread so there's a
 * record of the request; the counselor replies with the form as a message
 * attachment.
 */
export async function requestApplicationFormAction(): Promise<FormState> {
  const { session, student } = await requireOwnStudentRecord();

  if (student.applicationType !== "standard") {
    return { error: "This is only needed for standard applications." };
  }
  if (!student.assignedStaffId) {
    return { error: "You don't have a counselor assigned yet. Please check back soon." };
  }

  const staff = getStaffById(student.assignedStaffId);
  if (!staff?.userId) {
    return { error: "Your counselor doesn't have an active account yet. Please check back soon." };
  }

  addNote(student.id, session.userId, "Requested the application form.");

  await notifyUser({
    userId: staff.userId,
    type: "form_requested",
    title: `${session.name} requested the application form`,
    body: "Reply in their message thread with the form attached.",
    link: `/staff/students/${student.id}`,
  });

  revalidatePath("/student");
  return { success: "Request sent to your counselor." };
}
