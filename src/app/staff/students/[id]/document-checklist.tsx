"use client";

import { staffToggleDocumentAction } from "@/app/actions/staff";
import type { DocumentItem } from "@/types";

export function DocumentChecklist({ studentId, documents }: { studentId: string; documents: DocumentItem[] }) {
  return (
    <ul className="space-y-2">
      {documents.map((doc, index) => (
        <li key={doc.name} className="flex items-center gap-2">
          <form action={staffToggleDocumentAction} className="flex-1">
            <input type="hidden" name="studentId" value={studentId} />
            <input type="hidden" name="index" value={index} />
            <button
              type="submit"
              className="w-full flex items-center gap-3 border border-line rounded-lg px-3 py-2 text-sm hover:border-ink transition-colors text-left"
            >
              <span
                className={`w-4 h-4 rounded border grid place-items-center text-[10px] shrink-0 ${
                  doc.done ? "bg-teal border-teal text-white" : "border-line"
                }`}
              >
                {doc.done ? "Ã¢Å“â€œ" : ""}
              </span>
              <span className={`truncate ${doc.done ? "line-through text-ink/50" : ""}`}>{doc.name}</span>
            </button>
          </form>
          {doc.fileUrl && (
            <a
              href={doc.fileUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="text-xs text-teal hover:underline shrink-0"
            >
              View file
            </a>
          )}
        </li>
      ))}
    </ul>
  );
}

