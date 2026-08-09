import { listUsers } from "@/lib/repo";
import { getSession } from "@/lib/auth";
import { CreateStaffUserForm } from "./create-staff-form";
import { DeleteButton } from "@/components/delete-button";
import { deleteUserAction } from "@/app/actions/admin";

export const dynamic = "force-dynamic";

export default async function AdminUsersPage() {
  const users = listUsers();
  const session = await getSession();
  const adminCount = users.filter((u) => u.role === "admin").length;

  return (
    <div>
      <h1 className="font-display text-3xl mb-2">Accounts</h1>
      <p className="text-ink/60 mb-8">
        All admin, staff, and student accounts. Create new staff logins here. Deleting an account removes
        its login and any linked profile Ã¢â‚¬â€ staff and student records included.
      </p>

      <div className="grid lg:grid-cols-2 gap-10">
        <div className="overflow-x-auto border border-line rounded-xl h-fit">
          <table className="w-full text-sm">
            <thead>
              <tr className="text-left text-xs uppercase tracking-wide text-ink/50 border-b border-line">
                <th className="py-3 px-4 font-medium">Name</th>
                <th className="py-3 px-4 font-medium">Email</th>
                <th className="py-3 px-4 font-medium">Role</th>
                <th className="py-3 px-4 font-medium">Verified</th>
                <th className="py-3 px-4 font-medium"></th>
              </tr>
            </thead>
            <tbody>
              {users.map((u) => {
                const isSelf = u.id === session?.userId;
                const isLastAdmin = u.role === "admin" && adminCount <= 1;
                return (
                  <tr key={u.id} className="border-b border-line last:border-0">
                    <td className="py-3 px-4">{u.name}</td>
                    <td className="py-3 px-4 text-ink/60">{u.email}</td>
                    <td className="py-3 px-4 capitalize">{u.role}</td>
                    <td className="py-3 px-4">{u.emailVerified ? "Yes" : "Pending"}</td>
                    <td className="py-3 px-4 text-right">
                      {isSelf ? (
                        <span className="text-xs text-ink/30">You</span>
                      ) : isLastAdmin ? (
                        <span className="text-xs text-ink/30">Last admin</span>
                      ) : (
                        <DeleteButton
                          id={u.id}
                          action={deleteUserAction}
                          confirmLabel={`Delete ${u.name}'s account? This removes their login and any linked staff or student record. This can't be undone.`}
                        />
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        <CreateStaffUserForm />
      </div>
    </div>
  );
}

