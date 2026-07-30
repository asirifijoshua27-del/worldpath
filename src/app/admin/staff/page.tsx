import Link from "next/link";
import { listStaff } from "@/lib/repo";
import { DeleteButton } from "@/components/delete-button";
import { deleteStaffAction } from "@/app/actions/admin";

export const dynamic = "force-dynamic";

export default function AdminStaffPage() {
  const staff = listStaff();

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="font-display text-3xl mb-2">Staff directory</h1>
          <p className="text-ink/60">Shown publicly on the About page.</p>
        </div>
        <Link href="/admin/staff/new" className="btn-primary">
          + Add staff
        </Link>
      </div>

      <div className="divide-y divide-line border border-line rounded-xl">
        {staff.length === 0 && <p className="p-6 text-sm text-ink/50 italic">No staff members yet.</p>}
        {staff.map((s) => (
          <div key={s.id} className="p-4 flex items-center justify-between gap-4">
            <div>
              <p className="font-medium">{s.name}</p>
              <p className="text-sm text-ink/60">{s.title}</p>
            </div>
            <div className="flex items-center gap-4 text-sm">
              <Link href={`/admin/staff/${s.id}`} className="text-teal hover:underline">
                Edit
              </Link>
              <DeleteButton id={s.id} action={deleteStaffAction} confirmLabel={`Remove ${s.name}?`} />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
