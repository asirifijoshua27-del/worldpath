"use server";

import { revalidatePath } from "next/cache";
import { getSession } from "@/lib/auth";
import { getStudentByUserId, updateStudentDocuments, addNote } from "@/lib/repo";
import { noteSchema } from "@/lib/validators";
import { saveUploadedDocument, saveUploadedImage, UploadError, deleteUploadedImage } from "@/lib/uploads";
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

export async function studentUploadDocumentAction(formData: FormData): Promise<FormState> {
  const { student } = await requireOwnStudentRecord();
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
  revalidatePath("/student");
  return { success: "Document uploaded." };
}

export async function studentAddNoteAction(_prev: FormState, formData: FormData): Promise<FormState> {
  const { session, student } = await requireOwnStudentRecord();

  const parsed = noteSchema.safeParse({ text: String(formData.get("text") || "") });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }

  const imageFile = formData.get("image");
  let attachmentUrl: string | null = null;
  if (imageFile instanceof File && imageFile.size > 0) {
    try {
      attachmentUrl = await saveUploadedImage(imageFile);
    } catch (e) {
      if (e instanceof UploadError) return { error: e.message };
      throw e;
    }
  }

  if (!parsed.data.text.trim() && !attachmentUrl) {
    return { error: "Add a message or attach a picture." };
  }

  addNote(student.id, session.userId, parsed.data.text.trim(), attachmentUrl);
  revalidatePath("/student");
  return { success: "Message sent." };
}

