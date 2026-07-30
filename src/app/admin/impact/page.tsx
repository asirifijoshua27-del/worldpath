import Link from "next/link";
import { listImpactStories } from "@/lib/repo";
import { DeleteButton } from "@/components/delete-button";
import { deleteImpactStoryAction } from "@/app/actions/impact";

export const dynamic = "force-dynamic";

export default function AdminImpactPage() {
  const stories = listImpactStories();

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="font-display text-3xl mb-2">Impact stories</h1>
          <p className="text-ink/60">Shown publicly on the Impact page.</p>
        </div>
        <Link href="/admin/impact/new" className="btn-primary">
          + Add story
        </Link>
      </div>

      <div className="divide-y divide-line border border-line rounded-xl">
        {stories.length === 0 && <p className="p-6 text-sm text-ink/50 italic">No stories yet.</p>}
        {stories.map((s) => (
          <div key={s.id} className="p-4 flex items-center justify-between gap-4">
            <div>
              <p className="font-medium">{s.studentName}</p>
              <p className="text-sm text-ink/60">{s.headline}</p>
            </div>
            <div className="flex items-center gap-4 text-sm shrink-0">
              {s.featured === 1 && <span className="text-xs uppercase text-gold-deep">Featured</span>}
              <Link href={`/admin/impact/${s.id}`} className="text-teal hover:underline">
                Edit
              </Link>
              <DeleteButton id={s.id} action={deleteImpactStoryAction} confirmLabel={`Remove ${s.studentName}'s story?`} />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
