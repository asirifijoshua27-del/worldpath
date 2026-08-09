"use client";

import { useRef, useState, useTransition } from "react";
import { studentUploadDocumentAction } from "@/app/actions/student";
import type { DocumentItem } from "@/types";

export function DocumentUploadRow({ doc, index }: { doc: DocumentItem; index: number }) {
  const fileRef = useRef<HTMLInputElement>(null);
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  function handleFile(file: File | undefined) {
    if (!file) return;
    setError(null);
    const formData = new FormData();
    formData.set("index", String(index));
    formData.set("file", file);
    startTransition(async () => {
      const result = await studentUploadDocumentAction(formData);
      if (result?.error) setError(result.error);
    });
  }

  return (
    <li className="border border-line rounded-lg px-3 py-2.5">
      <div className="flex items-center justify-between gap-3">
        <div className="flex items-center gap-3 min-w-0">
          <span
            className={`w-4 h-4 rounded border grid place-items-center text-[10px] shrink-0 ${
              doc.done ? "bg-teal border-teal text-white" : "border-line"
            }`}
          >
            {doc.done ? "Ã¢Å“â€œ" : ""}
          </span>
          <span className={`text-sm truncate ${doc.done ? "" : "text-ink/80"}`}>{doc.name}</span>
        </div>
        <div className="flex items-center gap-3 shrink-0 text-xs">
          {doc.fileUrl && (
            <a href={doc.fileUrl} target="_blank" rel="noopener noreferrer" className="text-teal hover:underline">
              View
            </a>
          )}
          <button
            type="button"
            onClick={() => fileRef.current?.click()}
            disabled={pending}
            className="text-teal hover:underline disabled:opacity-60"
          >
            {pending ? "Uploading..." : doc.fileUrl ? "Replace" : "Upload"}
          </button>
          <input
            ref={fileRef}
            type="file"
            accept="image/jpeg,image/png,image/webp,image/gif,application/pdf"
            className="hidden"
            onChange={(e) => handleFile(e.target.files?.[0])}
          />
        </div>
      </div>
      {error && <p className="text-xs text-red-700 mt-1.5">{error}</p>}
    </li>
  );
}

