import { notFound } from "next/navigation";
import { getStaffById } from "@/lib/repo";
import { StaffForm } from "../staff-form";

export const dynamic = "force-dynamic";

export default async function EditStaffPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const staff = getStaffById(id);
  if (!staff) notFound();

  return (
    <div>
      <h1 className="font-display text-3xl mb-8">Edit staff member</h1>
      <StaffForm staff={staff} />
    </div>
  );
}
