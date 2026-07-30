import { listUsers } from "@/lib/repo";
import { CreateStaffUserForm } from "./create-staff-form";

export const dynamic = "force-dynamic";

export default function AdminUsersPage() {
  const users = listUsers();

  return (
    <div>
      <h1 className="font-display text-3xl mb-2">Accounts</h1>
      <p className="text-ink/60 mb-8">All admin, staff, and student accounts. Create new staff logins here.</p>

      <div className="grid lg:grid-cols-2 gap-10">
        <div className="overflow-x-auto border border-line rounded-xl h-fit">
          <table className="w-full text-sm">
            <thead>
              <tr className="text-left text-xs uppercase tracking-wide text-ink/50 border-b border-line">
                <th className="py-3 px-4 font-medium">Name</th>
                <th className="py-3 px-4 font-medium">Email</th>
                <th className="py-3 px-4 font-medium">Role</th>
                <th className="py-3 px-4 font-medium">Verified</th>
              </tr>
            </thead>
            <tbody>
              {users.map((u) => (
                <tr key={u.id} className="border-b border-line last:border-0">
                  <td className="py-3 px-4">{u.name}</td>
                  <td className="py-3 px-4 text-ink/60">{u.email}</td>
                  <td className="py-3 px-4 capitalize">{u.role}</td>
                  <td className="py-3 px-4">{u.emailVerified ? "Yes" : "Pending"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <CreateStaffUserForm />
      </div>
    </div>
  );
}
