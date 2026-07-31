import fs from "node:fs/promises";
import path from "node:path";
import { randomUUID } from "node:crypto";

// Uploaded files are stored under data/uploads (NOT /public). Next.js's
// production server snapshots the contents of /public at build time, so
// files written there while the server is already running wouldn't be
// served until a restart. Serving them instead through the dynamic route
// handler at /api/uploads/[filename] reads the file from disk on every
// request, so newly uploaded files show up immediately.

const UPLOAD_DIR = process.env.UPLOAD_DIR || path.join(process.cwd(), "data", "uploads");
const MAX_BYTES = 5 * 1024 * 1024; // 5MB

const IMAGE_TYPES: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
  "image/gif": "gif",
};

const DOCUMENT_TYPES: Record<string, string> = {
  ...IMAGE_TYPES,
  "application/pdf": "pdf",
};

export class UploadError extends Error {}

export function uploadDir(): string {
  return UPLOAD_DIR;
}

async function saveFile(file: File, allowedTypes: Record<string, string>, kindLabel: string): Promise<string> {
  if (file.size === 0) {
    throw new UploadError("No file was selected.");
  }
  if (file.size > MAX_BYTES) {
    throw new UploadError(`File must be smaller than 5MB.`);
  }
  const ext = allowedTypes[file.type];
  if (!ext) {
    throw new UploadError(`Please upload ${kindLabel}.`);
  }

  await fs.mkdir(UPLOAD_DIR, { recursive: true });

  const filename = `${randomUUID()}.${ext}`;
  const buffer = Buffer.from(await file.arrayBuffer());
  await fs.writeFile(path.join(UPLOAD_DIR, filename), buffer);

  return `/api/uploads/${filename}`;
}

/**
 * Saves an uploaded image File to the uploads directory and returns its
 * public URL path (e.g. "/api/uploads/xxxx.jpg"). Throws UploadError on
 * invalid input.
 */
export async function saveUploadedImage(file: File): Promise<string> {
  return saveFile(file, IMAGE_TYPES, "a JPG, PNG, WEBP, or GIF image");
}

/**
 * Saves an uploaded application document (a photo of a document, or a PDF).
 * Used for student document-checklist uploads.
 */
export async function saveUploadedDocument(file: File): Promise<string> {
  return saveFile(file, DOCUMENT_TYPES, "a JPG, PNG, WEBP, GIF, or PDF file");
}

/** Deletes a previously uploaded file given its public URL path, if it's one of ours. */
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
