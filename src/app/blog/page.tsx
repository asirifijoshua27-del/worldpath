import type { Metadata } from "next";
import Link from "next/link";
import { getSiteContent, listPublishedPosts } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `Blog | ${content.orgName}`,
    description: "Student success stories and guides to applying for university and scholarships abroad.",
  };
}

export default function BlogIndexPage() {
  const content = getSiteContent();
  const posts = listPublishedPosts();

  return (
    <>
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        <section className="mx-auto max-w-5xl px-6 pt-16 pb-8">
          <p className="uppercase tracking-[0.25em] text-xs text-gold-deep font-medium">Blog</p>
          <h1 className="font-display text-4xl sm:text-5xl mt-5">Guides & stories</h1>
          <p className="mt-6 text-lg text-ink/70 max-w-xl">
            Application guides, scholarship tips, and stories from students on their way abroad.
          </p>
        </section>

        <section className="mx-auto max-w-5xl px-6 pb-20">
          {posts.length === 0 ? (
            <p className="text-sm text-ink/50 italic border border-dashed border-line rounded-xl p-6">
 No posts published yet - check back soon.
            </p>
          ) : (
            <div className="grid sm:grid-cols-2 gap-8">
              {posts.map((p) => {
                const tags = JSON.parse(p.tags) as string[];
                return (
                  <Link
                    key={p.id}
                    href={`/blog/${p.slug}`}
                    className="border border-line rounded-xl overflow-hidden hover:border-gold-deep/60 hover:shadow-sm transition-all flex flex-col"
                  >
                    {p.coverImageUrl && (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img src={p.coverImageUrl} alt={p.title} className="w-full h-40 object-cover" />
                    )}
                    <div className="p-6 flex-1 flex flex-col">
                      {tags.length > 0 && (
                        <p className="text-xs uppercase tracking-wide text-gold-deep mb-2">{tags[0]}</p>
                      )}
                      <h2 className="font-display text-xl mb-2">{p.title}</h2>
                      <p className="text-sm text-ink/70 leading-relaxed flex-1">{p.excerpt}</p>
                      <p className="text-xs text-ink/40 mt-4">
                        {p.publishedAt ? new Date(p.publishedAt).toLocaleDateString() : ""} Ã‚Â· {p.authorName}
                      </p>
                    </div>
                  </Link>
                );
              })}
            </div>
          )}
        </section>
      </main>
      <SiteFooter orgName={content.orgName} contactEmail={content.contactEmail} contactPhone={content.contactPhone} address={content.address} />
    </>
  );
}

