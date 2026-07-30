import { notFound } from "next/navigation";
import { getBoardMemberById } from "@/lib/repo";
import { BoardMemberForm } from "../board-form";

export const dynamic = "force-dynamic";

export default async function EditBoardMemberPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const member = getBoardMemberById(id);
  if (!member) notFound();

  return (
    <div>
      <h1 className="font-display text-3xl mb-8">Edit board member</h1>
      <BoardMemberForm member={member} />
    </div>
  );
}
