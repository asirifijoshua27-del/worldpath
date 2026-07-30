import Link from "next/link";
import { listAllPosts } from "@/lib/repo";
import { DeleteButton } from "@/components/delete-button";
import { deleteBlogPostAction } from "@/app/actions/blog";

export const dynamic = "force-dynamic";

export default function AdminBlogPage() {
  const posts = listAllPosts();

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="font-display text-3xl mb-2">Blog</h1>
          <p className="text-ink/60">Success stories and application guides for organic search traffic.</p>
        </div>
        <Link href="/admin/blog/new" className="btn-primary">
          + New post
        </Link>
      </div>

      <div className="divide-y divide-line border border-line rounded-xl">
        {posts.length === 0 && <p className="p-6 text-sm text-ink/50 italic">No posts yet.</p>}
        {posts.map((p) => (
          <div key={p.id} className="p-4 flex items-center justify-between gap-4">
            <div>
              <p className="font-medium">{p.title}</p>
              <p className="text-xs text-ink/50">
                {p.published ? (
                  <span className="text-teal">Published</span>
                ) : (
                  <span className="text-gold-deep">Draft</span>
                )}
                {" · "}
                /blog/{p.slug}
              </p>
            </div>
            <div className="flex items-center gap-4 text-sm shrink-0">
              <Link href={`/admin/blog/${p.id}`} className="text-teal hover:underline">
                Edit
              </Link>
              <DeleteButton id={p.id} action={deleteBlogPostAction} confirmLabel={`Delete "${p.title}"?`} />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
