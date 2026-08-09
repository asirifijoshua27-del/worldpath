import { notFound } from "next/navigation";
import { getStaffById, getUserById } from "@/lib/repo";
import { StaffForm } from "../staff-form";
import { EmailStaffForm } from "./email-staff-form";
import { DeleteButton } from "@/components/delete-button";
import { deleteUserAction } from "@/app/actions/admin";

export const dynamic = "force-dynamic";

export default async function EditStaffPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const staff = getStaffById(id);
  if (!staff) notFound();

  const user = staff.userId ? getUserById(staff.userId) : undefined;

  return (
    <div>
      <h1 className="font-display text-3xl mb-8">Edit staff member</h1>
      <StaffForm staff={staff} />

      <div className="mt-12 pt-8 border-t border-line max-w-lg">
        <h2 className="font-display text-xl mb-4">Email this staff member</h2>
        {user ? (
          <EmailStaffForm staffId={staff.id} staffEmail={user.email} />
        ) : (
          <p className="text-sm text-ink/50 italic">
            No linked login account yet Ã¢â‚¬â€ nothing to email. Create one from the Accounts page.
          </p>
        )}
      </div>

      {user && (
        <div className="mt-12 pt-8 border-t border-line max-w-lg">
          <h2 className="font-display text-xl mb-2 text-red-700">Danger zone</h2>
          <p className="text-sm text-ink/60 mb-4">
            Deletes {user.name}'s login and this staff profile. Any assigned students become unassigned.
            This can't be undone.
          </p>
          <DeleteButton
            id={user.id}
            action={deleteUserAction}
            confirmLabel={`Delete ${user.name}'s account? This removes their login and this staff profile. This can't be undone.`}
          />
        </div>
      )}
    </div>
  );
}

