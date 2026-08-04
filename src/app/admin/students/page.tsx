import { listStudents, listStaff, getUserById } from "@/lib/repo";
import { StudentRow } from "./student-row";

export const dynamic = "force-dynamic";

export default function AdminStudentsPage() {
  const students = listStudents();
  const staff = listStaff();

  const rows = students.map((s) => {
    const user = getUserById(s.userId);
    return {
      id: s.id,
      userId: s.userId,
      code: s.code,
      name: user?.name || "â€”",
      email: user?.email || "â€”",
      targetLevel: s.targetLevel,
      status: s.status,
      assignedStaffId: s.assignedStaffId,
      applicationType: s.applicationType,
      schoolName: s.schoolName,
      photoUrl: s.photoUrl,
    };
  });

  return (
    <div>
      <h1 className="font-display text-3xl mb-2">Students</h1>
      <p className="text-ink/60 mb-8">Every student record across the organization. Changes save instantly.</p>

      <div className="overflow-x-auto border border-line rounded-xl">
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-xs uppercase tracking-wide text-ink/50 border-b border-line">
              <th className="py-3 px-4 font-medium"></th>
              <th className="py-3 px-4 font-medium">Code</th>
              <th className="py-3 px-4 font-medium">Student</th>
              <th className="py-3 px-4 font-medium">Program</th>
              <th className="py-3 px-4 font-medium">Level</th>
              <th className="py-3 px-4 font-medium">Status</th>
              <th className="py-3 px-4 font-medium">Assigned staff</th>
              <th className="py-3 px-4 font-medium"></th>
            </tr>
          </thead>
          <tbody className="px-4">
            {rows.length === 0 && (
              <tr>
                <td colSpan={8} className="py-6 px-4 text-ink/50 italic">
                  No students have registered yet.
                </td>
              </tr>
            )}
            {rows.map((r) => (
              <StudentRow key={r.id} student={r} staffOptions={staff.map((s) => ({ id: s.id, name: s.name }))} />
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

