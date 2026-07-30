"use client";

import { staffToggleDocumentAction } from "@/app/actions/staff";
import type { DocumentItem } from "@/types";

export function DocumentChecklist({ studentId, documents }: { studentId: string; documents: DocumentItem[] }) {
  return (
    <ul className="space-y-2">
      {documents.map((doc, index) => (
        <li key={doc.name}>
          <form action={staffToggleDocumentAction}>
            <input type="hidden" name="studentId" value={studentId} />
            <input type="hidden" name="index" value={index} />
            <button
              type="submit"
              className="w-full flex items-center gap-3 border border-line rounded-lg px-3 py-2 text-sm hover:border-ink transition-colors text-left"
            >
              <span
                className={`w-4 h-4 rounded border grid place-items-center text-[10px] ${
                  doc.done ? "bg-teal border-teal text-white" : "border-line"
                }`}
              >
                {doc.done ? "✓" : ""}
              </span>
              <span className={doc.done ? "line-through text-ink/50" : ""}>{doc.name}</span>
            </button>
          </form>
        </li>
      ))}
    </ul>
  );
}
