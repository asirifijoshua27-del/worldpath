import Link from "next/link";
import { getSession } from "@/lib/auth";
import { getStaffByUserId, listStudentsByStaff, getUserById } from "@/lib/repo";
import { APPLICATION_STATUSES } from "@/types";

export const dynamic = "force-dynamic";

export default async function StaffHomePage() {
  const session = await getSession();
  const staff = session ? getStaffByUserId(session.userId) : undefined;
  const students = staff ? listStudentsByStaff(staff.id) : [];

  const statusLabel = (value: string) => APPLICATION_STATUSES.find((s) => s.value === value)?.label ?? value;

  return (
    <div>
      <h1 className="font-display text-3xl mb-2">My students</h1>
      <p className="text-ink/60 mb-8">Students currently assigned to you.</p>

      {!staff && (
        <p className="text-sm text-ink/50 italic border border-dashed border-line rounded-xl p-6">
          No staff profile is linked to your account yet. Ask an admin to link one.
        </p>
      )}

      {staff && students.length === 0 && (
        <p className="text-sm text-ink/50 italic border border-dashed border-line rounded-xl p-6">
          No students are assigned to you yet.
        </p>
      )}

      {staff && students.length > 0 && (
        <div className="divide-y divide-line border border-line rounded-xl">
          {students.map((s) => {
            const user = getUserById(s.userId);
            return (
              <Link
                key={s.id}
                href={`/staff/students/${s.id}`}
                className="p-4 flex items-center gap-4 hover:bg-paper-dim transition-colors"
              >
                <div className="w-10 h-10 rounded-full bg-paper-dim border border-line overflow-hidden shrink-0">
                  {s.photoUrl ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={s.photoUrl} alt={user?.name || ""} className="w-full h-full object-cover" />
                  ) : (
                    <div className="w-full h-full grid place-items-center text-xs text-ink/40">
                      {user?.name?.charAt(0) ?? "?"}
                    </div>
                  )}
                </div>
                <div className="flex-1">
                  <p className="font-medium">{user?.name}</p>
                  <p className="text-xs text-ink/50 font-mono">{s.code}</p>
                </div>
                <span className="text-xs uppercase tracking-wide text-gold-deep">{statusLabel(s.status)}</span>
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}

