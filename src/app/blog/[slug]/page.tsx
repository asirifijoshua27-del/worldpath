import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { marked } from "marked";
import { getSiteContent, getPostBySlug } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";

export const dynamic = "force-dynamic";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const post = getPostBySlug(slug);
  if (!post || post.published !== 1) return {};

  return {
    title: `${post.title} | Blog`,
    description: post.excerpt,
    openGraph: {
      title: post.title,
      description: post.excerpt,
      type: "article",
      publishedTime: post.publishedAt || undefined,
      images: post.coverImageUrl ? [post.coverImageUrl] : undefined,
    },
  };
}

export default async function BlogPostPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const content = getSiteContent();
  const post = getPostBySlug(slug);

  if (!post || post.published !== 1) notFound();

  const tags = JSON.parse(post.tags) as string[];
  const html = marked.parse(post.body, { async: false }) as string;

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Article",
    headline: post.title,
    description: post.excerpt,
    author: { "@type": "Person", name: post.authorName },
    datePublished: post.publishedAt,
    dateModified: post.updatedAt,
    image: post.coverImageUrl || undefined,
  };

  return (
    <>
      {/* eslint-disable-next-line react/no-danger */}
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        <article className="mx-auto max-w-2xl px-6 pt-16 pb-24">
          <Link href="/blog" className="text-sm text-teal hover:underline">
            ← Back to blog
          </Link>

          {tags.length > 0 && (
            <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mt-6">{tags.join(" · ")}</p>
          )}
          <h1 className="font-display text-3xl sm:text-4xl mt-3 mb-4">{post.title}</h1>
          <p className="text-sm text-ink/50 mb-8">
            {post.authorName}
            {post.publishedAt ? ` · ${new Date(post.publishedAt).toLocaleDateString()}` : ""}
          </p>

          {post.coverImageUrl && (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={post.coverImageUrl} alt={post.title} className="w-full rounded-xl mb-10 object-cover max-h-96" />
          )}

          <div
            className="prose-content text-ink/85 leading-relaxed"
            // eslint-disable-next-line react/no-danger
            dangerouslySetInnerHTML={{ __html: html }}
          />

          <div className="mt-14 pt-8 border-t border-line flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <p className="text-ink/70">Ready to start your own application?</p>
            <Link href="/register" className="btn-primary shrink-0 text-center">
              Apply now
            </Link>
          </div>
        </article>
      </main>
      <SiteFooter orgName={content.orgName} contactEmail={content.contactEmail} contactPhone={content.contactPhone} address={content.address} />
    </>
  );
}

