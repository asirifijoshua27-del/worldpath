import Link from "next/link";
import { listStudents, listStaff, listBoardMembers, listUsers } from "@/lib/repo";
import { APPLICATION_STATUSES } from "@/types";

export const dynamic = "force-dynamic";

export default function AdminDashboard() {
  const students = listStudents();
  const staff = listStaff();
  const board = listBoardMembers();
  const users = listUsers();

  const unassigned = students.filter((s) => !s.assignedStaffId).length;

  return (
    <div>
      <h1 className="font-display text-3xl mb-2">Dashboard</h1>
      <p className="text-ink/60 mb-8">A quick look at WorldPath Group right now.</p>

      <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-12">
        <Stat label="Students" value={students.length} href="/admin/students" />
        <Stat label="Unassigned students" value={unassigned} href="/admin/students" accent={unassigned > 0} />
        <Stat label="Staff members" value={staff.length} href="/admin/staff" />
        <Stat label="Board members" value={board.length} href="/admin/board" />
      </div>

      <div className="grid sm:grid-cols-2 gap-8">
        <div>
          <h2 className="font-display text-xl mb-4">Applications by stage</h2>
          <div className="space-y-2">
            {APPLICATION_STATUSES.map((status) => {
              const count = students.filter((s) => s.status === status.value).length;
              return (
                <div key={status.value} className="flex items-center justify-between border-b border-line py-2 text-sm">
                  <span>{status.label}</span>
                  <span className="font-medium">{count}</span>
                </div>
              );
            })}
          </div>
        </div>
        <div>
          <h2 className="font-display text-xl mb-4">Accounts</h2>
          <div className="space-y-2 text-sm">
            <div className="flex items-center justify-between border-b border-line py-2">
              <span>Admins</span>
              <span className="font-medium">{users.filter((u) => u.role === "admin").length}</span>
            </div>
            <div className="flex items-center justify-between border-b border-line py-2">
              <span>Staff</span>
              <span className="font-medium">{users.filter((u) => u.role === "staff").length}</span>
            </div>
            <div className="flex items-center justify-between border-b border-line py-2">
              <span>Students</span>
              <span className="font-medium">{users.filter((u) => u.role === "student").length}</span>
            </div>
          </div>
          <Link href="/admin/users" className="inline-block mt-4 text-sm text-teal hover:underline">
            Manage accounts →
          </Link>
        </div>
      </div>
    </div>
  );
}

function Stat({ label, value, href, accent }: { label: string; value: number; href: string; accent?: boolean }) {
  return (
    <Link
      href={href}
      className={`block border rounded-xl p-5 hover:border-ink transition-colors ${
        accent ? "border-gold-deep bg-gold/5" : "border-line"
      }`}
    >
      <p className="text-3xl font-display">{value}</p>
      <p className="text-sm text-ink/60 mt-1">{label}</p>
    </Link>
  );
}
