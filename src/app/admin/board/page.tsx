import Link from "next/link";
import { listBoardMembers } from "@/lib/repo";
import { DeleteButton } from "@/components/delete-button";
import { deleteBoardMemberAction } from "@/app/actions/admin";
import { PhotoLightbox } from "@/components/photo-lightbox";

export const dynamic = "force-dynamic";

export default function AdminBoardPage() {
  const board = listBoardMembers();

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="font-display text-3xl mb-2">Board of Directors</h1>
          <p className="text-ink/60">Shown publicly on the About page.</p>
        </div>
        <Link href="/admin/board/new" className="btn-primary">
          + Add member
        </Link>
      </div>

      <div className="divide-y divide-line border border-line rounded-xl">
        {board.length === 0 && <p className="p-6 text-sm text-ink/50 italic">No board members yet.</p>}
        {board.map((b) => (
          <div key={b.id} className="p-4 flex items-center gap-4">
            <div className="w-12 h-12 rounded-full bg-paper-dim border border-line overflow-hidden shrink-0">
              {b.photoUrl ? (
                <PhotoLightbox src={b.photoUrl} alt={b.name} className="w-full h-full object-cover" />
              ) : (
                <div className="w-full h-full grid place-items-center text-xs text-ink/40">{b.name.charAt(0)}</div>
              )}
            </div>
            <div className="flex-1">
              <p className="font-medium">{b.name}</p>
              <p className="text-sm text-ink/60">{b.title}</p>
            </div>
            <div className="flex items-center gap-4 text-sm">
              <Link href={`/admin/board/${b.id}`} className="text-teal hover:underline">
                Edit
              </Link>
              <DeleteButton id={b.id} action={deleteBoardMemberAction} confirmLabel={`Remove ${b.name}?`} />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

