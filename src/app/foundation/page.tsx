import type { Metadata } from "next";
import Link from "next/link";
import { getSiteContent } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `WorldPath Caretaking Foundation | ${content.orgName}`,
    description:
      "The nonprofit organization behind WorldPath Group, supporting education, mentorship, healthcare outreach, and community development across Ghana.",
  };
}

export default function FoundationPage() {
  const content = getSiteContent();

  return (
    <>
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        <section className="mx-auto max-w-3xl px-6 pt-16 pb-20">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">Beyond admissions</p>
          <h1 className="font-display text-4xl mt-4 mb-8">WorldPath Caretaking Foundation</h1>
          <p className="text-lg text-ink/80 leading-relaxed whitespace-pre-line">
            {content.caretakingInfo ||
              "Beyond university placement, our parent foundation supports caretaking homes with food and daily necessities â€” because a student's wellbeing at home is part of their path to university too."}
          </p>

          <div className="mt-12 pt-8 border-t border-line">
            <Link href="/get-involved" className="btn-primary inline-block">
              See how you can help
            </Link>
          </div>
        </section>
      </main>
      <SiteFooter
        orgName={content.orgName}
        contactEmail={content.contactEmail}
        contactPhone={content.contactPhone}
        address={content.address}
      />
    </>
  );
}

