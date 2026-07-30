import fs from "node:fs/promises";
import path from "node:path";
import { randomUUID } from "node:crypto";

// Uploaded files are stored under data/uploads (NOT /public). Next.js's
// production server snapshots the contents of /public at build time, so
// files written there while the server is already running wouldn't be
// served until a restart. Serving them instead through the dynamic route
// handler at /api/uploads/[filename] reads the file from disk on every
// request, so newly uploaded photos show up immediately.

const UPLOAD_DIR = process.env.UPLOAD_DIR || path.join(process.cwd(), "data", "uploads");
const MAX_BYTES = 5 * 1024 * 1024; // 5MB
const ALLOWED_TYPES: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
  "image/gif": "gif",
};

export class UploadError extends Error {}

export function uploadDir(): string {
  return UPLOAD_DIR;
}

/**
 * Saves an uploaded image File to the uploads directory and returns its
 * public URL path (e.g. "/api/uploads/xxxx.jpg"). Throws UploadError on
 * invalid input.
 */
export async function saveUploadedImage(file: File): Promise<string> {
  if (file.size === 0) {
    throw new UploadError("No file was selected.");
  }
  if (file.size > MAX_BYTES) {
    throw new UploadError("Image must be smaller than 5MB.");
  }
  const ext = ALLOWED_TYPES[file.type];
  if (!ext) {
    throw new UploadError("Please upload a JPG, PNG, WEBP, or GIF image.");
  }

  await fs.mkdir(UPLOAD_DIR, { recursive: true });

  const filename = `${randomUUID()}.${ext}`;
  const buffer = Buffer.from(await file.arrayBuffer());
  await fs.writeFile(path.join(UPLOAD_DIR, filename), buffer);

  return `/api/uploads/${filename}`;
}

/** Deletes a previously uploaded image given its public URL path, if it's one of ours. */
export async function deleteUploadedImage(url: string | null | undefined): Promise<void> {
  if (!url || !url.startsWith("/api/uploads/")) return;
  const filename = url.replace("/api/uploads/", "");
  if (!filename || filename.includes("/") || filename.includes("..")) return;
  try {
    await fs.unlink(path.join(UPLOAD_DIR, filename));
  } catch {
    // File may already be gone — safe to ignore.
  }
}
