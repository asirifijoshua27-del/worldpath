import { listStudentsByTrack, listStaff, getUserById } from "@/lib/repo";
import { StudentRow } from "../students/student-row";

export const dynamic = "force-dynamic";

export default function AdminWorkVisaApplicantsPage() {
  const students = listStudentsByTrack("work_visa");
  const staff = listStaff();

  const rows = students.map((s) => {
    const user = getUserById(s.userId);
    return {
      id: s.id,
      userId: s.userId,
      code: s.code,
      name: user?.name || "-",
      email: user?.email || "-",
      targetLevel: s.targetLevel,
      status: s.status,
      assignedStaffId: s.assignedStaffId,
      applicationType: s.applicationType,
      schoolName: s.schoolName,
      photoUrl: s.photoUrl,
      applicationTrack: s.applicationTrack,
      profession: s.profession,
    };
  });

  return (
    <div>
      <h1 className="font-display text-3xl mb-2">Work Visa Applicants</h1>
      <p className="text-ink/60 mb-8">
        International Careers & Work Visa Support applicants, separate from university/scholarship students.{" "}
        <a href="/admin/students" className="text-teal hover:underline">
          View students &rarr;
        </a>
      </p>

      <div className="overflow-x-auto border border-line rounded-xl">
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-xs uppercase tracking-wide text-ink/50 border-b border-line">
              <th className="py-3 px-4 font-medium"></th>
              <th className="py-3 px-4 font-medium">Code</th>
              <th className="py-3 px-4 font-medium">Applicant</th>
              <th className="py-3 px-4 font-medium">Program</th>
              <th className="py-3 px-4 font-medium">Profession</th>
              <th className="py-3 px-4 font-medium">Status</th>
              <th className="py-3 px-4 font-medium">Assigned staff</th>
              <th className="py-3 px-4 font-medium"></th>
            </tr>
          </thead>
          <tbody className="px-4">
            {rows.length === 0 && (
              <tr>
                <td colSpan={8} className="py-6 px-4 text-ink/50 italic">
                  No work visa applicants have registered yet.
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
