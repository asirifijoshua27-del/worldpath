"use server";

import { revalidatePath } from "next/cache";
import { getSession } from "@/lib/auth";
import { saveUploadedImage, deleteUploadedImage, UploadError } from "@/lib/uploads";
import { createPost, updatePost, deletePost, getPostById } from "@/lib/repo";
import { blogPostSchema } from "@/lib/validators";
import type { FormState } from "@/app/actions/auth";
export type { FormState } from "@/app/actions/auth";

async function requireAdmin() {
  const session = await getSession();
  if (!session || session.role !== "admin") {
    throw new Error("Not authorized");
  }
  return session;
}

function parseTags(raw: string): string[] {
  return raw
    .split(",")
    .map((t) => t.trim())
    .filter(Boolean);
}

export async function saveBlogPostAction(_prev: FormState, formData: FormData): Promise<FormState> {
  const session = await requireAdmin();
  const id = String(formData.get("id") || "");
  const existingCoverUrl = String(formData.get("existingCoverUrl") || "");
  const coverFile = formData.get("cover");

  let coverImageUrl = existingCoverUrl;
  if (coverFile instanceof File && coverFile.size > 0) {
    try {
      coverImageUrl = await saveUploadedImage(coverFile);
    } catch (e) {
      if (e instanceof UploadError) return { error: e.message };
      throw e;
    }
    if (existingCoverUrl) await deleteUploadedImage(existingCoverUrl);
  }

  const parsed = blogPostSchema.safeParse({
    title: String(formData.get("title") || ""),
    excerpt: String(formData.get("excerpt") || ""),
    body: String(formData.get("body") || ""),
    coverImageUrl,
    tags: parseTags(String(formData.get("tags") || "")),
    authorName: String(formData.get("authorName") || session.name),
    published: formData.get("published") === "on",
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }

  if (id) {
    updatePost(id, parsed.data);
  } else {
    createPost(parsed.data);
  }
  revalidatePath("/admin/blog");
  revalidatePath("/blog");
  return { success: "Post saved." };
}

export async function deleteBlogPostAction(id: string) {
  await requireAdmin();
  const post = getPostById(id);
  deletePost(id);
  await deleteUploadedImage(post?.coverImageUrl);
  revalidatePath("/admin/blog");
  revalidatePath("/blog");
}
