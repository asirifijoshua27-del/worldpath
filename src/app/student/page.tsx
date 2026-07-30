import { getSession } from "@/lib/auth";
import { getStudentByUserId, getStaffById, listNotesForStudent } from "@/lib/repo";
import { APPLICATION_STATUSES } from "@/types";
import type { DocumentItem } from "@/types";

export const dynamic = "force-dynamic";

export default async function StudentHomePage() {
  const session = await getSession();
  const student = session ? getStudentByUserId(session.userId) : undefined;

  if (!student) {
    return <p className="text-ink/60">We couldn't find your application record. Please contact WorldPath Group.</p>;
  }

  const staff = student.assignedStaffId ? getStaffById(student.assignedStaffId) : undefined;
  const notes = listNotesForStudent(student.id);
  const documents = JSON.parse(student.documents) as DocumentItem[];
  const targetCountries = JSON.parse(student.targetCountries) as string[];
  const statusLabel = APPLICATION_STATUSES.find((s) => s.value === student.status)?.label ?? student.status;
  const completedDocs = documents.filter((d) => d.done).length;

  return (
    <div>
      <p className="font-mono text-xs bg-paper-dim border border-line rounded px-2 py-1 inline-block mb-3">
        {student.code}
      </p>
      <h1 className="font-display text-3xl mb-2">Welcome, {session?.name}</h1>
      <p className="text-ink/60 mb-10">
        {staff ? `Your counselor is ${staff.name}.` : "A counselor hasn't been assigned yet — one will be soon."}
      </p>

      <div className="grid sm:grid-cols-2 gap-6 mb-10">
        <div className="border border-line rounded-xl p-5">
          <p className="text-xs uppercase tracking-wide text-ink/50 mb-1">Application status</p>
          <p className="font-display text-xl text-gold-deep">{statusLabel}</p>
        </div>
        <div className="border border-line rounded-xl p-5">
          <p className="text-xs uppercase tracking-wide text-ink/50 mb-1">Targeting</p>
          <p className="capitalize">{student.targetLevel}</p>
          <p className="text-sm text-ink/70">{targetCountries.join(", ")}</p>
        </div>
      </div>

      <div className="mb-10">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-display text-xl">Document checklist</h2>
          <span className="text-sm text-ink/50">
            {completedDocs}/{documents.length} complete
          </span>
        </div>
        <ul className="space-y-2">
          {documents.map((doc) => (
            <li
              key={doc.name}
              className="flex items-center gap-3 border border-line rounded-lg px-3 py-2 text-sm"
            >
              <span
                className={`w-4 h-4 rounded border grid place-items-center text-[10px] ${
                  doc.done ? "bg-teal border-teal text-white" : "border-line"
                }`}
              >
                {doc.done ? "✓" : ""}
              </span>
              <span className={doc.done ? "line-through text-ink/50" : ""}>{doc.name}</span>
            </li>
          ))}
        </ul>
      </div>

      <div>
        <h2 className="font-display text-xl mb-4">Notes from your counselor</h2>
        {notes.length === 0 && <p className="text-sm text-ink/50 italic">No notes yet.</p>}
        <div className="space-y-4">
          {notes.map((n) => (
            <div key={n.id} className="border-b border-line pb-4">
              <p className="text-sm">{n.text}</p>
              <p className="text-xs text-ink/40 mt-1">
                {n.authorName} · {new Date(n.createdAt).toLocaleString()}
              </p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
