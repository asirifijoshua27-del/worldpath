"use server";

import { revalidatePath } from "next/cache";
import { getSession } from "@/lib/auth";
import { saveUploadedImage, deleteUploadedImage, UploadError } from "@/lib/uploads";
import { createImpactStory, updateImpactStory, deleteImpactStory, getImpactStoryById } from "@/lib/repo";
import { impactStorySchema } from "@/lib/validators";
import type { FormState } from "@/app/actions/auth";
export type { FormState } from "@/app/actions/auth";

async function requireAdmin() {
  const session = await getSession();
  if (!session || session.role !== "admin") {
    throw new Error("Not authorized");
  }
}

export async function saveImpactStoryAction(_prev: FormState, formData: FormData): Promise<FormState> {
  await requireAdmin();
  const id = String(formData.get("id") || "");
  const existingPhotoUrl = String(formData.get("existingPhotoUrl") || "");
  const photoFile = formData.get("photo");

  let photoUrl = existingPhotoUrl;
  if (photoFile instanceof File && photoFile.size > 0) {
    try {
      photoUrl = await saveUploadedImage(photoFile);
    } catch (e) {
      if (e instanceof UploadError) return { error: e.message };
      throw e;
    }
    if (existingPhotoUrl) await deleteUploadedImage(existingPhotoUrl);
  }

  const parsed = impactStorySchema.safeParse({
    studentName: String(formData.get("studentName") || ""),
    headline: String(formData.get("headline") || ""),
    story: String(formData.get("story") || ""),
    photoUrl,
    destinationCountry: String(formData.get("destinationCountry") || ""),
    targetLevel: String(formData.get("targetLevel") || "undergrad"),
    featured: formData.get("featured") === "on",
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }

  if (id) {
    updateImpactStory(id, parsed.data);
  } else {
    createImpactStory(parsed.data);
  }
  revalidatePath("/admin/impact");
  revalidatePath("/impact");
  return { success: "Story saved." };
}

export async function deleteImpactStoryAction(id: string) {
  await requireAdmin();
  const story = getImpactStoryById(id);
  deleteImpactStory(id);
  await deleteUploadedImage(story?.photoUrl);
  revalidatePath("/admin/impact");
  revalidatePath("/impact");
}
