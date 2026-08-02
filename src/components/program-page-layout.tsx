import Link from "next/link";
import { getSiteContent } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";

export function ProgramPageLayout({
  eyebrow,
  title,
  body,
  fallback,
  applyHref = "/register",
}: {
  eyebrow: string;
  title: string;
  body: string;
  fallback: string;
  applyHref?: string;
}) {
  const content = getSiteContent();

  return (
    <>
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        <section className="mx-auto max-w-3xl px-6 pt-16 pb-8">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">{eyebrow}</p>
          <h1 className="font-display text-4xl mt-4 mb-6">{title}</h1>
          <p className="text-lg text-ink/80 leading-relaxed whitespace-pre-line">{body || fallback}</p>
        </section>

        <section className="mx-auto max-w-3xl px-6 pb-20">
          <div className="rounded-2xl bg-navy text-paper px-8 py-10 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-6">
            <div>
              <h2 className="font-display text-xl mb-2">Ready to get started?</h2>
              <p className="text-paper/75">We'll match you with a counselor to guide your application.</p>
            </div>
            <Link href={applyHref} className="rounded-full bg-teal text-paper px-7 py-3 hover:bg-gold-deep transition-colors shrink-0 text-center">
              Get application support
            </Link>
          </div>
        </section>
      </main>
      <SiteFooter orgName={content.orgName} contactEmail={content.contactEmail} contactPhone={content.contactPhone} address={content.address} />
    </>
  );
}

